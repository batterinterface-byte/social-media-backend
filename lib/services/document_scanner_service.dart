import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DocumentScannerService {
  static final List<String> supportedExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'rtf', 'csv', 'json', 'xml', 'html', 'htm',
    'zip', 'rar', '7z', 'tar', 'gz',
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp',
    'mp3', 'wav', 'ogg', 'm4a', 'flac',
    'mp4', 'avi', 'mkv', 'mov', 'wmv',
    'exe', 'msi', 'apk', 'bat', 'sh', 'py', 'js',
  ];

  static Future<List<FileSystemEntity>> scanStorage() async {
    List<FileSystemEntity> documents = [];
    
    try {
      final storageDirs = await _getStorageDirectories();
      
      for (final dir in storageDirs) {
        if (await dir.exists()) {
          try {
            final files = await _scanDirectory(dir, 3);
            documents.addAll(files);
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      return [];
    }
    
    return documents;
  }

  static Future<List<Directory>> _getStorageDirectories() async {
    List<Directory> dirs = [];
    
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        dirs.add(externalDir);
        
        final parent = externalDir.parent;
        if (await parent.exists()) {
          dirs.add(parent);
        }
      }
    } catch (e) {
      // ignore
    }
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      dirs.add(appDir);
    } catch (e) {
      // ignore
    }
    
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        dirs.add(downloadDir);
      }
    } catch (e) {
      // ignore
    }
    
    try {
      final dcimDir = Directory('/storage/emulated/0/DCIM');
      if (await dcimDir.exists()) {
        dirs.add(dcimDir);
      }
    } catch (e) {
      // ignore
    }
    
    return dirs;
  }

  static Future<List<FileSystemEntity>> _scanDirectory(
    Directory dir,
    int maxDepth, {
    int currentDepth = 0,
  }) async {
    List<FileSystemEntity> results = [];
    
    if (currentDepth > maxDepth) return results;
    
    try {
      final entities = dir.listSync(followLinks: false);
      
      for (final entity in entities) {
        try {
          if (entity is File) {
            final ext = path.extension(entity.path).toLowerCase().replaceFirst('.', '');
            if (supportedExtensions.contains(ext)) {
              results.add(entity);
            }
          } else if (entity is Directory) {
            final name = path.basename(entity.path);
            if (!name.startsWith('.') && 
                !name.contains('cache') && 
                !name.contains('thumbnails')) {
              final subResults = await _scanDirectory(
                entity,
                maxDepth,
                currentDepth: currentDepth + 1,
              );
              results.addAll(subResults);
            }
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // ignore permission errors
    }
    
    return results;
  }

  static String getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    
    if (['pdf'].contains(ext)) return 'pdf';
    if (['doc', 'docx'].contains(ext)) return 'doc';
    if (['xls', 'xlsx'].contains(ext)) return 'xlsx';
    if (['ppt', 'pptx'].contains(ext)) return 'ppt';
    if (['txt', 'rtf', 'csv'].contains(ext)) return 'txt';
    if (['json', 'xml', 'html', 'htm'].contains(ext)) return 'code';
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return 'zip';
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp'].contains(ext)) return 'image';
    if (['mp3', 'wav', 'ogg', 'm4a', 'flac'].contains(ext)) return 'audio';
    if (['mp4', 'avi', 'mkv', 'mov', 'wmv'].contains(ext)) return 'video';
    if (['exe', 'msi', 'apk', 'bat', 'sh', 'py', 'js'].contains(ext)) return 'app';
    
    return 'other';
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      
      final manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    }
    return true;
  }
}