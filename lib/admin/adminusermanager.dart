import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';

// ─────────────────────────────────────────────────────────────
// Admin Users Tab
// View and manage all users — change roles, view details
// ─────────────────────────────────────────────────────────────

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('profiles')
          .select('id, username, avatar_url, role, is_admin, is_mentor, created_at')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _filtered = _users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        return (u['username'] ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _changeRole(String userId, String newRole) async {
    try {
      await supabase.from('profiles').update({
        'role': newRole,
        'is_mentor': newRole == 'mentor',
      }).eq('id', userId);

      _showSnack('Role updated to $newRole');
      await _loadUsers();
    } catch (e) {
      _showSnack('Failed: $e', isError: true);
    }
  }

  void _showRoleDialog(Map<String, dynamic> user) {
    final currentRole = user['role'] ?? 'reader';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Change role for ${user['username'] ?? 'user'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['reader', 'writer', 'mentor'].map((role) {
            return RadioListTile<String>(
              title: Text(role[0].toUpperCase() + role.substring(1)),
              value: role,
              groupValue: currentRole,
              activeColor: const Color(0xFF6B4226),
              onChanged: (val) {
                Navigator.pop(context);
                if (val != null && val != currentRole) {
                  _changeRole(user['id'], val);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'mentor':
        return Colors.purple.shade600;
      case 'writer':
        return Colors.blue.shade600;
      default:
        return Colors.brown.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search users...',
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

        // ── Count ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_filtered.length} users',
                style: TextStyle(
                    fontSize: 12, color: Colors.brown.shade400),
              ),
            ],
          ),
        ),

        // ── List ──
        Expanded(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF6B4226)),
                )
              : RefreshIndicator(
                  color: const Color(0xFF6B4226),
                  onRefresh: _loadUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildUserCard(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'reader';
    final isAdmin = user['is_admin'] == true;
    final currentUserId = supabase.auth.currentUser?.id;
    final isSelf = user['id'] == currentUserId;

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
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.brown.shade200,
            backgroundImage: user['avatar_url'] != null
                ? NetworkImage(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['username'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _roleColor(role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _roleColor(role),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Role change button — don't allow changing own role or other admins
          if (!isSelf && !isAdmin)
            IconButton(
              icon: const Icon(Icons.manage_accounts_outlined),
              color: Colors.brown.shade400,
              tooltip: 'Change role',
              onPressed: () => _showRoleDialog(user),
            ),
        ],
      ),
    );
  }
}