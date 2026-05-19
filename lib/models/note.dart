class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;
  final bool isFavorite;
  final bool isLocked;
  final String? category;
  final DateTime? reminderDate;
  final String? password;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.isLocked = false,
    this.category,
    this.reminderDate,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'category': category,
      'reminderDate': reminderDate?.toIso8601String(),
      'password': password,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isPinned: (map['isPinned'] as int?) == 1,
      isArchived: (map['isArchived'] as int?) == 1,
      isFavorite: (map['isFavorite'] as int?) == 1,
      isLocked: (map['isLocked'] as int?) == 1,
      category: map['category'] as String?,
      reminderDate: map['reminderDate'] != null
          ? DateTime.parse(map['reminderDate'] as String)
          : null,
      password: map['password'] as String?,
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    bool? isLocked,
    String? category,
    DateTime? reminderDate,
    String? password,
    bool clearCategory = false,
    bool clearReminder = false,
    bool clearPassword = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      category: clearCategory ? null : (category ?? this.category),
      reminderDate: clearReminder ? null : (reminderDate ?? this.reminderDate),
      password: clearPassword ? null : (password ?? this.password),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Note.fromJson(Map<String, dynamic> json) => Note.fromMap(json);
}