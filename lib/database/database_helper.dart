import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';
import '../models/todo.dart';
import '../models/document.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isPinned INTEGER DEFAULT 0,
        isArchived INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        isLocked INTEGER DEFAULT 0,
        category TEXT,
        reminderDate TEXT,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        dueDate TEXT,
        category TEXT,
        isPinned INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        type TEXT NOT NULL,
        size INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        importedAt TEXT NOT NULL,
        isPinned INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        category TEXT,
        isEncrypted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE notes ADD COLUMN isArchived INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE notes ADD COLUMN isFavorite INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE notes ADD COLUMN isLocked INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE notes ADD COLUMN category TEXT
      ''');
      await db.execute('''
        ALTER TABLE notes ADD COLUMN reminderDate TEXT
      ''');
      await db.execute('''
        ALTER TABLE notes ADD COLUMN password TEXT
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          isCompleted INTEGER DEFAULT 0,
          priority INTEGER DEFAULT 1,
          createdAt TEXT NOT NULL,
          dueDate TEXT,
          category TEXT,
          isPinned INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS documents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          path TEXT NOT NULL,
          type TEXT NOT NULL,
          size INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          importedAt TEXT NOT NULL,
          isPinned INTEGER DEFAULT 0,
          isFavorite INTEGER DEFAULT 0,
          category TEXT,
          isEncrypted INTEGER DEFAULT 0
        )
      ''');
    }
  }

  // ============ NOTES ============

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'isArchived = 0',
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getArchivedNotes() async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'isArchived = 1',
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getFavoriteNotes() async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'isFavorite = 1 AND isArchived = 0',
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getPinnedNotes() async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'isPinned = 1 AND isArchived = 0',
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: '(title LIKE ? OR content LIKE ?) AND isArchived = 0',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getNotesByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'category = ? AND isArchived = 0',
      whereArgs: [category],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<String>> getAllCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM notes WHERE category IS NOT NULL AND category != ""',
    );
    return result.map((map) => map['category'] as String).toList();
  }

  Future<Note?> getNote(int id) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Note.fromMap(result.first);
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> togglePin(int id) async {
    final db = await database;
    final note = await getNote(id);
    if (note == null) return 0;
    return await db.update(
      'notes',
      {'isPinned': note.isPinned ? 0 : 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id) async {
    final db = await database;
    final note = await getNote(id);
    if (note == null) return 0;
    return await db.update(
      'notes',
      {'isFavorite': note.isFavorite ? 0 : 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleArchive(int id) async {
    final db = await database;
    final note = await getNote(id);
    if (note == null) return 0;
    return await db.update(
      'notes',
      {'isArchived': note.isArchived ? 0 : 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> importNotes(List<Note> notes) async {
    final db = await database;
    final batch = db.batch();
    for (final note in notes) {
      batch.insert('notes', note.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Note>> exportAllNotes() async {
    final db = await database;
    final result = await db.query('notes', orderBy: 'updatedAt DESC');
    return result.map((map) => Note.fromMap(map)).toList();
  }

  // ============ TODOS ============

  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<Todo>> getAllTodos() async {
    final db = await database;
    final result = await db.query(
      'todos',
      orderBy: 'isPinned DESC, priority DESC, createdAt DESC',
    );
    return result.map((map) => Todo.fromMap(map)).toList();
  }

  Future<List<Todo>> getPendingTodos() async {
    final db = await database;
    final result = await db.query(
      'todos',
      where: 'isCompleted = 0',
      orderBy: 'isPinned DESC, priority DESC, dueDate ASC',
    );
    return result.map((map) => Todo.fromMap(map)).toList();
  }

  Future<List<Todo>> getCompletedTodos() async {
    final db = await database;
    final result = await db.query(
      'todos',
      where: 'isCompleted = 1',
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Todo.fromMap(map)).toList();
  }

  Future<List<Todo>> searchTodos(String query) async {
    final db = await database;
    final result = await db.query(
      'todos',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'isPinned DESC, priority DESC',
    );
    return result.map((map) => Todo.fromMap(map)).toList();
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleTodoComplete(int id) async {
    final db = await database;
    final result = await db.query('todos', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return 0;
    final todo = Todo.fromMap(result.first);
    return await db.update(
      'todos',
      {'isCompleted': todo.isCompleted ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearCompletedTodos() async {
    final db = await database;
    return await db.delete('todos', where: 'isCompleted = 1');
  }

  // ============ DOCUMENTS ============

  Future<int> insertDocument(Document doc) async {
    final db = await database;
    return await db.insert('documents', doc.toMap());
  }

  Future<List<Document>> getAllDocuments() async {
    final db = await database;
    final result = await db.query(
      'documents',
      orderBy: 'isPinned DESC, importedAt DESC',
    );
    return result.map((map) => Document.fromMap(map)).toList();
  }

  Future<List<Document>> getDocumentsByType(String type) async {
    final db = await database;
    final result = await db.query(
      'documents',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'importedAt DESC',
    );
    return result.map((map) => Document.fromMap(map)).toList();
  }

  Future<List<Document>> getFavoriteDocuments() async {
    final db = await database;
    final result = await db.query(
      'documents',
      where: 'isFavorite = 1',
      orderBy: 'importedAt DESC',
    );
    return result.map((map) => Document.fromMap(map)).toList();
  }

  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    final result = await db.query(
      'documents',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'importedAt DESC',
    );
    return result.map((map) => Document.fromMap(map)).toList();
  }

  Future<int> updateDocument(Document doc) async {
    final db = await database;
    return await db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<int> deleteDocument(int id) async {
    final db = await database;
    return await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleDocumentFavorite(int id) async {
    final db = await database;
    final result = await db.query('documents', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return 0;
    final doc = Document.fromMap(result.first);
    return await db.update(
      'documents',
      {'isFavorite': doc.isFavorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}