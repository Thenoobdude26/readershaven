import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';
import 'readingpage.dart';

// ─────────────────────────────────────────────────────────────
// Story Detail Page
// Shown when user taps a story card in Discover or Library
// ─────────────────────────────────────────────────────────────

class StoryDetailPage extends StatefulWidget {
  final String storyId;

  const StoryDetailPage({super.key, required this.storyId});

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  Map<String, dynamic>? _story;
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = true;
  bool _descExpanded = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    final userId = supabase.auth.currentUser?.id;

    try {
      // Load story details with author profile
      final story = await supabase
          .from('stories')
          .select('id, title, description, cover_url, genre, created_at, profiles(id, username, avatar_url)')
          .eq('id', widget.storyId)
          .single();

      // Load chapters ordered by chapter number
      final chapters = await supabase
          .from('chapters')
          .select('id, chapter_num, title, created_at')
          .eq('story_id', widget.storyId)
          .order('chapter_num', ascending: true);

      // Check if user has bookmarked this story
      bool bookmarked = false;
      if (userId != null) {
        final bookmark = await supabase
            .from('bookmarks')
            .select('story_id')
            .eq('user_id', userId)
            .eq('story_id', widget.storyId)
            .maybeSingle();
        bookmarked = bookmark != null;
      }

      if (!mounted) return;
      setState(() {
        _story = story;
        _chapters = List<Map<String, dynamic>>.from(chapters);
        _isBookmarked = bookmarked;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (_isBookmarked) {
        await supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('story_id', widget.storyId);
      } else {
        await supabase.from('bookmarks').insert({
          'user_id': userId,
          'story_id': widget.storyId,
        });
      }
      setState(() => _isBookmarked = !_isBookmarked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
      );
    }
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

    if (_story == null) {
      return const Scaffold(
        body: Center(child: Text('Story not found')),
      );
    }

    final author = (_story!['profiles'] as Map<String, dynamic>?);
    final coverUrl = _story!['cover_url'] as String?;
    final description = _story!['description'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: CustomScrollView(
        slivers: [
          // ── Collapsible app bar with cover image ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF6B4226),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: _isBookmarked ? const Color(0xFFFFD261) : Colors.white,
                ),
                onPressed: _toggleBookmark,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: coverUrl != null
                  ? Image.network(coverUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.brown.shade300,
                      child: const Center(
                        child: Icon(Icons.auto_stories, size: 80, color: Colors.white30),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Story info header ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _story!['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Author row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.brown.shade200,
                            backgroundImage: author?['avatar_url'] != null
                                ? NetworkImage(author!['avatar_url'])
                                : null,
                            child: author?['avatar_url'] == null
                                ? const Icon(Icons.person, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            author?['username'] ?? 'Unknown',
                            style: TextStyle(
                              color: Colors.brown.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Row(
                        children: [
                          _statChip(Icons.list_alt, '${_chapters.length} chapters'),
                          const SizedBox(width: 12),
                          if (_story!['genre'] != null)
                            _genreBadge(_story!['genre']),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Description ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: _descExpanded ? null : 3,
                        overflow: _descExpanded ? null : TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.brown.shade800,
                          height: 1.5,
                        ),
                      ),
                      if (description.length > 100) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => setState(() => _descExpanded = !_descExpanded),
                          child: Text(
                            _descExpanded ? 'Show less' : 'Read more',
                            style: const TextStyle(
                              color: Color(0xFF6B4226),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Chapter list ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chapters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_chapters.isEmpty)
                        Center(
                          child: Text(
                            'No chapters yet',
                            style: TextStyle(color: Colors.brown.shade400),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _chapters.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.brown.shade100,
                            height: 1,
                          ),
                          itemBuilder: (context, i) {
                            final chapter = _chapters[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${chapter['chapter_num']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                chapter['title'] ?? 'Chapter ${chapter['chapter_num']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReadingPage(
                                    storyId: widget.storyId,
                                    chapterId: chapter['id'],
                                    chapterTitle: chapter['title'] ?? '',
                                    storyTitle: _story!['title'] ?? '',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                // Bottom padding for the Start Reading button
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── Start Reading button ──
      bottomNavigationBar: _chapters.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReadingPage(
                        storyId: widget.storyId,
                        chapterId: _chapters.first['id'],
                        chapterTitle: _chapters.first['title'] ?? '',
                        storyTitle: _story!['title'] ?? '',
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4226),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Start Reading',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.brown.shade400),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.brown.shade600),
        ),
      ],
    );
  }

  Widget _genreBadge(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        genre,
        style: TextStyle(fontSize: 12, color: Colors.brown.shade700),
      ),
    );
  }
}