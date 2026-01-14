import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/synonym.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  final ApiService apiService;

  const AdminPanelScreen({super.key, required this.apiService});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<MasterTerm> _masterTerms = [];
  List<MasterTerm> _filteredMasterTerms = [];
  Map<int, List<Synonym>> _synonymsCache = {};
  Set<int> _expandedMasterIds = {};
  Set<int> _loadingSynonyms = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsyncedChanges = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMasterTerms();
    _searchController.addListener(_filterMasterTerms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMasterTerms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMasterTerms = _masterTerms;
      } else {
        _filteredMasterTerms = _masterTerms.where((master) {
          if (master.masterTerm.toLowerCase().contains(query)) {
            return true;
          }
          final synonyms = _synonymsCache[master.id];
          if (synonyms != null) {
            return synonyms.any((s) => s.synonymTerm.toLowerCase().contains(query));
          }
          return false;
        }).toList();
      }
    });
  }

  Future<void> _loadMasterTerms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final masters = await widget.apiService.getAllMasters();
      setState(() {
        _masterTerms = masters;
        _filteredMasterTerms = masters;
        _isLoading = false;
      });
      _filterMasterTerms();
      
      // Load all synonyms in background to show counts
      _loadAllSynonymCounts(masters);
    }on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load master terms: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadAllSynonymCounts(List<MasterTerm> masters) async {
    // Load synonyms for all masters in parallel (in batches to avoid overwhelming the API)
    const batchSize = 10;
    for (var i = 0; i < masters.length; i += batchSize) {
      final batch = masters.skip(i).take(batchSize);
      await Future.wait(
        batch.map((master) async {
          if (!_synonymsCache.containsKey(master.id)) {
            try {
              final synonyms = await widget.apiService.getSynonymsByMaster(master.id);
              _synonymsCache[master.id] = synonyms;
            } catch (_) {
              // Silently ignore errors for individual synonym loads
            }
          }
        }),
      );
      // Update UI after each batch
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadSynonyms(int masterId) async {
    if (_loadingSynonyms.contains(masterId)) return;

    setState(() {
      _loadingSynonyms.add(masterId);
    });

    try {
      final synonyms = await widget.apiService.getSynonymsByMaster(masterId);
      setState(() {
        _synonymsCache[masterId] = synonyms;
        _loadingSynonyms.remove(masterId);
      });
    } on ApiException catch (e) {
      setState(() {
        _loadingSynonyms.remove(masterId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load synonyms: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleExpanded(MasterTerm master) {
    setState(() {
      if (_expandedMasterIds.contains(master.id)) {
        _expandedMasterIds.remove(master.id);
      } else {
        _expandedMasterIds.add(master.id);
        if (!_synonymsCache.containsKey(master.id)) {
          _loadSynonyms(master.id);
        }
      }
    });
  }

  Future<void> _showAddMasterDialog() async {
    final result = await showDialog<MasterTerm>(
      context: context,
      builder: (context) => _MasterTermDialog(
        title: 'Add Master Term',
        apiService: widget.apiService,
      ),
    );

    if (result != null) {
      setState(() => _hasUnsyncedChanges = true);
      _loadMasterTerms();
    }
  }

  Future<void> _showEditMasterDialog(MasterTerm master) async {
    final result = await showDialog<MasterTerm>(
      context: context,
      builder: (context) => _MasterTermDialog(
        title: 'Edit Master Term',
        apiService: widget.apiService,
        existingMaster: master,
      ),
    );

    if (result != null) {
      setState(() => _hasUnsyncedChanges = true);
      _loadMasterTerms();
    }
  }

  Future<void> _deleteMaster(MasterTerm master) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Master Term'),
        content: Text(
          'Are you sure you want to delete "${master.masterTerm}" and all its synonyms?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.deleteMaster(master.id);
        _synonymsCache.remove(master.id);
        _expandedMasterIds.remove(master.id);
        setState(() => _hasUnsyncedChanges = true);
        _loadMasterTerms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${master.masterTerm}"')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddSynonymDialog(MasterTerm master) async {
    final result = await showDialog<Synonym>(
      context: context,
      builder: (context) => _SynonymDialog(
        title: 'Add Synonym',
        apiService: widget.apiService,
        masterId: master.id,
      ),
    );

    if (result != null) {
      setState(() => _hasUnsyncedChanges = true);
      _loadSynonyms(master.id);
    }
  }

  Future<void> _showEditSynonymDialog(Synonym synonym) async {
    final result = await showDialog<Synonym>(
      context: context,
      builder: (context) => _SynonymDialog(
        title: 'Edit Synonym',
        apiService: widget.apiService,
        masterId: synonym.masterId,
        existingSynonym: synonym,
      ),
    );

    if (result != null) {
      setState(() => _hasUnsyncedChanges = true);
      _loadSynonyms(synonym.masterId);
    }
  }

  Future<void> _deleteSynonym(Synonym synonym) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Synonym'),
        content: Text('Are you sure you want to delete "${synonym.synonymTerm}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.deleteSynonym(synonym.id);
        setState(() => _hasUnsyncedChanges = true);
        _loadSynonyms(synonym.masterId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${synonym.synonymTerm}"')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showImportDialog() async {
    final result = await showDialog<ImportResult>(
      context: context,
      builder: (context) => _ImportDialog(apiService: widget.apiService),
    );

    if (result != null && !result.dryRun) {
      _synonymsCache.clear();
      _expandedMasterIds.clear();
      setState(() => _hasUnsyncedChanges = true);
      _loadMasterTerms();
    }
  }

  Future<void> _showSyncProductionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SyncProductionDialog(apiService: widget.apiService),
    );

    if (result == true) {
      setState(() => _hasUnsyncedChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'assets/shotdeck_website_logo_r.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            const Text(
              'Keyword Extraction Admin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
            onPressed: _showImportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadMasterTerms,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search master terms...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_filteredMasterTerms.length} of ${_masterTerms.length} master terms',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 500;
          
          if (isSmallScreen) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'sync',
                  onPressed: _hasUnsyncedChanges ? _showSyncProductionDialog : null,
                  backgroundColor: _hasUnsyncedChanges 
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[700],
                  tooltip: 'Sync Production',
                  child: const Icon(Icons.sync, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'add',
                  onPressed: _showAddMasterDialog,
                  tooltip: 'Add Master Term',
                  child: const Icon(Icons.add, size: 20),
                ),
              ],
            );
          }
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'sync',
                onPressed: _hasUnsyncedChanges ? _showSyncProductionDialog : null,
                backgroundColor: _hasUnsyncedChanges 
                    ? const Color(0xFF4CAF50)
                    : Colors.grey[700],
                icon: const Icon(Icons.sync),
                label: const Text('Sync Production'),
              ),
              const SizedBox(width: 16),
              FloatingActionButton.extended(
                heroTag: 'add',
                onPressed: _showAddMasterDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Master Term'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMasterActions(MasterTerm master) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;
    
    if (isSmallScreen) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'add',
            child: Row(
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text('Add Synonym'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'add':
              _showAddSynonymDialog(master);
              break;
            case 'edit':
              _showEditMasterDialog(master);
              break;
            case 'delete':
              _deleteMaster(master);
              break;
          }
        },
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add Synonym',
          onPressed: () => _showAddSynonymDialog(master),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Edit',
          onPressed: () => _showEditMasterDialog(master),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Delete',
          color: Colors.red,
          onPressed: () => _deleteMaster(master),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading master terms',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMasterTerms,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredMasterTerms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No master terms yet'
                  : 'No master terms match your search',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (_searchController.text.isEmpty)
              const Text('Click the + button to add one'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredMasterTerms.length,
      itemBuilder: (context, index) {
        final master = _filteredMasterTerms[index];
        final isExpanded = _expandedMasterIds.contains(master.id);
        final synonyms = _synonymsCache[master.id];
        final isLoadingSynonyms = _loadingSynonyms.contains(master.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => _toggleExpanded(master),
                ),
                title: Row(
                  children: [
                    Text(
                      master.masterTerm,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (master.categoryName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4D8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00B4D8).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          master.categoryName!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF00B4D8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  synonyms != null
                      ? '${synonyms.length} synonym${synonyms.length == 1 ? '' : 's'}'
                      : 'Loading...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: _buildMasterActions(master),
                onTap: () => _toggleExpanded(master),
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                if (isLoadingSynonyms)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (synonyms == null || synonyms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No synonyms yet. Click + to add one.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  ...synonyms.map((synonym) => _buildSynonymTile(synonym)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSynonymTile(Synonym synonym) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;
    
    return Container(
      color: Colors.grey[900],
      child: ListTile(
        contentPadding: EdgeInsets.only(left: isSmallScreen ? 32 : 56, right: 8),
        title: Text(
          synonym.synonymTerm,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
        trailing: isSmallScreen
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditSynonymDialog(synonym);
                      break;
                    case 'delete':
                      _deleteSynonym(synonym);
                      break;
                  }
                },
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit',
                    onPressed: () => _showEditSynonymDialog(synonym),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    tooltip: 'Delete',
                    color: Colors.red,
                    onPressed: () => _deleteSynonym(synonym),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MasterTermDialog extends StatefulWidget {
  final String title;
  final ApiService apiService;
  final MasterTerm? existingMaster;

  const _MasterTermDialog({
    required this.title,
    required this.apiService,
    this.existingMaster,
  });

  @override
  State<_MasterTermDialog> createState() => _MasterTermDialogState();
}

class _MasterTermDialogState extends State<_MasterTermDialog> {
  final _formKey = GlobalKey<FormState>();
  final _termController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  String? _errorMessage;
  List<Category> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.existingMaster != null) {
      _termController.text = widget.existingMaster!.masterTerm;
      _selectedCategoryId = widget.existingMaster!.categoryId;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.apiService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _termController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      MasterTerm result;
      if (widget.existingMaster != null) {
        result = await widget.apiService.updateMaster(
          widget.existingMaster!.id,
          UpdateMasterTermRequest(
            masterTerm: _termController.text.trim(),
            categoryId: _selectedCategoryId,
          ),
        );
      } else {
        result = await widget.apiService.createMaster(
          CreateMasterTermRequest(
            masterTerm: _termController.text.trim(),
            categoryId: _selectedCategoryId,
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _termController,
                decoration: const InputDecoration(
                  labelText: 'Master Term',
                  hintText: 'Enter the master term',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a master term';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'Select a category (optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No Category'),
                        ),
                        ..._categories.map((category) => DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(category.categoryName),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingMaster != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

class _SynonymDialog extends StatefulWidget {
  final String title;
  final ApiService apiService;
  final int masterId;
  final Synonym? existingSynonym;

  const _SynonymDialog({
    required this.title,
    required this.apiService,
    required this.masterId,
    this.existingSynonym,
  });

  @override
  State<_SynonymDialog> createState() => _SynonymDialogState();
}

class _SynonymDialogState extends State<_SynonymDialog> {
  final _formKey = GlobalKey<FormState>();
  final _termController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingSynonym != null) {
      _termController.text = widget.existingSynonym!.synonymTerm;
    }
  }

  @override
  void dispose() {
    _termController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Synonym result;
      if (widget.existingSynonym != null) {
        result = await widget.apiService.updateSynonym(
          widget.existingSynonym!.id,
          UpdateSynonymRequest(
            synonymTerm: _termController.text.trim(),
          ),
        );
      } else {
        result = await widget.apiService.createSynonym(
          widget.masterId,
          CreateSynonymRequest(
            synonymTerm: _termController.text.trim(),
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _termController,
                decoration: const InputDecoration(
                  labelText: 'Synonym Term',
                  hintText: 'Enter the synonym term',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a synonym term';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingSynonym != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

class _ImportDialog extends StatefulWidget {
  final ApiService apiService;

  const _ImportDialog({required this.apiService});

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  PlatformFile? _selectedFile;
  bool _dryRun = true;
  bool _isLoading = false;
  ImportResult? _result;
  String? _errorMessage;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _import() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await widget.apiService.importCsv(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        dryRun: _dryRun,
      );
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import CSV'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload a CSV file with columns: MASTER TERM (required), ALT TERM 1, ALT TERM 2, ... (optional)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Select File'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedFile?.name ?? 'No file selected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Dry Run'),
              subtitle: const Text(
                'Preview changes without actually importing',
              ),
              value: _dryRun,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _dryRun = value ?? true;
                      });
                    },
              contentPadding: EdgeInsets.zero,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.dryRun ? Colors.blue[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _result!.dryRun ? Colors.blue[200]! : Colors.green[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result!.dryRun ? Icons.preview : Icons.check_circle,
                          color: _result!.dryRun
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _result!.dryRun
                              ? 'Dry Run Results'
                              : 'Import Complete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _result!.dryRun
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Rows read: ${_result!.rowsRead}'),
                    Text('Rows skipped: ${_result!.rowsSkipped}'),
                    Text('Master terms created: ${_result!.masterTermsCreated}'),
                    Text('Synonyms created: ${_result!.synonymsCreated}'),
                    if (_result!.errors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Errors: ${_result!.errors.length}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ...(_result!.errors.take(5).map((e) => Text(
                            '  Row ${e.rowNumber}: ${e.message}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ))),
                      if (_result!.errors.length > 5)
                        Text(
                          '  ... and ${_result!.errors.length - 5} more',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.of(context).pop(_result),
          child: Text(_result != null && !_result!.dryRun ? 'Done' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedFile == null ? null : _import,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_dryRun ? 'Preview' : 'Import'),
        ),
      ],
    );
  }
}

class _SyncProductionDialog extends StatefulWidget {
  final ApiService apiService;

  const _SyncProductionDialog({required this.apiService});

  @override
  State<_SyncProductionDialog> createState() => _SyncProductionDialogState();
}

class _SyncProductionDialogState extends State<_SyncProductionDialog> {
  bool _isLoading = false;
  bool _isComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _syncProduction();
  }

  Future<void> _syncProduction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.apiService.refreshProduction();
      setState(() {
        _isLoading = false;
        _isComplete = true;
      });
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isComplete ? 'Sync Complete' : 'Syncing Production'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Syncing changes to production...',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait, this may take a moment.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ] else if (_errorMessage != null) ...[
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Sync Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ] else if (_isComplete) ...[
              const Icon(
                Icons.check_circle,
                size: 48,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(height: 16),
              const Text(
                "Successfully sync'd production",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your changes are now live.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isLoading)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_isComplete),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isComplete ? const Color(0xFF4CAF50) : null,
            ),
            child: Text(_isComplete ? 'Close' : 'Dismiss'),
          ),
      ],
    );
  }
}
