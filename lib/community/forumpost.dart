import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';
import 'package:readershaven/profile/publicuserprofile.dart';

// ─────────────────────────────────────────────────────────────
// Forum Post Detail Page
// Full post with likes, dislikes and comments
// ─────────────────────────────────────────────────────────────

class ForumPostDetailPage extends StatefulWidget {
  final String postId;

  const ForumPostDetailPage({super.key, required this.postId});

  @override
  State<ForumPostDetailPage> createState() => _ForumPostDetailPageState();
}

class _ForumPostDetailPageState extends State<ForumPostDetailPage> {
  Map<String, dynamic>? _post;
  Map<String, dynamic>? _author;
  List<Map<String, dynamic>> _comments = [];
  String? _userReaction;
  int _likeCount = 0;
  int _dislikeCount = 0;
  bool _isLoading = true;
  bool _isPostingComment = false;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    final userId = supabase.auth.currentUser?.id;

    try {
      final post = await supabase
          .from('forum_posts_with_counts')
          .select()
          .eq('id', widget.postId)
          .single();

      final author = await supabase
          .from('profiles')
          .select('id, username, avatar_url, role')
          .eq('id', post['author_id'])
          .single();

      final comments = await supabase
          .from('post_comments')
          .select('id, content, created_at, author_id, profiles!post_comments_author_id_fkey(username, avatar_url)')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      String? userReaction;
      if (userId != null) {
        final reaction = await supabase
            .from('post_reactions')
            .select('reaction')
            .eq('user_id', userId)
            .eq('post_id', widget.postId)
            .maybeSingle();
        userReaction = reaction?['reaction'];
      }

      if (!mounted) return;
      setState(() {
        _post = post;
        _author = author;
        _comments = List<Map<String, dynamic>>.from(comments);
        _userReaction = userReaction;
        _likeCount = post['like_count'] ?? 0;
        _dislikeCount = post['dislike_count'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _react(String reaction) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (_userReaction == reaction) {
        await supabase
            .from('post_reactions')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', widget.postId);

        setState(() {
          if (reaction == 'like') _likeCount--;
          if (reaction == 'dislike') _dislikeCount--;
          _userReaction = null;
        });
      } else {
        await supabase.from('post_reactions').upsert({
          'user_id': userId,
          'post_id': widget.postId,
          'reaction': reaction,
        });

        setState(() {
          if (_userReaction == 'like') _likeCount--;
          if (_userReaction == 'dislike') _dislikeCount--;
          if (reaction == 'like') _likeCount++;
          if (reaction == 'dislike') _dislikeCount++;
          _userReaction = reaction;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isPostingComment = true);
    try {
      await supabase.from('post_comments').insert({
        'post_id': widget.postId,
        'author_id': userId,
        'content': text,
      });
      _commentCtrl.clear();
      await _loadPost();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to comment: $e'),
            backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await supabase.from('post_comments').delete().eq('id', commentId);
      await _loadPost();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6B4226))),
      );
    }

    if (_post == null) {
      return const Scaffold(
        body: Center(child: Text('Post not found')),
      );
    }

    final currentUserId = supabase.auth.currentUser?.id;
    final tag = _post!['tag'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text('Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Post ──
                Container(
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
                      // Author
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfilePage(
                                    userId: _post!['author_id']),
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.brown.shade200,
                              backgroundImage: _author?['avatar_url'] != null
                                  ? NetworkImage(_author!['avatar_url'])
                                  : null,
                              child: _author?['avatar_url'] == null
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfilePage(
                                      userId: _post!['author_id']),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _author?['username'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    (_author?['role'] ?? 'reader')
                                        .toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.brown.shade400),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(tag,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.brown.shade700)),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _post!['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _post!['body'] ?? '',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.brown.shade800,
                            height: 1.6),
                      ),

                      const SizedBox(height: 16),

                      // Reactions
                      Row(
                        children: [
                          _reactionButton(
                            icon: Icons.thumb_up_outlined,
                            activeIcon: Icons.thumb_up,
                            count: _likeCount,
                            isActive: _userReaction == 'like',
                            activeColor: const Color(0xFF6B4226),
                            onTap: () => _react('like'),
                          ),
                          const SizedBox(width: 16),
                          _reactionButton(
                            icon: Icons.thumb_down_outlined,
                            activeIcon: Icons.thumb_down,
                            count: _dislikeCount,
                            isActive: _userReaction == 'dislike',
                            activeColor: Colors.redAccent,
                            onTap: () => _react('dislike'),
                          ),
                          const Spacer(),
                          Icon(Icons.comment_outlined,
                              size: 16, color: Colors.brown.shade400),
                          const SizedBox(width: 4),
                          Text('${_comments.length} comments',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.brown.shade400)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Comments (${_comments.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 12),

                if (_comments.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No comments yet — start the conversation!',
                        style: TextStyle(color: Colors.brown.shade300),
                      ),
                    ),
                  )
                else
                  ..._comments.map((comment) {
                    final commentProfile =
                        comment['profiles'] as Map<String, dynamic>?;
                    final isMyComment =
                        comment['author_id'] == currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfilePage(
                                    userId: comment['author_id']),
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.brown.shade200,
                              backgroundImage:
                                  commentProfile?['avatar_url'] != null
                                      ? NetworkImage(
                                          commentProfile!['avatar_url'])
                                      : null,
                              child: commentProfile?['avatar_url'] == null
                                  ? const Icon(Icons.person,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      commentProfile?['username'] ??
                                          'Unknown',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    const Spacer(),
                                    if (isMyComment)
                                      GestureDetector(
                                        onTap: () => _deleteComment(
                                            comment['id']),
                                        child: Icon(Icons.delete_outline,
                                            size: 16,
                                            color: Colors.brown.shade300),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['content'] ?? '',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.brown.shade800,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Comment input ──
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _postComment(),
                  ),
                ),
                const SizedBox(width: 8),
                _isPostingComment
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF6B4226)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send,
                            color: Color(0xFF6B4226)),
                        onPressed: _postComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactionButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 20,
            color: isActive ? activeColor : Colors.brown.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? activeColor : Colors.brown.shade400,
            ),
          ),
        ],
      ),
    );
  }
}