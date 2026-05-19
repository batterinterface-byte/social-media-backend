import 'package:flutter/material.dart';
import '../models/note.dart';
import '../database/database_helper.dart';
import '../services/file_service.dart';
import 'note_editor_screen.dart';
import 'package:intl/intl.dart';

enum NoteFilter { all, archived, favorites, pinned, category }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Note> _notes = [];
  List<String> _categories = [];
  bool _isLoading = true;
  NoteFilter _currentFilter = NoteFilter.all;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _categories = await _dbHelper.getAllCategories();
    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    List<Note> notes;
    switch (_currentFilter) {
      case NoteFilter.archived:
        notes = await _dbHelper.getArchivedNotes();
        break;
      case NoteFilter.favorites:
        notes = await _dbHelper.getFavoriteNotes();
        break;
      case NoteFilter.pinned:
        notes = await _dbHelper.getPinnedNotes();
        break;
      case NoteFilter.category:
        notes = _selectedCategory != null
            ? await _dbHelper.getNotesByCategory(_selectedCategory!)
            : await _dbHelper.getAllNotes();
        break;
      case NoteFilter.all:
        notes = await _dbHelper.getAllNotes();
        break;
    }
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      _loadNotes();
      return;
    }
    setState(() => _isLoading = true);
    final notes = await _dbHelper.searchNotes(query);
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _deleteNote(int id) async {
    await _dbHelper.deleteNote(id);
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted')),
      );
    }
  }

  Future<void> _togglePin(int id) async {
    await _dbHelper.togglePin(id);
    _loadNotes();
  }

  Future<void> _toggleFavorite(int id) async {
    await _dbHelper.toggleFavorite(id);
    _loadNotes();
  }

  Future<void> _toggleArchive(int id) async {
    await _dbHelper.toggleArchive(id);
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note archived')),
      );
    }
  }

  Future<void> _exportNotes() async {
    final path = await FileService.exportNotesToJson();
    if (!mounted) return;
    
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notes exported to: $path')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export notes')),
      );
    }
  }

  Future<void> _importNotes() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use file picker to select JSON file')),
    );
  }

  void _navigateToEditor({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );
    if (result == true) {
      _loadData();
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
              leading: const Icon(Icons.notes),
              title: const Text('All Notes'),
              selected: _currentFilter == NoteFilter.all,
              onTap: () {
                setState(() {
                  _currentFilter = NoteFilter.all;
                  _isSearching = false;
                  _searchController.clear();
                });
                _loadNotes();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Pinned'),
              selected: _currentFilter == NoteFilter.pinned,
              onTap: () {
                setState(() => _currentFilter = NoteFilter.pinned);
                _loadNotes();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              selected: _currentFilter == NoteFilter.favorites,
              onTap: () {
                setState(() => _currentFilter = NoteFilter.favorites);
                _loadNotes();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archived'),
              selected: _currentFilter == NoteFilter.archived,
              onTap: () {
                setState(() => _currentFilter = NoteFilter.archived);
                _loadNotes();
                Navigator.pop(context);
              },
            ),
            if (_categories.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categories'),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoriesDialog();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _categories.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_categories[index]),
              onTap: () {
                setState(() {
                  _currentFilter = NoteFilter.category;
                  _selectedCategory = _categories[index];
                });
                _loadNotes();
                Navigator.pop(context);
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(note.id!);
              },
            ),
            ListTile(
              leading: Icon(note.isFavorite ? Icons.favorite : Icons.favorite_border),
              title: Text(note.isFavorite ? 'Remove from favorites' : 'Add to favorites'),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(note.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text(note.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                Navigator.pop(context);
                _toggleArchive(note.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareNote(Note note) async {
    final text = '${note.title}\n\n${note.content}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share: $text')),
    );
  }

  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(note.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                ),
                onChanged: _searchNotes,
              )
            : Text(_getAppBarTitle()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadNotes();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportNotes();
              } else if (value == 'import') {
                _importNotes();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Export Notes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Import Notes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(isTablet),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentFilter) {
      case NoteFilter.archived:
        return 'Archived';
      case NoteFilter.favorites:
        return 'Favorites';
      case NoteFilter.pinned:
        return 'Pinned';
      case NoteFilter.category:
        return _selectedCategory ?? 'Category';
      case NoteFilter.all:
        return 'My Notes';
    }
  }

  Widget _buildEmptyState() {
    String message = 'No notes yet';
    if (_currentFilter == NoteFilter.archived) {
      message = 'No archived notes';
    } else if (_currentFilter == NoteFilter.favorites) {
      message = 'No favorite notes';
    } else if (_currentFilter == NoteFilter.pinned) {
      message = 'No pinned notes';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create one',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isTablet ? 2 : 1;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isTablet ? 1.5 : 2,
          ),
          itemCount: _notes.length,
          itemBuilder: (context, index) => _buildNoteCard(_notes[index]),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEditor(note: note),
        onLongPress: () => _showNoteOptions(note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.push_pin, size: 16, color: Colors.orange),
                    ),
                  if (note.isFavorite)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.favorite, size: 16, color: Colors.red),
                    ),
                  if (note.category != null && note.category!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        note.category!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (note.isLocked)
                    const Icon(Icons.lock, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.isLocked ? '🔒 Locked' : (note.title.isEmpty ? 'Untitled' : note.title),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.isLocked ? 'Tap to unlock' : note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: note.isLocked ? Colors.grey[400] : Colors.grey[700],
                    fontStyle: note.isLocked ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(note.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (note.reminderDate != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.alarm, size: 12, color: Colors.grey[500]),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}