import 'package:flutter/material.dart';
import 'package:readershaven/main.dart';
import 'package:readershaven/core/constants.dart';

class EditStoryPage extends StatefulWidget {
  final String storyId;
  final String title;
  final String description;
  final String genre;
  final String language;
  final String audienceRating;

  const EditStoryPage({
    super.key,
    required this.storyId,
    required this.title,
    required this.description,
    required this.genre,
    required this.language,
    required this.audienceRating,
  });

  @override
  State<EditStoryPage> createState() => _EditStoryPageState();
}

class _EditStoryPageState extends State<EditStoryPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late String _selectedGenre;
  late String _selectedLanguage;
  late String _selectedAudience;
  bool _isSaving = false;

  final List<String> _languages = ['English', 'Malay', 'Chinese', 'Other'];
  final List<String> _audiences = ['Everyone', 'Teen (13+)', 'Mature (18+)'];

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.title;
    _descCtrl.text = widget.description;
    _selectedGenre = widget.genre;
    _selectedLanguage = widget.language;
    _selectedAudience = widget.audienceRating;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Title cannot be empty', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await supabase.from('stories').update({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'genre': _selectedGenre,
        'language': _selectedLanguage,
        'audience_rating': _selectedAudience,
      }).eq('id', widget.storyId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
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
        title: const Text('Edit Story'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
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
                  : const Text('Save',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  items: _languages
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                ),
              ),
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

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4226),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes',
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
}