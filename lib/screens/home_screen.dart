import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/note.dart';
import '../../utils/debouncer.dart';
import '../../utils/time_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _storageKey = 'minimalist_notes_data';
  List<Note> _notes = [];
  Note? _activeNote;

  final _debouncer = Debouncer(milliseconds: 500);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // --- Storage Engine ---
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString(_storageKey);

    if (notesJson != null) {
      final List<dynamic> decoded = jsonDecode(notesJson);
      setState(() {
        _notes = decoded.map((item) => Note.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveNotesToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  // --- State Actions ---
  void _addNote() {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _notes.insert(0, newNote);
      _setActiveNote(newNote);
    });

    _saveNotesToDisk();
  }

  Future<void> _deleteNote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This action cannot be undone.'),
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
      setState(() {
        _notes.removeWhere((note) => note.id == id);
        if (_activeNote?.id == id) {
          _activeNote = null;
          _titleController.clear();
          _contentController.clear();
        }
      });
      _saveNotesToDisk();
    }
  }

  void _setActiveNote(Note note) {
    setState(() {
      _activeNote = note;
      _titleController.text = note.title;
      _contentController.text = note.content;
    });
  }

  void _onEditorChanged() {
    if (_activeNote == null) return;

    _debouncer.run(() {
      setState(() {
        _activeNote!.title = _titleController.text;
        _activeNote!.content = _contentController.text;
        _activeNote!.updatedAt = DateTime.now().millisecondsSinceEpoch;

        _notes.removeWhere((n) => n.id == _activeNote!.id);
        _notes.insert(0, _activeNote!);
      });
      _saveNotesToDisk();
    });
  }

  String _getDisplayTitle(Note note) {
    if (note.title.trim().isNotEmpty) return note.title;
    if (note.content.trim().isNotEmpty) {
      final firstLine = note.content.split('\n').first.trim();
      return firstLine.length > 30 ? '${firstLine.substring(0, 30)}...' : firstLine;
    }
    return 'New Note';
  }

  // --- UI Builders ---
  Widget _buildSidebar(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 300,
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 24),
                  onPressed: _addNote,
                  splashRadius: 20,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: _notes.isEmpty
                ? const Center(
                    child: Text(
                      'No notes yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final isActive = _activeNote?.id == note.id;

                      return InkWell(
                        onTap: () {
                          _setActiveNote(note);
                          if (isMobile) Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFF1F5F9) : null,
                            border: Border(
                              left: BorderSide(
                                color: isActive ? const Color(0xFF0F172A) : Colors.transparent,
                                width: 4,
                              ),
                              bottom: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getDisplayTitle(note),
                                      style: TextStyle(
                                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      getRelativeTime(note.updatedAt),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                onPressed: () => _deleteNote(note.id),
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(bool isMobile) {
    if (_activeNote == null) {
      return Scaffold(
        appBar: isMobile ? AppBar(leading: const _DrawerMenuButton()) : null,
        body: const Center(
          child: Text('Select a note to begin.', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: isMobile ? AppBar(leading: const _DrawerMenuButton()) : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              onChanged: (_) => _onEditorChanged(),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                onChanged: (_) => _onEditorChanged(),
                decoration: const InputDecoration(
                  hintText: 'Start typing...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return Scaffold(
            drawer: Drawer(child: _buildSidebar(true)),
            body: _buildEditor(true),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _buildSidebar(false),
              Expanded(child: _buildEditor(false)),
            ],
          ),
        );
      },
    );
  }
}

class _DrawerMenuButton extends StatelessWidget {
  const _DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => Scaffold.of(context).openDrawer(),
    );
  }
}