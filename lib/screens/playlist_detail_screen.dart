import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/track_tile.dart';
import 'player_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({Key? key, required this.playlistId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final playlistIndex = audioProvider.playlists.indexWhere((p) => p.id == playlistId);

    if (playlistIndex == -1) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F14),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Playlist not found', style: TextStyle(color: Colors.white))),
      );
    }

    final playlist = audioProvider.playlists[playlistIndex];
    final songs = playlist.songs;
    final hasImage = songs.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1D1B26),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                playlist.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      songs.first.thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: const Color(0xFF2A2A35)),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.5)),
                  ),
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A35),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
                        ],
                        image: hasImage
                            ? DecorationImage(
                                image: NetworkImage(songs.first.thumbnailUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !hasImage
                          ? const Icon(Icons.music_note, color: Colors.white24, size: 60)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E28),
                      title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
                      content: const Text('Are you sure you want to delete this playlist?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                        TextButton(
                          onPressed: () {
                            audioProvider.deletePlaylist(playlistId);
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${songs.length} track${songs.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (songs.isNotEmpty)
                    Builder(builder: (context) {
                      final isPlaylistPlaying = audioProvider.isPlaying &&
                          audioProvider.currentSong != null &&
                          songs.any((s) => s.id == audioProvider.currentSong!.id);
                      return GestureDetector(
                        onTap: () {
                          if (isPlaylistPlaying) {
                            audioProvider.pause();
                          } else {
                            if (audioProvider.currentSong != null &&
                                songs.any((s) => s.id == audioProvider.currentSong!.id)) {
                              audioProvider.play();
                            } else {
                              audioProvider.playSong(songs.first, contextQueue: songs);
                            }
                          }
                        },
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.pink,
                          child: Icon(
                            isPlaylistPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          if (songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.library_music_outlined, size: 50, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'No tracks yet',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverReorderableList(
              itemBuilder: (context, index) {
                final song = songs[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(song.id),
                  index: index,
                  child: Material(
                    color: Colors.transparent,
                    child: TrackTile(
                      song: song,
                      contextQueue: songs,
                      playlistId: playlistId, // Pass this to allow removal
                    ),
                  ),
                );
              },
              itemCount: songs.length,
              onReorder: (oldIndex, newIndex) {
                audioProvider.reorderPlaylistSongs(playlistId, oldIndex, newIndex);
              },
            ),
        ],
      ),
    );
  }
}
