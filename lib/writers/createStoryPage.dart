import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:readershaven/main.dart';
import 'package:readershaven/core/constants.dart';
import 'writestorypage.dart';

// ─────────────────────────────────────────────────────────────
// Create Story Page
// Writer fills in story details before writing
// ─────────────────────────────────────────────────────────────

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedGenre = 'Fantasy';
  String _selectedLanguage = 'English';
  String _selectedAudience = 'Everyone';
  File? _coverImage;
  bool _isSaving = false;

  final List<String> _languages = ['English', 'Malay', 'Chinese', 'Other'];
  final List<String> _audiences = ['Everyone', 'Teen (13+)', 'Mature (18+)'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _coverImage = File(picked.path));
  }

  Future<void> _createStory() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a title', isError: true);
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      String? coverUrl;

      // Upload cover image if selected
      if (_coverImage != null) {
        final path = 'covers/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('covers').upload(
              path,
              _coverImage!,
              fileOptions: const FileOptions(upsert: true),
            );
        coverUrl = supabase.storage.from('covers').getPublicUrl(path);
      }

      // Insert story as draft
      final story = await supabase.from('stories').insert({
        'author_id': userId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'genre': _selectedGenre,
        'language': _selectedLanguage,
        'audience_rating': _selectedAudience,
        'cover_url': coverUrl,
        'is_draft': true,
        'is_published': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      if (!mounted) return;

      // Navigate to writing page with the new story
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WriteStoryPage(
            storyId: story['id'],
            storyTitle: story['title'],
          ),
        ),
      );
    } catch (e) {
      _showSnack('Failed to create story: $e', isError: true);
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
        title: const Text('New Story'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _createStory,
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
                  : const Text('Next →',
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
            // ── Cover image picker ──
            Center(
              child: GestureDetector(
                onTap: _pickCover,
                child: Container(
                  width: 160,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.brown.shade300, width: 1.5),
                    image: _coverImage != null
                        ? DecorationImage(
                            image: FileImage(_coverImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                size: 36, color: Colors.brown.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Upload Cover',
                              style: TextStyle(
                                  color: Colors.brown.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recommended: 400×600px',
                              style: TextStyle(
                                  color: Colors.brown.shade400, fontSize: 10),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Title ──
            _label('Story Title'),
            const SizedBox(height: 8),
            _field(_titleCtrl, 'Enter your story title...'),

            const SizedBox(height: 20),

            // ── Description ──
            _label('Description'),
            const SizedBox(height: 8),
            _field(
              _descCtrl,
              'Write a short description of your story...',
              maxLines: 4,
            ),

            const SizedBox(height: 20),

            // ── Genre ──
            _label('Genre'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres
                  .where((g) => g != 'All')
                  .map((g) => FilterChip(
                        label: Text(g),
                        selected: _selectedGenre == g,
                        onSelected: (_) => setState(() => _selectedGenre = g),
                        selectedColor: const Color(0xFF6B4226),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _selectedGenre == g
                              ? Colors.white
                              : Colors.brown.shade800,
                          fontWeight: _selectedGenre == g
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.brown.shade100,
                        side: BorderSide(
                          color: _selectedGenre == g
                              ? const Color(0xFF6B4226)
                              : Colors.brown.shade300,
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // ── Language ──
            _label('Language'),
            const SizedBox(height: 8),
            _dropdown(
              value: _selectedLanguage,
              items: _languages,
              onChanged: (v) => setState(() => _selectedLanguage = v!),
            ),

            const SizedBox(height: 20),

            // ── Audience ──
            _label('Audience'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _audiences
                  .map((a) => ChoiceChip(
                        label: Text(a),
                        selected: _selectedAudience == a,
                        onSelected: (_) =>
                            setState(() => _selectedAudience = a),
                        selectedColor: const Color(0xFF6B4226),
                        labelStyle: TextStyle(
                          color: _selectedAudience == a
                              ? Colors.white
                              : Colors.brown.shade800,
                        ),
                        backgroundColor: Colors.brown.shade100,
                      ))
                  .toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      );

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
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
          borderSide: const BorderSide(color: Color(0xFF6B4226), width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}