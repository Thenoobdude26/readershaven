import 'package:flutter/material.dart';
import 'package:readershaven/main.dart';

// ─────────────────────────────────────────────────────────────
// Create Post Page
// User creates a new forum post
// ─────────────────────────────────────────────────────────────

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _selectedTag;
  bool _isSaving = false;

  final List<String> _tags = [
    'General',
    'Writing Tips',
    'Feedback',
    'Discussion',
    'Announcement',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a title', isError: true);
      return;
    }
    if (_bodyCtrl.text.trim().isEmpty) {
      _showSnack('Please enter some content', isError: true);
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await supabase.from('forum_posts').insert({
        'author_id': userId,
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'tag': _selectedTag,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed to post: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF6B4226),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text('New Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD261),
                foregroundColor: const Color(0xFF1A0A00),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1A0A00)),
                    )
                  : const Text('Post',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Title'),
            const SizedBox(height: 8),
            _field(_titleCtrl, 'What\'s on your mind?'),

            const SizedBox(height: 20),

            _label('Content'),
            const SizedBox(height: 8),
            _field(
              _bodyCtrl,
              'Share your thoughts, questions, or ideas...',
              maxLines: 8,
            ),

            const SizedBox(height: 20),

            _label('Tag (optional)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((t) {
                final selected = _selectedTag == t;
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedTag = selected ? null : t),
                  selectedColor: const Color(0xFF6B4226),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.brown.shade800,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.brown.shade100,
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF6B4226)
                        : Colors.brown.shade300,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4226),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Post',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.brown.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.brown.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6B4226), width: 1.5),
        ),
      ),
    );
  }
}