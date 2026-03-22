import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';

// ─────────────────────────────────────────────────────────────
// Admin Content Tab
// View and delete stories and forum posts
// ─────────────────────────────────────────────────────────────

class AdminContentTab extends StatefulWidget {
  const AdminContentTab({super.key});

  @override
  State<AdminContentTab> createState() => _AdminContentTabState();
}

class _AdminContentTabState extends State<AdminContentTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _stories = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingStories = true;
  bool _isLoadingPosts = true;
  final _storySearchCtrl = TextEditingController();
  final _postSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filteredStories = [];
  List<Map<String, dynamic>> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStories();
    _loadPosts();
    _storySearchCtrl.addListener(_filterStories);
    _postSearchCtrl.addListener(_filterPosts);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storySearchCtrl.dispose();
    _postSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoadingStories = true);
    try {
      final data = await supabase
          .from('stories')
          .select(
            'id, title, genre, is_published, is_draft, created_at, author_id, profiles!stories_author_id_fkey(username)',
          )
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _stories = List<Map<String, dynamic>>.from(data);
        _filteredStories = _stories;
        _isLoadingStories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStories = false);
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final data = await supabase
          .from('forum_posts')
          .select(
            'id, title, tag, created_at, author_id, profiles!forum_posts_author_id_fkey(username)',
          )
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _posts = List<Map<String, dynamic>>.from(data);
        _filteredPosts = _posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPosts = false);
    }
  }

  void _filterStories() {
    final q = _storySearchCtrl.text.toLowerCase();
    setState(() {
      _filteredStories = _stories.where((s) {
        return (s['title'] ?? '').toLowerCase().contains(q) ||
            ((s['profiles'] as Map?)?['username'] ?? '')
                .toLowerCase()
                .contains(q);
      }).toList();
    });
  }

  void _filterPosts() {
    final q = _postSearchCtrl.text.toLowerCase();
    setState(() {
      _filteredPosts = _posts.where((p) {
        return (p['title'] ?? '').toLowerCase().contains(q) ||
            ((p['profiles'] as Map?)?['username'] ?? '')
                .toLowerCase()
                .contains(q);
      }).toList();
    });
  }

  Future<void> _deleteStory(String storyId, String title) async {
    final confirmed = await _confirmDelete('story', title);
    if (!confirmed) return;

    try {
      await supabase.from('stories').delete().eq('id', storyId);
      _showSnack('Story deleted');
      await _loadStories();
    } catch (e) {
      _showSnack('Failed: $e', isError: true);
    }
  }

  Future<void> _deletePost(String postId, String title) async {
    final confirmed = await _confirmDelete('post', title);
    if (!confirmed) return;

    try {
      await supabase.from('forum_posts').delete().eq('id', postId);
      _showSnack('Post deleted');
      await _loadPosts();
    } catch (e) {
      _showSnack('Failed: $e', isError: true);
    }
  }

  Future<bool> _confirmDelete(String type, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text(
          'Are you sure you want to delete "$title"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6B4226),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6B4226),
          tabs: [
            Tab(text: 'Stories (${_stories.length})'),
            Tab(text: 'Posts (${_posts.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStoriesTab(),
              _buildPostsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoriesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _storySearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search stories or authors...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingStories
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF6B4226)),
                )
              : RefreshIndicator(
                  color: const Color(0xFF6B4226),
                  onRefresh: _loadStories,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filteredStories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _buildStoryCard(_filteredStories[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _postSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search posts or authors...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingPosts
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF6B4226)),
                )
              : RefreshIndicator(
                  color: const Color(0xFF6B4226),
                  onRefresh: _loadPosts,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filteredPosts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _buildPostCard(_filteredPosts[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final profile = story['profiles'] as Map<String, dynamic>?;
    final isPublished = story['is_published'] == true;
    final isDraft = story['is_draft'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.brown.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.auto_stories,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story['title'] ?? 'Untitled',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'by ${profile?['username'] ?? 'Unknown'}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.brown.shade500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDraft
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isDraft ? 'Draft' : 'Published',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDraft
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                    if (story['genre'] != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          story['genre'],
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.brown.shade700),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete story',
            onPressed: () =>
                _deleteStory(story['id'], story['title'] ?? 'Untitled'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final profile = post['profiles'] as Map<String, dynamic>?;
    final tag = post['tag'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6B4226).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.forum_outlined,
                color: Color(0xFF6B4226), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] ?? 'Untitled',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'by ${profile?['username'] ?? 'Unknown'}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.brown.shade500),
                ),
                if (tag != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                          fontSize: 10, color: Colors.brown.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete post',
            onPressed: () =>
                _deletePost(post['id'], post['title'] ?? 'Untitled'),
          ),
        ],
      ),
    );
  }
}