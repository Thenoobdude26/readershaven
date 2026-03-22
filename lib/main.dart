import 'package:flutter/material.dart';
import 'package:readershaven/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile/profilepage.dart';
import 'package:readershaven/core/constants.dart';
import 'homescreenpages/discover_page.dart';
import 'homescreenpages/librarypage.dart';
import 'writers/createStoryPage.dart';
import 'community/communitypage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tghjbeyxclnpsvfyepsy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRnaGpiZXl4Y2xucHN2ZnllcHN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NTgwODAsImV4cCI6MjA4OTMzNDA4MH0.reEecj8BDEYdZJPpL0JYMBRKp2Z5lGKpfBVPPS-Mq4U',
  );
  runApp(const ReadersHaven());
}

final supabase = Supabase.instance.client;

// Global notifier so any widget can toggle dark mode
final darkModeNotifier = ValueNotifier<bool>(false);

class ReadersHaven extends StatelessWidget {
  const ReadersHaven({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (_, isDark, _) => MaterialApp(
        title: "ReadersHaven",
        debugShowCheckedModeBanner: false,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B4226),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Georgia',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B4226),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Georgia',
        ),
        home: const LoginSignupPage(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Genre list
// ─────────────────────────────────────────────────────────────

// const List<String> _genres = [
//   "All",
//   "Fantasy",
//   "Romance",
//   "Sci-Fi",
//   "Mystery",
//   "Drama",
//   "Horror",
//   "Non-Fiction",
// ];

// ─────────────────────────────────────────────────────────────
// Home Page
// ─────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  String _userRole = 'reader';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  List<Widget> get _pages => [
    _HomeContent(onSearch: _onSearch),
    DiscoverPage(initialQuery: _searchQuery),
    const CommunityPage(),
    const LibraryPage(),
    if (_userRole == 'writer' || _userRole == 'mentor') const CreateStoryPage(),
  ];

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _selectedIndex = 1;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // ← just this
  }

  Future<void> _loadUserRole() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    if (!mounted) return;
    setState(() => _userRole = data['role'] ?? 'reader');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _isDarkMode
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFF5EFE6),
      endDrawer: const Drawer(child: ProfilePage()),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              "ReadersHaven",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: "Toggle dark mode",
            onPressed: () {
              setState(() => _isDarkMode = !_isDarkMode);
              darkModeNotifier.value = _isDarkMode;
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: "Notifications",
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: "Profile",
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF6B4226).withOpacity(0.95),
        indicatorColor: Colors.white.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.explore, color: Colors.white),
            label: "Discover",
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.forum, color: Colors.white),
            label: "Community",
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.library_books, color: Colors.white),
            label: "Library",
          ),
          if (_userRole == 'writer' || _userRole == 'mentor')
            const NavigationDestination(
              icon: Icon(Icons.edit_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.edit, color: Colors.white),
              label: "Write",
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home Content Tab
// StatefulWidget so it can load reading progress from Supabase
// ─────────────────────────────────────────────────────────────

class _HomeContent extends StatefulWidget {
  final void Function(String query) onSearch;
  const _HomeContent({required this.onSearch});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  // null = still loading or no data found
  Map<String, dynamic>? _latestProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // maybeSingle() returns null instead of throwing if no rows found
      final data = await supabase
          .from('reading_progress')
          .select('progress, updated_at, stories(title), chapters(title)')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _latestProgress = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onSubmitted: (query) => widget.onSearch(query),
              decoration: InputDecoration(
                hintText: "Search stories, authors, genres…",
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

          const SizedBox(height: 20),

          // ── Genre chips ──
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = genres[i] == "All";
                return ChoiceChip(
                  label: Text(genres[i]),
                  selected: selected,
                  selectedColor: const Color(0xFF6B4226),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.brown.shade800,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.brown.shade100,
                  onSelected: (_) {},
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // ── Continue Reading ──
          // Only shown if the user has actually read something
          if (!_isLoading && _latestProgress != null) ...[
            _SectionHeader(
              title: "Continue Reading",
              actionLabel: "My Library",
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _ContinueReadingCard(
              title:
                  (_latestProgress!['stories']
                      as Map<String, dynamic>?)?['title'] ??
                  'Unknown Story',
              chapter:
                  (_latestProgress!['chapters']
                      as Map<String, dynamic>?)?['title'] ??
                  '',
              progress:
                  (_latestProgress!['progress'] as num?)?.toDouble() ?? 0.0,
              coverColor: const Color(0xFFB5451B),
            ),
            const SizedBox(height: 28),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade900,
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              actionLabel,
              style: const TextStyle(color: Color(0xFF6B4226)),
            ),
          ),
        ],
      ),
    );
  }
}

// author field removed — not stored in reading_progress
// fetch separately if needed when navigating to story
class _ContinueReadingCard extends StatelessWidget {
  final String title;
  final double progress;
  final String chapter;
  final Color coverColor;

  const _ContinueReadingCard({
    required this.title,
    required this.progress,
    required this.chapter,
    required this.coverColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: coverColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_stories,
                color: Colors.white54,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (chapter.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      chapter,
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.brown.shade100,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6B4226)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${(progress * 100).toInt()}% read",
                    style: TextStyle(
                      color: Colors.brown.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4226),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Continue", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Placeholder pages for bottom nav tabs
// ─────────────────────────────────────────────────────────────