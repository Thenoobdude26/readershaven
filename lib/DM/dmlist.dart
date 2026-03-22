import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';
import 'chatpage.dart';

// ─────────────────────────────────────────────────────────────
// DM List Page
// Shows all direct message conversations
// ─────────────────────────────────────────────────────────────

class DmListPage extends StatefulWidget {
  const DmListPage({super.key});

  @override
  State<DmListPage> createState() => _DmListPageState();
}

class _DmListPageState extends State<DmListPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get all unique users the current user has DMs with
      final sent = await supabase
          .from('direct_messages')
          .select(
            'receiver_id, profiles!direct_messages_receiver_id_fkey(id, username, avatar_url)',
          )
          .eq('sender_id', userId)
          .order('created_at', ascending: false);

      final received = await supabase
          .from('direct_messages')
          .select(
            'sender_id, profiles!direct_messages_sender_id_fkey(id, username, avatar_url)',
          )
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);

      // Deduplicate conversations by user id
      final Map<String, Map<String, dynamic>> convMap = {};

      for (final msg in sent) {
        final profile = msg['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          convMap[profile['id']] = profile;
        }
      }

      for (final msg in received) {
        final profile = msg['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          convMap[profile['id']] = profile;
        }
      }

      if (!mounted) return;
      setState(() {
        _conversations = convMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B4226)),
            )
          : _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 48,
                    color: Colors.brown.shade200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.brown.shade300),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start a conversation from someone\'s profile',
                    style: TextStyle(
                      color: Colors.brown.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final user = _conversations[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DmChatPage(
                        otherUserId: user['id'],
                        otherUsername: user['username'] ?? 'Unknown',
                      ),
                    ),
                  ),
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
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
                          child: Text(
                            user['username'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
