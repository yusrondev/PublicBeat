import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/track_tile.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final favSongs = audioProvider.favorites;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14), // Pure dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Liked Songs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: favSongs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120, top: 16),
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
            'No Liked Songs',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Songs you like will appear here.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
