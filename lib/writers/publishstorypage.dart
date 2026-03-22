import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';

// ─────────────────────────────────────────────────────────────
// Publish Story Page
// Final review and publish to Supabase
// ─────────────────────────────────────────────────────────────

class PublishStoryPage extends StatefulWidget {
  final String storyId;

  const PublishStoryPage({super.key, required this.storyId});

  @override
  State<PublishStoryPage> createState() => _PublishStoryPageState();
}

class _PublishStoryPageState extends State<PublishStoryPage> {
  Map<String, dynamic>? _story;
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = true;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      final story = await supabase
          .from('stories')
          .select(
            'id, title, description, cover_url, genre, language, audience_rating',
          )
          .eq('id', widget.storyId)
          .single();

      final chapters = await supabase
          .from('chapters')
          .select('id, chapter_num, title')
          .eq('story_id', widget.storyId)
          .order('chapter_num', ascending: true);

      if (!mounted) return;
      setState(() {
        _story = story;
        _chapters = List<Map<String, dynamic>>.from(chapters);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _publish() async {
    if (_chapters.isEmpty) {
      _showSnack('Add at least one chapter before publishing', isError: true);
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await supabase
          .from('stories')
          .update({'is_draft': false, 'is_published': true})
          .eq('id', widget.storyId);

      if (!mounted) return;
      // Pop all the way back to home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Story published!'),
          backgroundColor: Color(0xFF6B4226),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showSnack('Failed to publish: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF6B4226),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6B4226)),
        ),
      );
    }

    final coverUrl = _story?['cover_url'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text('Publish Story'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD261),
                foregroundColor: const Color(0xFF1A0A00),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A0A00),
                      ),
                    )
                  : const Text(
                      'Publish',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover preview ──
            Center(
              child: Container(
                width: 160,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.brown.shade200,
                  borderRadius: BorderRadius.circular(16),
                  image: coverUrl != null
                      ? DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: coverUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.auto_stories,
                          size: 48,
                          color: Colors.white54,
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            // ── Story details summary ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _story?['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(Icons.category_outlined, _story?['genre'] ?? ''),
                  const SizedBox(height: 6),
                  _detailRow(Icons.language, _story?['language'] ?? ''),
                  const SizedBox(height: 6),
                  _detailRow(
                    Icons.people_outline,
                    _story?['audience_rating'] ?? '',
                  ),
                  const SizedBox(height: 12),
                  if ((_story?['description'] ?? '').isNotEmpty) ...[
                    Text(
                      _story!['description'],
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Chapters list ──
            Text(
              'Chapters (${_chapters.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_chapters.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No chapters yet — go back and write!',
                    style: TextStyle(color: Colors.brown.shade400),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _chapters.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: Colors.brown.shade100, height: 1),
                  itemBuilder: (_, i) {
                    final ch = _chapters[i];
                    return ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.brown.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${ch['chapter_num']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        ch['title'] ?? 'Chapter ${ch['chapter_num']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade400,
                        size: 18,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 28),

            // ── Publish button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPublishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4226),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Publish Story',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.brown.shade400),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.brown.shade600)),
      ],
    );
  }
}
