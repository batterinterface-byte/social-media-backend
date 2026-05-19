import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';

enum TodoFilter { all, pending, completed }

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Todo> _todos = [];
  bool _isLoading = true;
  TodoFilter _currentFilter = TodoFilter.pending;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTodos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentFilter = TodoFilter.all;
          break;
        case 1:
          _currentFilter = TodoFilter.pending;
          break;
        case 2:
          _currentFilter = TodoFilter.completed;
          break;
      }
    });
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    List<Todo> todos;
    switch (_currentFilter) {
      case TodoFilter.completed:
        todos = await _dbHelper.getCompletedTodos();
        break;
      case TodoFilter.pending:
        todos = await _dbHelper.getPendingTodos();
        break;
      case TodoFilter.all:
        todos = await _dbHelper.getAllTodos();
        break;
    }
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  Future<void> _searchTodos(String query) async {
    if (query.isEmpty) {
      _loadTodos();
      return;
    }
    setState(() => _isLoading = true);
    final todos = await _dbHelper.searchTodos(query);
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  Future<void> _addTodo() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TodoEditSheet(),
    );
    if (result == true) _loadTodos();
  }

  Future<void> _editTodo(Todo todo) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TodoEditSheet(todo: todo),
    );
    if (result == true) _loadTodos();
  }

  Future<void> _toggleComplete(int id) async {
    await _dbHelper.toggleTodoComplete(id);
    _loadTodos();
  }

  Future<void> _deleteTodo(int id) async {
    await _dbHelper.deleteTodo(id);
    _loadTodos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todo deleted')),
      );
    }
  }

  Future<void> _clearCompleted() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed'),
        content: const Text('Delete all completed todos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _dbHelper.clearCompletedTodos();
      _loadTodos();
    }
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
                  hintText: 'Search todos...',
                  border: InputBorder.none,
                ),
                onChanged: _searchTodos,
              )
            : const Text('My Tasks'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadTodos();
                }
              });
            },
          ),
          if (_currentFilter == TodoFilter.completed)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCompleted,
              tooltip: 'Clear completed',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? _buildEmptyState()
              : _buildTodoList(isTablet),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTodo,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No tasks yet';
    if (_currentFilter == TodoFilter.completed) {
      message = 'No completed tasks';
    } else if (_currentFilter == TodoFilter.pending) {
      message = 'All tasks completed! 🎉';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
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
            'Tap + to add a new task',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(bool isTablet) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todos.length,
      itemBuilder: (context, index) => _buildTodoCard(_todos[index]),
    );
  }

  Widget _buildTodoCard(Todo todo) {
    final isOverdue = todo.dueDate != null &&
        todo.dueDate!.isBefore(DateTime.now()) &&
        !todo.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editTodo(todo),
        onLongPress: () => _showTodoOptions(todo),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: todo.isCompleted,
                onChanged: (_) => _toggleComplete(todo.id!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (todo.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin, size: 14, color: Colors.orange),
                          ),
                        Expanded(
                          child: Text(
                            todo.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.isCompleted ? Colors.grey : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (todo.description != null && todo.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityChip(todo.priority),
                        if (todo.dueDate != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: isOverdue ? Colors.red : Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d').format(todo.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOverdue ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(int priority) {
    Color color;
    String label;
    switch (priority) {
      case 3:
        color = Colors.red;
        label = 'High';
        break;
      case 2:
        color = Colors.orange;
        label = 'Medium';
        break;
      default:
        color = Colors.green;
        label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showTodoOptions(Todo todo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                todo.isCompleted
                    ? Icons.check_circle_outline
                    : Icons.check_circle,
              ),
              title: Text(todo.isCompleted ? 'Mark as pending' : 'Mark as done'),
              onTap: () {
                Navigator.pop(context);
                _toggleComplete(todo.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editTodo(todo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteTodo(todo.id!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TodoEditSheet extends StatefulWidget {
  final Todo? todo;

  const TodoEditSheet({super.key, this.todo});

  @override
  State<TodoEditSheet> createState() => _TodoEditSheetState();
}

class _TodoEditSheetState extends State<TodoEditSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _priority = 1;
  DateTime? _dueDate;
  bool _isPinned = false;
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
      _priority = widget.todo!.priority;
      _dueDate = widget.todo!.dueDate;
      _isPinned = widget.todo!.isPinned;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final now = DateTime.now();
    if (widget.todo != null) {
      final updated = widget.todo!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        isPinned: _isPinned,
        clearDueDate: _dueDate == null,
      );
      await _dbHelper.updateTodo(updated);
    } else {
      final todo = Todo(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _priority,
        createdAt: now,
        dueDate: _dueDate,
        isPinned: _isPinned,
      );
      await _dbHelper.insertTodo(todo);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );

      setState(() {
        _dueDate = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 23,
          time?.minute ?? 59,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.todo != null ? 'Edit Task' : 'New Task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text('Priority', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Low')),
                  ButtonSegment(value: 2, label: Text('Medium')),
                  ButtonSegment(value: 3, label: Text('High')),
                ],
                selected: {_priority},
                onSelectionChanged: (values) {
                  setState(() => _priority = values.first);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, yyyy • HH:mm').format(_dueDate!)
                      : 'Set due date',
                ),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _dueDate = null),
                      )
                    : null,
                onTap: _selectDueDate,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pin to top'),
                secondary: const Icon(Icons.push_pin),
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: Text(widget.todo != null ? 'Save' : 'Add Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}