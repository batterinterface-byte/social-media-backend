import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/note.dart';
import '../models/todo.dart';

class ExportService {
  static Future<String?> exportAllData() async {
    try {
      final db = DatabaseHelper.instance;
      final notes = await db.exportAllNotes();
      final todos = await db.getAllTodos();
      final docs = await db.getAllDocuments();

      final data = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'todos': todos.map((t) => t.toJson()).toList(),
        'documents': docs.map((d) => d.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/notebook_backup_$timestamp.json');
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final db = DatabaseHelper.instance;

      if (data['notes'] != null) {
        final notes = (data['notes'] as List)
            .map((n) => Note.fromJson(n as Map<String, dynamic>))
            .toList();
        for (final note in notes) {
          await db.insertNote(note.copyWith(id: null));
        }
      }

      if (data['todos'] != null) {
        final todos = (data['todos'] as List)
            .map((t) => Todo.fromJson(t as Map<String, dynamic>))
            .toList();
        for (final todo in todos) {
          await db.insertTodo(todo.copyWith(id: null));
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> shareBackup() async {
    final path = await exportAllData();
    if (path != null) {
      await Share.shareXFiles([XFile(path)], text: 'Notebook Pro Backup');
    }
  }

  static Future<String?> exportNotesAsText() async {
    try {
      final notes = await DatabaseHelper.instance.exportAllNotes();
      final buffer = StringBuffer();
      
      for (final note in notes) {
        buffer.writeln('=== ${note.title.isEmpty ? "Untitled" : note.title} ===');
        buffer.writeln(note.content);
        buffer.writeln('Created: ${note.createdAt}');
        buffer.writeln('Updated: ${note.updatedAt}');
        buffer.writeln();
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/notes_export.txt');
      await file.writeAsString(buffer.toString());
      
      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> exportTasksAsText() async {
    try {
      final todos = await DatabaseHelper.instance.getAllTodos();
      final buffer = StringBuffer();
      
      for (final todo in todos) {
        final status = todo.isCompleted ? '[✓]' : '[ ]';
        buffer.writeln('$status ${todo.title}');
        if (todo.description != null && todo.description!.isNotEmpty) {
          buffer.writeln('   ${todo.description}');
        }
        if (todo.dueDate != null) {
          buffer.writeln('   Due: ${todo.dueDate}');
        }
        buffer.writeln();
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tasks_export.txt');
      await file.writeAsString(buffer.toString());
      
      return file.path;
    } catch (e) {
      return null;
    }
  }
}