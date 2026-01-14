import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/synonym.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  String get _synonymsEndpoint => '$baseUrl/api/admin/synonyms';

  // Categories CRUD

  Future<List<Category>> getAllCategories() async {
    final response = await http.get(
      Uri.parse('$_synonymsEndpoint/categories'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<Category> createCategory(CreateCategoryRequest request) async {
    final response = await http.post(
      Uri.parse('$_synonymsEndpoint/categories'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<Category> updateCategory(int id, UpdateCategoryRequest request) async {
    final response = await http.put(
      Uri.parse('$_synonymsEndpoint/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$_synonymsEndpoint/categories/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  // Master Terms CRUD

  Future<List<MasterTerm>> getAllMasters() async {
    final response = await http.get(
      Uri.parse('$_synonymsEndpoint/masters'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => MasterTerm.fromJson(json)).toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<MasterTerm> getMasterById(int id) async {
    final response = await http.get(
      Uri.parse('$_synonymsEndpoint/masters/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return MasterTerm.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<MasterTerm> createMaster(CreateMasterTermRequest request) async {
    final response = await http.post(
      Uri.parse('$_synonymsEndpoint/masters'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return MasterTerm.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<MasterTerm> updateMaster(int id, UpdateMasterTermRequest request) async {
    final response = await http.put(
      Uri.parse('$_synonymsEndpoint/masters/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return MasterTerm.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<void> deleteMaster(int id) async {
    final response = await http.delete(
      Uri.parse('$_synonymsEndpoint/masters/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  // Synonyms CRUD

  Future<List<Synonym>> getSynonymsByMaster(int masterId) async {
    final response = await http.get(
      Uri.parse('$_synonymsEndpoint/masters/$masterId/synonyms'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Synonym.fromJson(json)).toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<Synonym> getSynonymById(int id) async {
    final response = await http.get(
      Uri.parse('$_synonymsEndpoint/synonyms/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Synonym.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<Synonym> createSynonym(int masterId, CreateSynonymRequest request) async {
    final response = await http.post(
      Uri.parse('$_synonymsEndpoint/masters/$masterId/synonyms'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return Synonym.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<Synonym> updateSynonym(int id, UpdateSynonymRequest request) async {
    final response = await http.put(
      Uri.parse('$_synonymsEndpoint/synonyms/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return Synonym.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<void> deleteSynonym(int id) async {
    final response = await http.delete(
      Uri.parse('$_synonymsEndpoint/synonyms/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  // Password Check

  Future<bool> checkPassword(String password) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Search/check-password?password=${Uri.encodeComponent(password)}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result is bool) {
        return result;
      }
      return result == true || result == 'true';
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  // Production Sync

  Future<String> refreshProduction() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Search/refresh'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  // CSV Import

  Future<ImportResult> importCsv({
    required Uint8List fileBytes,
    required String fileName,
    bool dryRun = false,
  }) async {
    final uri = Uri.parse('$_synonymsEndpoint/import-csv');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    request.fields['dryRun'] = dryRun.toString();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return ImportResult.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  String _parseErrorMessage(String body) {
    try {
      final jsonBody = json.decode(body);
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ?? jsonBody['Message'] ?? body;
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
