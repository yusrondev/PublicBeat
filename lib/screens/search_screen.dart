import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/track_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _browseCategories = [
    {'title': 'Pop Hits', 'query': 'pop hits top charts', 'color': Colors.purpleAccent},
    {'title': 'Indie & Folk', 'query': 'indie folk acoustic', 'color': Colors.deepOrangeAccent},
    {'title': 'Chill Lofi', 'query': 'lofi chill beats', 'color': Colors.indigoAccent},
    {'title': 'Rock Legends', 'query': 'classic rock hits', 'color': Colors.redAccent},
    {'title': 'R&B / Soul', 'query': 'rnb soul groove', 'color': Colors.pinkAccent},
    {'title': 'Dance / EDM', 'query': 'edm dance club music', 'color': Colors.blueAccent},
    {'title': 'Gaming Synth', 'query': 'synthwave cyberpunk gaming', 'color': Colors.tealAccent},
    {'title': 'Classical Study', 'query': 'classical piano studying', 'color': Colors.blueGrey},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String val) {
    if (val.trim().isNotEmpty) {
      Provider.of<AudioProvider>(context, listen: false).search(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Page Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Search',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Premium Cupertino-style Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x1FFFFFFF), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, color: Colors.white60),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onSubmitted: _onSearchSubmitted,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Songs, artists, or genres...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          audioProvider.search('');
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Dynamic Search Result Body
            Expanded(
              child: audioProvider.isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                      ),
                    )
                  : _searchController.text.isEmpty && audioProvider.searchResults.isEmpty
                      ? _buildBrowseCategories(audioProvider)
                      : _buildSearchResults(audioProvider),
            ),
          ],
        ),
      ),
    );
  }

  // Shows default Spotify-style tiles when search input is empty
  Widget _buildBrowseCategories(AudioProvider audioProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text(
              'Browse all categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _browseCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                final category = _browseCategories[index];
                return GestureDetector(
                  onTap: () {
                    _searchController.text = category['title'];
                    _focusNode.unfocus();
                    audioProvider.search(category['query']);
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: category['color'].withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: category['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: -10,
                          right: -10,
                          child: Transform.rotate(
                            angle: 0.4,
                            child: Icon(
                              Icons.music_note,
                              size: 70,
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            category['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 100), // Bottom padding for player overlay
        ],
      ),
    );
  }

  // Shows results if search query returns results
  Widget _buildSearchResults(AudioProvider audioProvider) {
    if (audioProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search terms.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: audioProvider.searchResults.length,
      itemBuilder: (context, index) {
        final song = audioProvider.searchResults[index];
        return TrackTile(
          song: song,
          contextQueue: audioProvider.searchResults,
        );
      },
    );
  }
}
