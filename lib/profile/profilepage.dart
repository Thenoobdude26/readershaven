import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../auth.dart';
import 'edit_profile_page.dart';

final supabase = Supabase.instance.client;

// ─────────────────────────────────────────────────────────────
// Profile Page — reads & writes to Supabase profiles table
// ─────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile data
  String _username = '';
  String _bio = '';
  String? _avatarUrl;
  String _role = 'reader';
  String _applicationStatus = '';
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  // Edit controllers
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  // Stories & reading progress
  List<Map<String, dynamic>> _publishedStories = [];
  List<Map<String, dynamic>> _readingProgress = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Data fetching ────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Load profile
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Load published stories
      final stories = await supabase
          .from('stories')
          .select('id, title, genre, created_at')
          .eq('author_id', userId)
          .eq('is_published', true)
          .order('created_at', ascending: false);

      // Load reading progress
      final progress = await supabase
          .from('reading_progress')
          .select('progress, stories(title, genre)')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(10);

      //application
      final applications = await supabase
          .from('role_applications')
          .select('status')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .limit(1);

      // Load follower/following counts
      final followers = await supabase
          .from('follows')
          .select('id')
          .eq('following_id', userId)
          .count(CountOption.exact);

      final following = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', userId)
          .count(CountOption.exact);

      if (!mounted) return;
      setState(() {
        _username = profile['username'] ?? '';
        _bio = profile['bio'] ?? '';
        _role = profile['role'] ?? 'reader';
        _avatarUrl = profile['avatar_url'];
        _followerCount = followers.count ?? 0;
        _followingCount = following.count ?? 0;
        _publishedStories = List<Map<String, dynamic>>.from(stories);
        _readingProgress = List<Map<String, dynamic>>.from(progress);
        _usernameCtrl.text = _username;
        _bioCtrl.text = _bio;
        _isLoading = false;
        _applicationStatus = applications.isNotEmpty ? 'pending' : '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Failed to load profile: $e', isError: true);
    }
  }

  // ── Save profile edits ───────────────────────────────────────

  Future<void> _saveProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await supabase
          .from('profiles')
          .update({
            'username': _usernameCtrl.text.trim(),
            'bio': _bioCtrl.text.trim(),
          })
          .eq('id', userId);

      setState(() {
        _username = _usernameCtrl.text.trim();
        _bio = _bioCtrl.text.trim();
      });
      _showSnack('Profile updated!');
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Change password ──────────────────────────────────────────

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text.length < 6) {
      _showSnack('Password must be at least 6 characters', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordCtrl.text),
      );
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _showSnack('Password changed!');
    } on AuthException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Upload avatar ────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      final file = File(picked.path);
      final path = '$userId.jpg';

      await supabase.storage
          .from('avatars')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final url = supabase.storage.from('avatars').getPublicUrl(path);

      await supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', userId);

      setState(() => _avatarUrl = url);
      _showSnack('Avatar updated!');
    } catch (e) {
      _showSnack('Failed to upload avatar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // roles
  Future<void> _applyForRole() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final nextRole = _role == 'reader' ? 'writer' : 'mentor';

    // Show a dialog asking for their reason
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Apply to become a $nextRole'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Why do you want to apply?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase.from('role_applications').insert({
        'user_id': userId,
        'requested_role': nextRole,
        'reason': reasonCtrl.text.trim(),
      });
      setState(() => _applicationStatus = 'pending');
      _showSnack('Application submitted!');
    } catch (e) {
      _showSnack('Failed to submit: $e', isError: true);
    }
  }
  // ── Sign out ─────────────────────────────────────────────────

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginSignupPage()),
      (_) => false,
    );
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

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B4226)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildStats(),
          _buildTabBar(),
          _buildTabContent(),
          const SizedBox(height: 16),
          const SizedBox(height: 32),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Header (avatar + name + bio) ─────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6B4226), Colors.brown.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white24,
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person, size: 48, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD261),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Color(0xFF1A0A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _username.isEmpty ? 'No username set' : _username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Apply button — only show if reader or writer, and no pending application
          if (_role != 'mentor' && _applicationStatus != 'pending')
            TextButton(
              onPressed: _applyForRole,
              child: Text(
                _role == 'reader'
                    ? 'Apply to become a Writer'
                    : 'Apply to become a Mentor',
                style: const TextStyle(color: Color(0xFFFFD261), fontSize: 12),
              ),
            ),

          if (_applicationStatus == 'pending')
            const Text(
              'Application pending review',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          if (_bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _bio,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditProfilePage(username: _username, bio: _bio),
                ),
              );
              _loadProfile(); // refresh data when returning
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          // Sign out button
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, size: 16, color: Colors.white60),
            label: const Text(
              'Sign out',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────

  Widget _buildStats() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(_publishedStories.length.toString(), 'Stories'),
          _divider(),
          _statItem(_followerCount.toString(), 'Followers'),
          _divider(),
          _statItem(_followingCount.toString(), 'Following'),
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

  Widget _divider() =>
      Container(width: 1, height: 32, color: Colors.brown.shade100);

  // ── Tab bar ──────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6B4226),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF6B4226),
        tabs: const [
          Tab(icon: Icon(Icons.auto_stories, size: 20), text: 'Stories'),
          Tab(icon: Icon(Icons.bookmark, size: 20), text: 'Reading'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 280,
      child: TabBarView(
        controller: _tabController,
        children: [_buildStoriesList(), _buildReadingList()],
      ),
    );
  }

  // ── Published stories list ───────────────────────────────────

  Widget _buildStoriesList() {
    if (_publishedStories.isEmpty) {
      return _emptyState(Icons.auto_stories, "No published stories yet");
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _publishedStories.length,
      itemBuilder: (context, i) {
        final s = _publishedStories[i];
        return Container(
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
                        borderRadius: BorderRadius.circular(20),
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
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  // ── Reading progress list ────────────────────────────────────

  Widget _buildReadingList() {
    if (_readingProgress.isEmpty) {
      return _emptyState(Icons.bookmark_border, "Nothing in progress yet");
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _readingProgress.length,
      itemBuilder: (context, i) {
        final item = _readingProgress[i];
        final story = item['stories'] as Map<String, dynamic>?;
        final progress = (item['progress'] as num?)?.toDouble() ?? 0.0;

        return Container(
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
                  color: Colors.brown.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story?['title'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.brown.shade100,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF6B4226),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${(progress * 100).toInt()}% read',
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
        );
      },
    );
  }


  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.brown.shade200),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.brown.shade300, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
