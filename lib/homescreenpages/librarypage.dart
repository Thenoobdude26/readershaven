import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../reading/storydetailpage.dart';

final supabase = Supabase.instance.client;

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookmarks = [];
  List<Map<String, dynamic>> _readingProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final bookmarks = await supabase
          .from('bookmarks')
          .select('story_id, stories(id, title, cover_url, created_at)')
          .eq('user_id', userId);

      final progress = await supabase
          .from('reading_progress')
          .select('progress, updated_at, stories(id, title, cover_url)')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _bookmarks = List<Map<String, dynamic>>.from(bookmarks);
        _readingProgress = List<Map<String, dynamic>>.from(progress);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // BUOLD TIME
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B4226)),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6B4226),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6B4226),
          tabs: [
            Tab(icon: Icon(Icons.bookmark, size: 20), text: 'Bookmarks'),
            Tab(icon: Icon(Icons.menu_book, size: 20), text: 'Reading'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildBookmarksList(), _buildReadingList()],
          ),
        ),
      ],
    );
  }

  //bookmarks
  Widget _buildBookmarksList() {
    if (_bookmarks.isEmpty) {
      return const Center(child: Text('No bookmarks yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarks.length,
      itemBuilder: (context, i) {
        final s = _bookmarks[i];
        final story = s['stories'] as Map<String, dynamic>?;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryDetailPage(storyId: story?['id'] ?? ''),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story?['title'] ?? 'Unknown'),
                      const SizedBox(height: 3),
                      Text(
                        story?['created_at'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.brown.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //readinglsit
  Widget _buildReadingList() {
    if (_readingProgress.isEmpty) {
      return const Center(child: Text('No story being read.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _readingProgress.length,
      itemBuilder: (context, i) {
        final item = _readingProgress[i];
        final story = item['stories'] as Map<String, dynamic>?;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryDetailPage(storyId: story?['id'] ?? ''),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story?['title'] ?? 'Unknown'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (item['progress'] as num?)?.toDouble() ?? 0.0,
                        backgroundColor: Colors.brown.shade100,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF6B4226),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['updated_at'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.brown.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
