import 'package:flutter/material.dart';

void main() {
  runApp(const ReaderSHavenApp());
}

class ReaderSHavenApp extends StatelessWidget {
  const ReaderSHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ReaderSHaven",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4226), // warm brown
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
      home: const HomePage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sample data models
// ─────────────────────────────────────────────────────────────

class Story {
  final String title;
  final String author;
  final String genre;
  final String coverColor; // placeholder for cover art
  final double rating;
  final bool isSpotlighted; // ReaderSHaven's random spotlight feature

  const Story({
    required this.title,
    required this.author,
    required this.genre,
    required this.coverColor,
    required this.rating,
    this.isSpotlighted = false,
  });
}

const List<Story> _featuredStories = [
  Story(
    title: "The Ember Throne",
    author: "Lyra Ashwood",
    genre: "Fantasy",
    coverColor: "#B5451B",
    rating: 4.8,
  ),
  Story(
    title: "Circuits & Starlight",
    author: "M. Chen",
    genre: "Sci-Fi",
    coverColor: "#1B4B8A",
    rating: 4.5,
  ),
  Story(
    title: "Letters Never Sent",
    author: "Rosa Vega",
    genre: "Romance",
    coverColor: "#8A1B4B",
    rating: 4.7,
  ),
];

const List<Story> _spotlightStories = [
  Story(
    title: "A Village Forgotten",
    author: "T. Obi",
    genre: "Drama",
    coverColor: "#2E7D32",
    rating: 4.2,
    isSpotlighted: true,
  ),
  Story(
    title: "Salt & Smoke",
    author: "Priya Nair",
    genre: "Mystery",
    coverColor: "#37474F",
    rating: 4.0,
    isSpotlighted: true,
  ),
];

const List<String> _genres = [
  "All",
  "Fantasy",
  "Romance",
  "Sci-Fi",
  "Mystery",
  "Drama",
  "Horror",
  "Non-Fiction",
];

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
  String _selectedGenre = "All";
  bool _isDarkMode = false;

  final List<Widget> _pages = const [
    _HomeContent(),
    _DiscoverPage(),
    _CommunityPage(),
    _ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, size: 22),
            const SizedBox(width: 8),
            const Text(
              "ReaderSHaven",
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
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: "Notifications",
            onPressed: () {},
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
        destinations: const [
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
            icon: Icon(Icons.person_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home Content Tab
// ─────────────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  const _HomeContent();

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
              itemCount: _genres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = _genres[i] == "All";
                return ChoiceChip(
                  label: Text(_genres[i]),
                  selected: selected,
                  selectedColor: const Color(0xFF6B4226),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.brown.shade800,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.brown.shade100,
                  onSelected: (_) {},
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ── Featured Stories ──
          _SectionHeader(title: "Featured", actionLabel: "See all", onTap: () {}),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredStories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) =>
                  _StoryCard(story: _featuredStories[i], isWide: true),
            ),
          ),

          const SizedBox(height: 28),

          // ── Spotlight (random hidden gems) ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.brown.shade700,
                  Colors.brown.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "Hidden Gems Spotlight",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Randomly selected stories deserving more readers",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: _spotlightStories
                      .map((s) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _StoryCard(
                                  story: s, isWide: false, onDark: true),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Continue Reading ──
          _SectionHeader(
              title: "Continue Reading", actionLabel: "My Library", onTap: () {}),
          const SizedBox(height: 12),
          _ContinueReadingCard(
            title: "The Ember Throne",
            author: "Lyra Ashwood",
            progress: 0.62,
            chapter: "Chapter 14: The Breaking Wall",
            coverColor: const Color(0xFFB5451B),
          ),

          const SizedBox(height: 28),

          // ── Quick Actions ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _QuickActionButton(
                  icon: Icons.edit_outlined,
                  label: "Write",
                  color: Colors.deepOrange.shade400,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _QuickActionButton(
                  icon: Icons.handshake_outlined,
                  label: "Commission",
                  color: Colors.teal.shade400,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _QuickActionButton(
                  icon: Icons.school_outlined,
                  label: "Mentorship",
                  color: Colors.indigo.shade400,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _QuickActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: "Chat",
                  color: Colors.pink.shade400,
                  onTap: () {},
                ),
              ],
            ),
          ),

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

class _StoryCard extends StatelessWidget {
  final Story story;
  final bool isWide;
  final bool onDark;

  const _StoryCard({
    required this.story,
    required this.isWide,
    this.onDark = false,
  });

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final double w = isWide ? 150 : double.infinity;
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: isWide ? w : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover placeholder
            Container(
              width: isWide ? w : double.infinity,
              height: isWide ? 180 : 120,
              decoration: BoxDecoration(
                color: _parseColor(story.coverColor),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.auto_stories,
                      color: Colors.white.withOpacity(0.3),
                      size: isWide ? 60 : 40,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            story.rating.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (story.isSpotlighted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.amber, size: 14),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: onDark ? Colors.white : Colors.brown.shade900,
              ),
            ),
            Text(
              story.author,
              style: TextStyle(
                fontSize: 11,
                color: onDark ? Colors.white70 : Colors.brown.shade600,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.brown.shade200.withOpacity(onDark ? 0.3 : 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                story.genre,
                style: TextStyle(
                  fontSize: 10,
                  color: onDark ? Colors.white : Colors.brown.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  final String title;
  final String author;
  final double progress;
  final String chapter;
  final Color coverColor;

  const _ContinueReadingCard({
    required this.title,
    required this.author,
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
            )
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
              child: const Icon(Icons.auto_stories,
                  color: Colors.white54, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(author,
                      style: TextStyle(
                          color: Colors.brown.shade500, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(chapter,
                      style: TextStyle(
                          color: Colors.brown.shade700, fontSize: 12)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.brown.shade100,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6B4226)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text("${(progress * 100).toInt()}% read",
                      style: TextStyle(
                          color: Colors.brown.shade500, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4226),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Continue", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.brown.shade800,
                  fontWeight: FontWeight.w500),
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

class _DiscoverPage extends StatelessWidget {
  const _DiscoverPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore, size: 64, color: Color(0xFF6B4226)),
          SizedBox(height: 12),
          Text("Discover Page",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Browse all genres and new releases",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CommunityPage extends StatelessWidget {
  const _CommunityPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum, size: 64, color: Color(0xFF6B4226)),
          SizedBox(height: 12),
          Text("Community Page",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Chat rooms, forums, and mentorship",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 64, color: Color(0xFF6B4226)),
          SizedBox(height: 12),
          Text("Profile Page",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Your library, commissions, and settings",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}