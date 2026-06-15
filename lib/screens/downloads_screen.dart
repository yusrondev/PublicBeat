import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/track_tile.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    
    // Combine active downloads and completed downloads
    final activeSongs = audioProvider.activeDownloads.values.toList();
    final downloadedSongs = audioProvider.downloadedSongs;
    final allSongs = [...activeSongs, ...downloadedSongs];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Downloads',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: allSongs.isEmpty
          ? const Center(
              child: Text(
                'Belum ada lagu yang diunduh.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ReorderableListView.builder(
              physics: const BouncingScrollPhysics(),
              header: activeSongs.isEmpty 
                  ? null 
                  : Column(
                      children: activeSongs.map((song) => TrackTile(
                        key: ValueKey('active_${song.id}'),
                        song: song,
                        contextQueue: downloadedSongs,
                        isFromDownloads: true,
                      )).toList(),
                    ),
              itemCount: downloadedSongs.length,
              onReorder: (oldIndex, newIndex) {
                audioProvider.reorderDownloadedSongs(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final song = downloadedSongs[index];
                return TrackTile(
                  key: ValueKey(song.id),
                  song: song,
                  contextQueue: downloadedSongs,
                  isFromDownloads: true,
                );
              },
            ),
    );
  }
}
