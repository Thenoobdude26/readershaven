import 'package:flutter/material.dart';
import 'package:readershaven/main.dart';
import 'chatroompage.dart';

// ─────────────────────────────────────────────────────────────
// Chatroom List Page
// Lists public and mentorship chatrooms
// ─────────────────────────────────────────────────────────────

class ChatroomListPage extends StatefulWidget {
  const ChatroomListPage({super.key});

  @override
  State<ChatroomListPage> createState() => _ChatroomListPageState();
}

class _ChatroomListPageState extends State<ChatroomListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _publicRooms = [];
  List<Map<String, dynamic>> _mentorshipRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      final data = await supabase
          .from('chatrooms')
          .select()
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _publicRooms = List<Map<String, dynamic>>.from(
          data.where((r) => r['type'] == 'public'),
        );
        _mentorshipRooms = List<Map<String, dynamic>>.from(
          data.where((r) => r['type'] == 'mentorship'),
        );
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
          'Chatrooms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFFFD261),
          tabs: const [
            Tab(text: 'Public'),
            Tab(text: 'Mentorship'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B4226)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRoomList(_publicRooms, Icons.forum),
                _buildRoomList(_mentorshipRooms, Icons.school),
              ],
            ),
    );
  }

  Widget _buildRoomList(List<Map<String, dynamic>> rooms, IconData icon) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.brown.shade200),
            const SizedBox(height: 8),
            Text('No rooms yet',
                style: TextStyle(color: Colors.brown.shade300)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final room = rooms[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatroomPage(
                roomId: room['id'],
                roomName: room['name'] ?? 'Room',
              ),
            ),
          ),
          child: Container(
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
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4226).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      color: const Color(0xFF6B4226), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room['type'] == 'mentorship'
                            ? 'Mentorship room'
                            : 'Public room',
                        style: TextStyle(
                            fontSize: 12, color: Colors.brown.shade400),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}