import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';

// ─────────────────────────────────────────────────────────────
// Admin Applications Tab
// Approve or reject pending role applications
// ─────────────────────────────────────────────────────────────

class AdminApplicationsTab extends StatefulWidget {
  final VoidCallback onRefresh;

  const AdminApplicationsTab({super.key, required this.onRefresh});

  @override
  State<AdminApplicationsTab> createState() => _AdminApplicationsTabState();
}

class _AdminApplicationsTabState extends State<AdminApplicationsTab> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String _filter = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('role_applications')
          .select(
            'id, requested_role, reason, status, created_at, user_id, profiles!role_applications_user_id_fkey(username, avatar_url, role)',
          )
          .eq('status', _filter)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _applications = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApplication(
    String applicationId,
    String userId,
    String requestedRole,
    bool approve,
  ) async {
    final adminId = supabase.auth.currentUser?.id;
    if (adminId == null) return;

    try {
      // Update application status
      await supabase.from('role_applications').update({
        'status': approve ? 'approved' : 'rejected',
        'reviewed_by': adminId,
      }).eq('id', applicationId);

      // If approved, update user role
      if (approve) {
        await supabase.from('profiles').update({
          'role': requestedRole,
          if (requestedRole == 'mentor') 'is_mentor': true,
        }).eq('id', userId);
      }

      _showSnack(
        approve
            ? 'Application approved — role updated!'
            : 'Application rejected',
        isError: !approve,
      );

      widget.onRefresh();
      await _loadApplications();
    } catch (e) {
      _showSnack('Failed: $e', isError: true);
    }
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
        // ── Filter chips ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: ['pending', 'approved', 'rejected'].map((f) {
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f[0].toUpperCase() + f.substring(1)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _filter = f);
                    _loadApplications();
                  },
                  selectedColor: const Color(0xFF6B4226),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.brown.shade800,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.brown.shade100,
                ),
              );
            }).toList(),
          ),
        ),

        // ── List ──
        Expanded(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF6B4226)),
                )
              : _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox,
                              size: 48, color: Colors.brown.shade200),
                          const SizedBox(height: 8),
                          Text(
                            'No $_filter applications',
                            style:
                                TextStyle(color: Colors.brown.shade300),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF6B4226),
                      onRefresh: _loadApplications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _buildApplicationCard(_applications[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final profile = app['profiles'] as Map<String, dynamic>?;
    final status = app['status'] as String;
    final requestedRole = app['requested_role'] as String;

    Color statusColor = Colors.orange.shade600;
    if (status == 'approved') statusColor = Colors.green.shade600;
    if (status == 'rejected') statusColor = Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
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
          // ── User info ──
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.brown.shade200,
                backgroundImage: profile?['avatar_url'] != null
                    ? NetworkImage(profile!['avatar_url'])
                    : null,
                child: profile?['avatar_url'] == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?['username'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Current role: ${profile?['role'] ?? 'reader'}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.brown.shade400),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Requested role ──
          Row(
            children: [
              Icon(Icons.arrow_upward,
                  size: 14, color: Colors.brown.shade400),
              const SizedBox(width: 4),
              Text(
                'Applying for: ',
                style: TextStyle(
                    fontSize: 13, color: Colors.brown.shade500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4226).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  requestedRole.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4226),
                  ),
                ),
              ),
            ],
          ),

          // ── Reason ──
          if ((app['reason'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '"${app['reason']}"',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.brown.shade700,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // ── Action buttons (only for pending) ──
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleApplication(
                      app['id'],
                      app['user_id'],
                      requestedRole,
                      false,
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApplication(
                      app['id'],
                      app['user_id'],
                      requestedRole,
                      true,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}