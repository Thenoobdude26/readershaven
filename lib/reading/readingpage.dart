import 'package:flutter/material.dart';
import 'package:readershaven/main.dart';

// ─────────────────────────────────────────────────────────────
// Reading Page
// The actual story reading experience
// ─────────────────────────────────────────────────────────────

class ReadingPage extends StatefulWidget {
  final String storyId;
  final String chapterId;
  final String chapterTitle;
  final String storyTitle;

  const ReadingPage({
    super.key,
    required this.storyId,
    required this.chapterId,
    required this.chapterTitle,
    required this.storyTitle,
  });

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  String _content = '';
  bool _isLoading = true;
  double _fontSize = 17;
  final ScrollController _scrollController = ScrollController();
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadChapter();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChapter() async {
    try {
      final data = await supabase
          .from('chapters')
          .select('content')
          .eq('id', widget.chapterId)
          .single();

      if (!mounted) return;
      setState(() {
        _content = data['content'] ?? '';
        _isLoading = false;
      });

      // Load existing progress
      await _loadProgress();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProgress() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await supabase
          .from('reading_progress')
          .select('progress')
          .eq('user_id', userId)
          .eq('story_id', widget.storyId)
          .eq('chapter_id', widget.chapterId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() => _readProgress = (data['progress'] as num).toDouble());

        // Scroll to saved position after frame renders
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            _scrollController.jumpTo(maxScroll * _readProgress);
          }
        });
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max == 0) return;
    final progress = (_scrollController.offset / max).clamp(0.0, 1.0);
    setState(() => _readProgress = progress);

    // Debounce save — save every 5% change
    if ((progress * 20).floor() != (_readProgress * 20).floor()) {
      _saveProgress(progress);
    }
  }

  Future<void> _saveProgress(double progress) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('reading_progress').upsert({
        'user_id': userId,
        'story_id': widget.storyId,
        'chapter_id': widget.chapterId,
        'progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, story_id, chapter_id');
    } catch (_) {}
  }

  void _showFontSizeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Font Size',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_fontSize > 12) {
                        setState(() => _fontSize -= 1);
                        setModalState(() {});
                      }
                    },
                  ),
                  Text(
                    '${_fontSize.toInt()}px',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_fontSize < 28) {
                        setState(() => _fontSize += 1);
                        setModalState(() {});
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Preview
              Text(
                'The quick brown fox jumps over the lazy dog.',
                style: TextStyle(fontSize: _fontSize, height: 1.7),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(
        storyId: widget.storyId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.storyTitle,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text(
              widget.chapterTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Font size',
            onPressed: _showFontSizeDialog,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _readProgress,
            backgroundColor: Colors.brown.shade700,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD261)),
            minHeight: 3,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B4226)),
            )
          : _content.isEmpty
              ? Center(
                  child: Text(
                    'No content yet',
                    style: TextStyle(color: Colors.brown.shade400),
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Text(
                    _content,
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.8,
                      color: Colors.brown.shade900,
                    ),
                  ),
                ),

      // ── Bottom action bar ──
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _bottomAction(Icons.bookmark_outline, 'Bookmark', () {}),
              _bottomAction(Icons.chat_bubble_outline, 'Comments', _showComments),
              _bottomAction(Icons.share_outlined, 'Share', () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.brown.shade600, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.brown.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Comments Bottom Sheet
// ─────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final String storyId;

  const _CommentsSheet({required this.storyId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  final _commentCtrl = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final data = await supabase
          .from('comments')
          .select('id, content, created_at, profiles(username, avatar_url)')
          .eq('story_id', widget.storyId)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _comments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || _commentCtrl.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await supabase.from('comments').insert({
        'story_id': widget.storyId,
        'user_id': userId,
        'content': _commentCtrl.text.trim(),
      });
      _commentCtrl.clear();
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
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
            'Comments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B4226)))
                : _comments.isEmpty
                    ? const Center(child: Text('No comments yet — be the first!'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          final profile = c['profiles'] as Map<String, dynamic>?;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.brown.shade200,
                                  backgroundImage: profile?['avatar_url'] != null
                                      ? NetworkImage(profile!['avatar_url'])
                                      : null,
                                  child: profile?['avatar_url'] == null
                                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile?['username'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(c['content'] ?? '', style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          // Comment input
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Leave a comment...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isPosting
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B4226)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF6B4226)),
                        onPressed: _postComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}