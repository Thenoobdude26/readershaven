import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';
import 'chatroomlist.dart';
import 'package:readershaven/DM/dmlist.dart';
import 'forumpost.dart';
import 'createpost.dart';
import 'package:readershaven/profile/publicuserprofile.dart';

// ─────────────────────────────────────────────────────────────
// Community Page
// Forum posts as default, chatrooms and DMs via appbar icons
// ─────────────────────────────────────────────────────────────

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  List<Map<String, dynamic>> _userResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  String _selectedTag = 'All';

  final List<String> _tags = [
    'All',
    'General',
    'Writing Tips',
    'Feedback',
    'Discussion',
    'Announcement',
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final data = await supabase
          .from('forum_posts_with_counts')
          .select()
          .order('created_at', ascending: false);

      // fetch author profiles separately
      final postsWithProfiles = await Future.wait(
        (data as List).map((post) async {
          final profile = await supabase
              .from('profiles')
              .select('id, username, avatar_url')
              .eq('id', post['author_id'])
              .maybeSingle();
          return {...post, 'profiles': profile};
        }),
      );

      if (!mounted) return;
      setState(() {
        _posts = List<Map<String, dynamic>>.from(postsWithProfiles);
        _filteredPosts = _posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _userResults = [];
        _applyTagFilter();
      });
      return;
    }
    setState(() => _isSearching = true);
    _search(query);
  }

  Future<void> _search(String query) async {
    final matchedPosts = _posts.where((p) {
      return (p['title'] ?? '').toLowerCase().contains(query) ||
          (p['body'] ?? '').toLowerCase().contains(query);
    }).toList();

    final users = await supabase
        .from('profiles')
        .select('id, username, avatar_url, role')
        .ilike('username', '%$query%')
        .limit(5);

    if (!mounted) return;
    setState(() {
      _filteredPosts = matchedPosts;
      _userResults = List<Map<String, dynamic>>.from(users);
    });
  }

  void _applyTagFilter() {
    setState(() {
      _filteredPosts = _selectedTag == 'All'
          ? _posts
          : _posts.where((p) => p['tag'] == _selectedTag).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Chatrooms',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatroomListPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            tooltip: 'Direct Messages',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DmListPage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          );
          if (created == true) _loadPosts();
        },
        child: const Icon(Icons.edit),
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search posts or users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyTagFilter();
                        },
                      )
                    : null,
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

          // ── Tag chips (hidden during search) ──
          if (!_isSearching)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = _tags[i] == _selectedTag;
                  return ChoiceChip(
                    label: Text(_tags[i]),
                    selected: selected,
                    selectedColor: const Color(0xFF6B4226),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.brown.shade800,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.brown.shade100,
                    onSelected: (_) {
                      setState(() => _selectedTag = _tags[i]);
                      _applyTagFilter();
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // ── Content ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF6B4226)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF6B4226),
                    onRefresh: _loadPosts,
                    child: _isSearching &&
                            (_userResults.isNotEmpty ||
                                _filteredPosts.isNotEmpty)
                        ? _buildSearchResults()
                        : _filteredPosts.isEmpty
                            ? Center(
                                child: Text(
                                  'No posts yet — be the first!',
                                  style: TextStyle(
                                      color: Colors.brown.shade300),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 80),
                                itemCount: _filteredPosts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) =>
                                    _buildPostCard(_filteredPosts[i]),
                              ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        if (_userResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Users',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700),
            ),
          ),
          ..._userResults.map(
            (u) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userId: u['id']),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.brown.shade200,
                      backgroundImage: u['avatar_url'] != null
                          ? NetworkImage(u['avatar_url'])
                          : null,
                      child: u['avatar_url'] == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['username'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(
                            (u['role'] ?? 'reader').toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.brown.shade400),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_filteredPosts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Posts',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700),
            ),
          ),
          ..._filteredPosts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPostCard(p),
              )),
        ],
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final profile = post['profiles'] as Map<String, dynamic>?;
    final tag = post['tag'] as String?;
    final likeCount = post['like_count'] ?? 0;
    final dislikeCount = post['dislike_count'] ?? 0;
    final commentCount = post['comment_count'] ?? 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForumPostDetailPage(postId: post['id']),
          ),
        );
        _loadPosts();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfilePage(userId: post['author_id']),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.brown.shade200,
                    backgroundImage: profile?['avatar_url'] != null
                        ? NetworkImage(profile!['avatar_url'])
                        : null,
                    child: profile?['avatar_url'] == null
                        ? const Icon(Icons.person,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfilePage(userId: post['author_id']),
                    ),
                  ),
                  child: Text(
                    profile?['username'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ),
                const Spacer(),
                if (tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                          fontSize: 10, color: Colors.brown.shade700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post['title'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              post['body'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.brown.shade700,
                  height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.thumb_up_outlined,
                    size: 14, color: Colors.brown.shade400),
                const SizedBox(width: 4),
                Text('$likeCount',
                    style: TextStyle(
                        fontSize: 12, color: Colors.brown.shade400)),
                const SizedBox(width: 12),
                Icon(Icons.thumb_down_outlined,
                    size: 14, color: Colors.brown.shade400),
                const SizedBox(width: 4),
                Text('$dislikeCount',
                    style: TextStyle(
                        fontSize: 12, color: Colors.brown.shade400)),
                const SizedBox(width: 12),
                Icon(Icons.comment_outlined,
                    size: 14, color: Colors.brown.shade400),
                const SizedBox(width: 4),
                Text('$commentCount',
                    style: TextStyle(
                        fontSize: 12, color: Colors.brown.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}