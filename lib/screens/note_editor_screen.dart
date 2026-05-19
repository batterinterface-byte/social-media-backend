import 'package:flutter/material.dart';
import '../models/note.dart';
import '../database/database_helper.dart';
import '../services/encryption_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _passwordController;
  bool _isEditing = false;
  bool _hasChanges = false;
  bool _isLocked = false;
  String? _selectedCategory;
  DateTime? _reminderDate;
  bool _isUnlocked = false;
  String _decryptedTitle = '';
  String _decryptedContent = '';

  final List<String> _defaultCategories = [
    'Personal',
    'Work',
    'Ideas',
    'Shopping',
    'Tasks',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _passwordController = TextEditingController();
    _isLocked = widget.note?.isLocked ?? false;
    _selectedCategory = widget.note?.category;
    _reminderDate = widget.note?.reminderDate;
    
    if (widget.note != null && widget.note!.isLocked) {
      _decryptedTitle = widget.note!.title;
      _decryptedContent = widget.note!.content;
    } else {
      _titleController.text = widget.note?.title ?? '';
      _contentController.text = widget.note?.content ?? '';
    }

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  bool get _isContentLocked {
    if (!_isLocked) return false;
    if (_isUnlocked) return false;
    return true;
  }

  Future<void> _saveNote() async {
    if (_isContentLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please unlock the note first')),
      );
      return;
    }

    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note is empty')),
      );
      return;
    }

    final now = DateTime.now();
    String? password;
    bool shouldBeLocked = _isLocked;

    if (_isLocked) {
      if (_passwordController.text.isNotEmpty) {
        password = EncryptionService.hashPassword(_passwordController.text);
      } else if (widget.note?.password != null) {
        password = widget.note?.password;
      }
      
      if (password != null && _isUnlocked) {
        title = EncryptionService.encrypt(title, _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : _decryptedTitle);
        content = EncryptionService.encrypt(content, _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : _decryptedContent);
      }
    }

    if (_isEditing && widget.note != null) {
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
        isLocked: shouldBeLocked,
        category: _selectedCategory,
        reminderDate: _reminderDate,
        password: shouldBeLocked ? password : null,
        clearCategory: _selectedCategory == null,
        clearReminder: _reminderDate == null,
        clearPassword: !shouldBeLocked,
      );
      await _dbHelper.updateNote(updatedNote);
    } else {
      String finalTitle = title;
      String finalContent = content;
      
      if (_isLocked && _passwordController.text.isNotEmpty) {
        finalTitle = EncryptionService.encrypt(title, _passwordController.text);
        finalContent = EncryptionService.encrypt(content, _passwordController.text);
      }

      final newNote = Note(
        title: finalTitle,
        content: finalContent,
        createdAt: now,
        updatedAt: now,
        isLocked: _isLocked,
        category: _selectedCategory,
        reminderDate: _reminderDate,
        password: _isLocked ? password : null,
      );
      await _dbHelper.insertNote(newNote);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _selectReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _reminderDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _hasChanges = true;
        });
      }
    }
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ..._defaultCategories.map((category) => ListTile(
              leading: Icon(
                _selectedCategory == category ? Icons.check_circle : Icons.circle_outlined,
                color: _selectedCategory == category
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(category),
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _hasChanges = true;
                });
                Navigator.pop(context);
              },
            )),
            if (_selectedCategory != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Clear Category'),
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                    _hasChanges = true;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showLockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isLocked ? 'Remove Lock' : 'Lock Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isLocked
                ? 'Do you want to remove password protection?'
                : 'Set a password to protect this note'),
            if (!_isLocked) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (_isLocked) {
                  _isLocked = false;
                  _passwordController.clear();
                  _isUnlocked = false;
                } else {
                  _isLocked = _passwordController.text.isNotEmpty;
                }
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: Text(_isLocked ? 'Remove' : 'Lock'),
          ),
        ],
      ),
    );
  }

  void _unlockNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (widget.note?.password != null) {
                if (EncryptionService.verifyPassword(
                  widget.note?.password,
                  _passwordController.text,
                )) {
                  final decryptedTitle = EncryptionService.decrypt(
                    widget.note!.title,
                    _passwordController.text,
                  );
                  final decryptedContent = EncryptionService.decrypt(
                    widget.note!.content,
                    _passwordController.text,
                  );
                  setState(() {
                    _isUnlocked = true;
                    _decryptedTitle = _passwordController.text;
                    _decryptedContent = _passwordController.text;
                    _titleController.text = decryptedTitle;
                    _contentController.text = decryptedContent;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wrong password')),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 600.0 : double.infinity;

    if (_isContentLocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Locked Note'),
          actions: [
            IconButton(
              icon: const Icon(Icons.lock_open),
              onPressed: _unlockNote,
              tooltip: 'Unlock',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'This note is locked',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _unlockNote,
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Note' : 'New Note'),
          actions: [
            IconButton(
              icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
              onPressed: _showLockDialog,
              tooltip: _isLocked ? 'Unlock' : 'Lock',
            ),
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: _showCategorySelector,
              tooltip: 'Category',
            ),
            IconButton(
              icon: const Icon(Icons.alarm),
              onPressed: _selectReminder,
              tooltip: 'Reminder',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
          ],
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_selectedCategory != null) ...[
                        Chip(
                          label: Text(_selectedCategory!),
                          onDeleted: () {
                            setState(() {
                              _selectedCategory = null;
                              _hasChanges = true;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_reminderDate != null)
                        Chip(
                          avatar: const Icon(Icons.alarm, size: 16),
                          label: Text(
                            '${_reminderDate!.day}/${_reminderDate!.month}',
                          ),
                          onDeleted: () {
                            setState(() {
                              _reminderDate = null;
                              _hasChanges = true;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    maxLines: 1,
                  ),
                  const Divider(),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}