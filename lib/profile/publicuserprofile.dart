import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';
import 'package:readershaven/reading/storydetailpage.dart';
import 'package:readershaven/DM/chatpage.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _stories = [];
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final currentUserId = supabase.auth.currentUser?.id;

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      final stories = await supabase
          .from('stories')
          .select('id, title, genre, cover_url')
          .eq('author_id', widget.userId)
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final followers = await supabase
          .from('follows')
          .select('id')
          .eq('following_id', widget.userId)
          .count(CountOption.exact);

      final following = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', widget.userId)
          .count(CountOption.exact);

      bool isFollowing = false;
      if (currentUserId != null) {
        final follow = await supabase
            .from('follows')
            .select('id')
            .eq('follower_id', currentUserId)
            .eq('following_id', widget.userId)
            .maybeSingle();
        isFollowing = follow != null;
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stories = List<Map<String, dynamic>>.from(stories);
        _followerCount = followers.count ?? 0;
        _followingCount = following.count ?? 0;
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      if (_isFollowing) {
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', widget.userId);
        setState(() {
          _isFollowing = false;
          _followerCount--;
        });
      } else {
        await supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': widget.userId,
        });
        setState(() {
          _isFollowing = true;
          _followerCount++;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
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

    if (_profile == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final isCurrentUser = supabase.auth.currentUser?.id == widget.userId;
    final avatarUrl = _profile!['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF6B4226),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6B4226), Colors.brown.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white24,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profile!['username'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (_profile!['role'] ?? 'reader').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Stats + actions ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statItem(_stories.length.toString(), 'Stories'),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.brown.shade100,
                          ),
                          _statItem(_followerCount.toString(), 'Followers'),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.brown.shade100,
                          ),
                          _statItem(_followingCount.toString(), 'Following'),
                        ],
                      ),
                      if (!isCurrentUser) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? Colors.grey.shade200
                                    : const Color(0xFF6B4226),
                                foregroundColor: _isFollowing
                                    ? Colors.brown.shade700
                                    : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                _isFollowing ? 'Following' : 'Follow',
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DmChatPage(
                                    otherUserId: widget.userId,
                                    otherUsername: _profile!['username'] ?? '',
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.message_outlined,
                                size: 16,
                              ),
                              label: const Text('Message'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B4226),
                                side: const BorderSide(
                                  color: Color(0xFF6B4226),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Bio ──
                if ((_profile!['bio'] ?? '').isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _profile!['bio'],
                      style: TextStyle(
                        color: Colors.brown.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── Published stories ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stories (${_stories.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_stories.isEmpty)
                        Center(
                          child: Text(
                            'No published stories yet',
                            style: TextStyle(color: Colors.brown.shade300),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _stories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final s = _stories[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StoryDetailPage(storyId: s['id']),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.brown.shade100,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.brown.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                        image: s['cover_url'] != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  s['cover_url'],
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: s['cover_url'] == null
                                          ? const Icon(
                                              Icons.auto_stories,
                                              color: Colors.white,
                                              size: 22,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.brown.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              s['genre'] ?? '',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.brown.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4226),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.brown.shade400),
        ),
      ],
    );
  }
}
