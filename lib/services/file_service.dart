import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/note.dart';
import '../database/database_helper.dart';

class FileService {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<String?> exportNotesToJson() async {
    try {
      await requestStoragePermission();
      
      final notes = await DatabaseHelper.instance.exportAllNotes();
      final jsonData = jsonEncode(notes.map((n) => n.toJson()).toList());
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/notes_export_$timestamp.json');
      
      await file.writeAsString(jsonData);
      
      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Note>?> importNotesFromJson() async {
    try {
      await requestStoragePermission();
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as List;
      
      return jsonData
          .map((data) => Note.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveToDownloads(String content, String filename) async {
    try {
      await requestStoragePermission();
      
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final file = File('${directory.path}/$filename');
        await file.writeAsString(content);
      }
    } catch (e) {
      rethrow;
    }
  }
}