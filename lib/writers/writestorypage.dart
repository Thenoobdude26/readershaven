import 'dart:async';
import 'package:flutter/material.dart';
import 'package:readershaven/main.dart';
import 'publishstorypage.dart';
import 'editstorypage.dart';

// ─────────────────────────────────────────────────────────────
// Write Story Page
// Text editor with auto-save and basic formatting
// ─────────────────────────────────────────────────────────────

class WriteStoryPage extends StatefulWidget {
  final String storyId;
  final String storyTitle;
  // If editing an existing chapter, pass these
  final String? chapterId;
  final int? chapterNum;

  const WriteStoryPage({
    super.key,
    required this.storyId,
    required this.storyTitle,
    this.chapterId,
    this.chapterNum,
  });

  @override
  State<WriteStoryPage> createState() => _WriteStoryPageState();
}

class _WriteStoryPageState extends State<WriteStoryPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSaving = false;
  bool _savedOnce = false;
  String? _currentChapterId;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _currentChapterId = widget.chapterId;
    if (widget.chapterId != null) _loadExistingChapter();
    _loadChapters();
    _contentCtrl.addListener(
      _scheduleAutoSave,
    ); // Auto-save every 30 seconds while typing
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), _saveDraft);
  }

  List<Map<String, dynamic>> _chapters = [];

  Future<void> _loadChapters() async {
    final data = await supabase
        .from('chapters')
        .select('id, chapter_num, title')
        .eq('story_id', widget.storyId)
        .order('chapter_num', ascending: true);
    if (!mounted) return;
    setState(() => _chapters = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _loadExistingChapter() async {
    try {
      final data = await supabase
          .from('chapters')
          .select('title, content')
          .eq('id', widget.chapterId!)
          .single();

      if (!mounted) return;
      _titleCtrl.text = data['title'] ?? '';
      _contentCtrl.text = data['content'] ?? '';
    } catch (_) {}
  }

  Future<void> _loadChapterById(String chapterId) async {
    setState(() {
      _currentChapterId = chapterId;
      _titleCtrl.clear();
      _contentCtrl.clear();
    });

    final data = await supabase
        .from('chapters')
        .select('title, content')
        .eq('id', chapterId)
        .single();

    if (!mounted) return;
    setState(() {
      _titleCtrl.text = data['title'] ?? '';
      _contentCtrl.text = data['content'] ?? '';
    });
  }

  void _newChapter() {
    setState(() {
      _currentChapterId = null;
      _titleCtrl.clear();
      _contentCtrl.clear();
      _savedOnce = false;
    });
  }

  Future<void> _saveDraft() async {
    if (_contentCtrl.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      if (_currentChapterId == null) {
        // Create new chapter
        final chapter = await supabase
            .from('chapters')
            .insert({
              'story_id': widget.storyId,
              'chapter_num': _chapters.length + 1,
              'title': _titleCtrl.text.trim().isEmpty
                  ? 'Chapter ${widget.chapterNum ?? 1}'
                  : _titleCtrl.text.trim(),
              'content': _contentCtrl.text,
            })
            .select()
            .single();

        _currentChapterId = chapter['id'];
      } else {
        // Update existing chapter
        await supabase
            .from('chapters')
            .update({
              'title': _titleCtrl.text.trim().isEmpty
                  ? 'Chapter ${widget.chapterNum ?? 1}'
                  : _titleCtrl.text.trim(),
              'content': _contentCtrl.text,
            })
            .eq('id', _currentChapterId!);
      }

      if (!mounted) return;
      setState(() => _savedOnce = true);
      await _loadChapters();
      _showSnack('Draft saved');
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Formatting helpers ──
  void _insertFormatting(String prefix, String suffix) {
    final text = _contentCtrl.text;
    final selection = _contentCtrl.selection;
    final selectedText = selection.textInside(text);

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );

    _contentCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            selection.start +
            prefix.length +
            selectedText.length +
            suffix.length,
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF6B4226),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.brown.shade800,
        elevation: 0,
        title: Text(
          widget.storyTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
        actions: [
          // Save indicator
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6B4226),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown.shade400,
                    ),
                  ),
                ],
              ),
            )
          else if (_savedOnce)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown.shade400,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Edit story details',
            onPressed: () async {
              // first load the story details
              final story = await supabase
                  .from('stories')
                  .select(
                    'title, description, genre, language, audience_rating',
                  )
                  .eq('id', widget.storyId)
                  .single();

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditStoryPage(
                    storyId: widget.storyId,
                    title: story['title'] ?? '',
                    description: story['description'] ?? '',
                    genre: story['genre'] ?? 'Fantasy',
                    language: story['language'] ?? 'English',
                    audienceRating: story['audience_rating'] ?? 'Everyone',
                  ),
                ),
              );
            },
          ),
          //chapters
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Chapters',
            onPressed: _showChaptersSheet,
          ),
          // Manual save
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveDraft,
            tooltip: 'Save draft',
          ),
          // Next → Publish
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () async {
                await _saveDraft();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublishStoryPage(storyId: widget.storyId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4226),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Publish →',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Divider ──
          Divider(color: Colors.brown.shade100, height: 1),

          // ── Formatting toolbar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _formatButton(
                  icon: Icons.format_bold,
                  tooltip: 'Bold',
                  onTap: () => _insertFormatting('**', '**'),
                ),
                _formatButton(
                  icon: Icons.format_italic,
                  tooltip: 'Italic',
                  onTap: () => _insertFormatting('_', '_'),
                ),
                _formatButton(
                  icon: Icons.format_quote,
                  tooltip: 'Quote',
                  onTap: () => _insertFormatting('"', '"'),
                ),
                const VerticalDivider(width: 20),
                _formatButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'List',
                  onTap: () => _insertFormatting('\n• ', ''),
                ),
              ],
            ),
          ),

          Divider(color: Colors.brown.shade100, height: 1),

          // ── Chapter title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Chapter title...',
                hintStyle: TextStyle(
                  color: Colors.brown.shade300,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
              ),
            ),
          ),

          Divider(color: Colors.brown.shade100, indent: 20, endIndent: 20),

          // ── Content area ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _contentCtrl,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 17, height: 1.8),
                decoration: InputDecoration(
                  hintText: 'Once upon a time...',
                  hintStyle: TextStyle(
                    color: Colors.brown.shade300,
                    fontSize: 17,
                    height: 1.8,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChaptersSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Chapters',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _chapters.length,
              itemBuilder: (_, i) {
                final ch = _chapters[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.brown.shade100,
                    child: Text(
                      '${ch['chapter_num']}',
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(ch['title'] ?? 'Chapter ${ch['chapter_num']}'),
                  trailing: _currentChapterId == ch['id']
                      ? const Icon(Icons.edit, color: Color(0xFF6B4226))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _loadChapterById(ch['id']);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _newChapter();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Chapter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4226),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      color: Colors.brown.shade600,
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}
