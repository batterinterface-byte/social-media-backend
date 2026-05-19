class Todo {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final int priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? category;
  final bool isPinned;

  Todo({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = 1,
    required this.createdAt,
    this.dueDate,
    this.category,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['isCompleted'] as int?) == 1,
      priority: map['priority'] as int? ?? 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      category: map['category'] as String?,
      isPinned: (map['isPinned'] as int?) == 1,
    );
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    String? category,
    bool? isPinned,
    bool clearDueDate = false,
    bool clearCategory = false,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      category: clearCategory ? null : (category ?? this.category),
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Todo.fromJson(Map<String, dynamic> json) => Todo.fromMap(json);

  static String priorityLabel(int priority) {
    switch (priority) {
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }
}