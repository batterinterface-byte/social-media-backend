import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document.dart';
import '../database/database_helper.dart';
import '../services/document_scanner_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

enum DocFilter { all, favorites, type }

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Document> _documents = [];
  List<FileSystemEntity> _scannedFiles = [];
  bool _isLoading = true;
  bool _isScanning = false;
  DocFilter _currentFilter = DocFilter.all;
  String? _selectedType;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> _docTypes = [
    'pdf', 'doc', 'xlsx', 'txt', 'zip', 'image', 'audio', 'video', 'other'
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    List<Document> docs;
    
    if (_selectedType != null) {
      docs = await _dbHelper.getDocumentsByType(_selectedType!);
    } else if (_currentFilter == DocFilter.favorites) {
      docs = await _dbHelper.getFavoriteDocuments();
    } else {
      docs = await _dbHelper.getAllDocuments();
    }
    
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _searchDocuments(String query) async {
    if (query.isEmpty) {
      _loadDocuments();
      return;
    }
    setState(() => _isLoading = true);
    final docs = await _dbHelper.searchDocuments(query);
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _scanStorage() async {
    setState(() => _isScanning = true);
    
    final hasPermission = await DocumentScannerService.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required')),
        );
      }
      setState(() => _isScanning = false);
      return;
    }

    final files = await DocumentScannerService.scanStorage();
    setState(() {
      _scannedFiles = files;
      _isScanning = false;
    });

    if (files.isNotEmpty && mounted) {
      _showScanResults();
    }
  }

  void _showScanResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Found ${_scannedFiles.length} files',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _importAllDocuments();
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Import All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _scannedFiles.length,
                itemBuilder: (context, index) {
                  final file = _scannedFiles[index] as File;
                  final type = DocumentScannerService.getFileType(file.path);
                  return ListTile(
                    leading: Text(
                      _getTypeIcon(type),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      file.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${type.toUpperCase()} • ${_formatSize(file.lengthSync())}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () => _importSingleDocument(file),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'pdf': return '📄';
      case 'doc': return '📝';
      case 'xlsx': return '📊';
      case 'txt': return '📃';
      case 'zip': return '📦';
      case 'image': return '🖼️';
      case 'audio': return '🎵';
      case 'video': return '🎬';
      case 'code': return '💻';
      default: return '📁';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _importSingleDocument(File file) async {
    try {
      final stat = await file.stat();
      final type = DocumentScannerService.getFileType(file.path);
      final name = file.path.split('/').last;
      
      final doc = Document(
        name: name,
        path: file.path,
        type: type,
        size: stat.size,
        createdAt: stat.modified,
        importedAt: DateTime.now(),
      );
      
      await _dbHelper.insertDocument(doc);
      _loadDocuments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported: $name')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    }
  }

  Future<void> _importAllDocuments() async {
    int imported = 0;
    for (final file in _scannedFiles) {
      try {
        final f = file as File;
        final stat = await f.stat();
        final type = DocumentScannerService.getFileType(f.path);
        final name = f.path.split('/').last;
        
        final doc = Document(
          name: name,
          path: f.path,
          type: type,
          size: stat.size,
          createdAt: stat.modified,
          importedAt: DateTime.now(),
        );
        
        await _dbHelper.insertDocument(doc);
        imported++;
      } catch (e) {
        continue;
      }
    }
    
    _loadDocuments();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported documents')),
      );
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    
    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        if (file.path != null) {
          final type = DocumentScannerService.getFileType(file.name);
          
          final doc = Document(
            name: file.name,
            path: file.path!,
            type: type,
            size: file.size,
            createdAt: DateTime.now(),
            importedAt: DateTime.now(),
          );
          
          await _dbHelper.insertDocument(doc);
        }
      }
      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${result.files.length} files')),
        );
      }
    }
  }

  Future<void> _deleteDocument(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Remove "$name" from vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _dbHelper.deleteDocument(id);
      _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document removed')),
        );
      }
    }
  }

  Future<void> _shareDocument(Document doc) async {
    try {
      await Share.shareXFiles([XFile(doc.path)], text: doc.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot share: $e')),
        );
      }
    }
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('All Documents'),
              selected: _currentFilter == DocFilter.all && _selectedType == null,
              onTap: () {
                setState(() {
                  _currentFilter = DocFilter.all;
                  _selectedType = null;
                });
                _loadDocuments();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              selected: _currentFilter == DocFilter.favorites,
              onTap: () {
                setState(() {
                  _currentFilter = DocFilter.favorites;
                  _selectedType = null;
                });
                _loadDocuments();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('By Type', style: Theme.of(context).textTheme.titleSmall),
            ),
            ..._docTypes.map((type) => ListTile(
              leading: Text(_getTypeIcon(type), style: const TextStyle(fontSize: 20)),
              title: Text(type.toUpperCase()),
              selected: _selectedType == type,
              onTap: () {
                setState(() {
                  _currentFilter = DocFilter.type;
                  _selectedType = type;
                });
                _loadDocuments();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search documents...',
                  border: InputBorder.none,
                ),
                onChanged: _searchDocuments,
              )
            : const Text('Document Vault'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadDocuments();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmptyState()
              : _buildDocumentGrid(isTablet),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'scan',
            onPressed: _isScanning ? null : _scanStorage,
            child: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.scanner),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: _pickDocument,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No documents yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan storage or add documents',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentGrid(bool isTablet) {
    final crossAxisCount = isTablet ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _documents.length,
      itemBuilder: (context, index) => _buildDocumentCard(_documents[index]),
    );
  }

  Widget _buildDocumentCard(Document doc) {
    return Card(
      child: InkWell(
        onTap: () => _openDocument(doc),
        onLongPress: () => _showDocumentOptions(doc),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(doc.icon, style: const TextStyle(fontSize: 32)),
                  const Spacer(),
                  if (doc.isFavorite)
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                ],
              ),
              const Spacer(),
              Text(
                doc.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    doc.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    doc.sizeFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDocument(Document doc) async {
    try {
      final file = File(doc.path);
      final exists = await file.exists();
      if (!mounted) return;
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening: ${doc.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDocumentOptions(Document doc) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(context);
                _openDocument(doc);
              },
            ),
            ListTile(
              leading: Icon(
                doc.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: doc.isFavorite ? Colors.red : null,
              ),
              title: Text(doc.isFavorite ? 'Remove from favorites' : 'Add to favorites'),
              onTap: () {
                Navigator.pop(context);
                _dbHelper.toggleDocumentFavorite(doc.id!);
                _loadDocuments();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareDocument(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteDocument(doc.id!, doc.name);
              },
            ),
          ],
        ),
      ),
    );
  }
}