class Category {
  final int id;
  final String categoryName;

  Category({
    required this.id,
    required this.categoryName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      categoryName: json['categoryName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
    };
  }
}

class MasterTerm {
  final int id;
  final String masterTerm;
  final bool isIncluded;
  final int? categoryId;
  final String? categoryName;
  List<Synonym> synonyms;

  MasterTerm({
    required this.id,
    required this.masterTerm,
    required this.isIncluded,
    this.categoryId,
    this.categoryName,
    this.synonyms = const [],
  });

  factory MasterTerm.fromJson(Map<String, dynamic> json) {
    return MasterTerm(
      id: json['id'] as int,
      masterTerm: json['masterTerm'] as String,
      isIncluded: json['isIncluded'] as bool? ?? true,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'masterTerm': masterTerm,
      'isIncluded': isIncluded,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }

  MasterTerm copyWith({
    int? id,
    String? masterTerm,
    bool? isIncluded,
    int? categoryId,
    String? categoryName,
    List<Synonym>? synonyms,
  }) {
    return MasterTerm(
      id: id ?? this.id,
      masterTerm: masterTerm ?? this.masterTerm,
      isIncluded: isIncluded ?? this.isIncluded,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      synonyms: synonyms ?? this.synonyms,
    );
  }
}

class Synonym {
  final int id;
  final int masterId;
  final String synonymTerm;
  final bool isIncluded;

  Synonym({
    required this.id,
    required this.masterId,
    required this.synonymTerm,
    required this.isIncluded,
  });

  factory Synonym.fromJson(Map<String, dynamic> json) {
    return Synonym(
      id: json['id'] as int,
      masterId: json['masterId'] as int,
      synonymTerm: json['synonymTerm'] as String,
      isIncluded: json['isIncluded'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'masterId': masterId,
      'synonymTerm': synonymTerm,
      'isIncluded': isIncluded,
    };
  }

  Synonym copyWith({
    int? id,
    int? masterId,
    String? synonymTerm,
    bool? isIncluded,
  }) {
    return Synonym(
      id: id ?? this.id,
      masterId: masterId ?? this.masterId,
      synonymTerm: synonymTerm ?? this.synonymTerm,
      isIncluded: isIncluded ?? this.isIncluded,
    );
  }
}

class CreateCategoryRequest {
  final String categoryName;

  CreateCategoryRequest({
    required this.categoryName,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
    };
  }
}

class UpdateCategoryRequest {
  final String categoryName;

  UpdateCategoryRequest({
    required this.categoryName,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
    };
  }
}

class CreateMasterTermRequest {
  final String masterTerm;
  final bool isIncluded;
  final int? categoryId;

  CreateMasterTermRequest({
    required this.masterTerm,
    this.isIncluded = true,
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'masterTerm': masterTerm,
      'isIncluded': isIncluded,
      if (categoryId != null) 'categoryId': categoryId,
    };
  }
}

class UpdateMasterTermRequest {
  final String masterTerm;
  final bool isIncluded;
  final int? categoryId;

  UpdateMasterTermRequest({
    required this.masterTerm,
    this.isIncluded = true,
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'masterTerm': masterTerm,
      'isIncluded': isIncluded,
      if (categoryId != null) 'categoryId': categoryId,
    };
  }
}

class CreateSynonymRequest {
  final String synonymTerm;
  final bool isIncluded;

  CreateSynonymRequest({
    required this.synonymTerm,
    this.isIncluded = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'synonymTerm': synonymTerm,
      'isIncluded': isIncluded,
    };
  }
}

class UpdateSynonymRequest {
  final String synonymTerm;
  final bool isIncluded;

  UpdateSynonymRequest({
    required this.synonymTerm,
    this.isIncluded = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'synonymTerm': synonymTerm,
      'isIncluded': isIncluded,
    };
  }
}

class ImportResult {
  final bool dryRun;
  final int rowsRead;
  final int rowsSkipped;
  final int masterTermsCreated;
  final int synonymsCreated;
  final List<ImportRowError> errors;

  ImportResult({
    required this.dryRun,
    required this.rowsRead,
    required this.rowsSkipped,
    required this.masterTermsCreated,
    required this.synonymsCreated,
    required this.errors,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      dryRun: json['dryRun'] as bool? ?? false,
      rowsRead: json['rowsRead'] as int? ?? 0,
      rowsSkipped: json['rowsSkipped'] as int? ?? 0,
      masterTermsCreated: json['masterTermsCreated'] as int? ?? 0,
      synonymsCreated: json['synonymsCreated'] as int? ?? 0,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => ImportRowError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ImportRowError {
  final int rowNumber;
  final String? masterTerm;
  final String message;

  ImportRowError({
    required this.rowNumber,
    this.masterTerm,
    required this.message,
  });

  factory ImportRowError.fromJson(Map<String, dynamic> json) {
    return ImportRowError(
      rowNumber: json['rowNumber'] as int? ?? 0,
      masterTerm: json['masterTerm'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}
