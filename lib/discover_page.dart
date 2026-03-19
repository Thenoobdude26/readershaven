import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readershaven/main.dart';
import 'package:readershaven/core/constants.dart';
import 'reading/storydetailpage.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<Map<String, dynamic>> _stories = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _selectedGenre = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStories();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  //load and filter

  Future<void> _loadStories() async {
    try {
      final data = await supabase
          .from('stories')
          .select(
            'id, title,description,cover_url,genre,created_at, profiles(username)',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _stories = List<Map<String, dynamic>>.from(data);
        _filtered = _stories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _stories.where((s) {
        final matchesGenre =
            _selectedGenre == 'All' || s['genre'] == _selectedGenre;
        final matchesSearch =
            query.isEmpty ||
            (s['title'] ?? '').toLowerCase().contains(query) ||
            (s['profiles']?['username'] ?? '').toLowerCase().contains(query);
        return matchesGenre && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildGenreChips(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6B4226)),
                )
              : _filtered.isEmpty
              ? const Center(child: Text('No stories found'))
              : _buildGrid(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search stories or authors. . .',
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
    );
  }

  Widget _buildGenreChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = genres[i] == _selectedGenre;
          return ChoiceChip(
            label: Text(genres[i]),
            selected: selected,
            selectedColor: const Color(0xFF6B4226),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.brown.shade800,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.brown.shade100,
            onSelected: (_) {
              setState(() => _selectedGenre = genres[i]);
              _applyFilters();
            },
          );
        },
      ),
    );
  }

  //grid
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, i) => _buildStoryCard(_filtered[i]),
    );
  }

  //storycard
  Widget _buildStoryCard(Map<String, dynamic> story) {
    final coverUrl = story['cover_url'] as String?;
    final author =
        (story['profiles'] as Map<String, dynamic>?)?['username'] ?? 'Unknown';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryDetailPage(storyId: story['id']),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.brown.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.brown.shade500,
                    ),
                  ),
                  if (story['genre'] != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        story['genre'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.brown.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
