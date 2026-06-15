import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/glassmorphic_panel.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final favSongs = audioProvider.favorites;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'My Library',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Favorites summary banner card
            if (favSongs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassmorphicPanel(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.pink, Colors.purpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Liked Songs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${favSongs.length} track${favSongs.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Floating Glass Play button
                      GestureDetector(
                        onTap: () {
                          if (favSongs.isNotEmpty) {
                            audioProvider.playSong(favSongs.first, contextQueue: favSongs);
                          }
                        },
                        child: const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.pink,
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Library List Content
            Expanded(
              child: favSongs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: favSongs.length,
                      itemBuilder: (context, index) {
                        final song = favSongs[index];
                        return TrackTile(
                          song: song,
                          contextQueue: favSongs,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x0FFFFFFF), width: 1.5),
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 50,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Library is Empty',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tap the heart icon next to any song in Search or Home to add it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
