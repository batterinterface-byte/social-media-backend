class Document {
  final int? id;
  final String name;
  final String path;
  final String type;
  final int size;
  final DateTime createdAt;
  final DateTime importedAt;
  final bool isPinned;
  final bool isFavorite;
  final String? category;
  final bool isEncrypted;

  Document({
    this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.createdAt,
    required this.importedAt,
    this.isPinned = false,
    this.isFavorite = false,
    this.category,
    this.isEncrypted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
      'importedAt': importedAt.toIso8601String(),
      'isPinned': isPinned ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'category': category,
      'isEncrypted': isEncrypted ? 1 : 0,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as int?,
      name: map['name'] as String,
      path: map['path'] as String,
      type: map['type'] as String,
      size: map['size'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      importedAt: DateTime.parse(map['importedAt'] as String),
      isPinned: (map['isPinned'] as int?) == 1,
      isFavorite: (map['isFavorite'] as int?) == 1,
      category: map['category'] as String?,
      isEncrypted: (map['isEncrypted'] as int?) == 1,
    );
  }

  Document copyWith({
    int? id,
    String? name,
    String? path,
    String? type,
    int? size,
    DateTime? createdAt,
    DateTime? importedAt,
    bool? isPinned,
    bool? isFavorite,
    String? category,
    bool? isEncrypted,
    bool clearCategory = false,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      importedAt: importedAt ?? this.importedAt,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      category: clearCategory ? null : (category ?? this.category),
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  String get icon {
    switch (type.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'zip':
      case 'rar':
      case '7z':
        return '📦';
      case 'txt':
        return '📃';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp3':
      case 'wav':
      case 'm4a':
        return '🎵';
      case 'mp4':
      case 'avi':
      case 'mkv':
        return '🎬';
      default:
        return '📁';
    }
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toJson() => toMap();

  factory Document.fromJson(Map<String, dynamic> json) =>
      Document.fromMap(json);
}