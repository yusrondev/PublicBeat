import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../screens/player_screen.dart';

class TrackTile extends StatelessWidget {
  final Song song;
  final List<Song> contextQueue;
  final String? playlistId;
  final bool isFromSearch;
  final bool isFromDownloads;

  const TrackTile({
    Key? key,
    required this.song,
    required this.contextQueue,
    this.playlistId,
    this.isFromSearch = false,
    this.isFromDownloads = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final isCurrent = audioProvider.currentSong?.id == song.id;
    final isPlaying = isCurrent && audioProvider.isPlaying;
    final isDownloading = audioProvider.downloadProgress.containsKey(song.id);
    final downloadProgress = audioProvider.downloadProgress[song.id] ?? 0.0;

    void _showPlaylistMenu() {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E28),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (audioProvider.playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No playlists created yet.', style: TextStyle(color: Colors.white54)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: audioProvider.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = audioProvider.playlists[index];
                      return ListTile(
                        leading: const Icon(Icons.queue_music, color: Colors.pinkAccent),
                        title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          audioProvider.addSongToPlaylist(playlist.id, song);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${playlist.name}'),
                              backgroundColor: Colors.pink,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      );
    }

    final minutes = song.duration.inMinutes;
    final seconds = (song.duration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0x1FAD1457) : const Color(0x0AFFFFFF), // Highlight background if current
        borderRadius: BorderRadius.circular(12),
        border: isCurrent 
            ? Border.all(color: const Color(0x40AD1457), width: 1.0)
            : Border.all(color: Colors.transparent, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Opacity(
            opacity: isDownloading ? 0.5 : 1.0,
            child: ListTile(
        onTap: () {
          audioProvider.playSong(song, contextQueue: contextQueue);
          if (isFromSearch) {
            audioProvider.addRecentSearchedSong(song);
          }
          if (playlistId != null || isFromDownloads) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
                  backgroundColor: const Color(0xFF0F0F14),
                  body: PlayerScreen(
                    slideValue: 1.0,
                    onCollapse: () => Navigator.pop(context),
                    onExpand: () {},
                  ),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutQuart;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          }
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            song.thumbnailUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey[900],
                child: const Icon(Icons.music_note, color: Colors.white60),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey[900],
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isCurrent ? Colors.pinkAccent : Colors.white,
          ),
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: isCurrent ? Colors.pinkAccent.withOpacity(0.7) : Colors.white60,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Duration tag
            Text(
              '$minutes:$seconds',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(width: 8),
            // Favorite toggle button
            IconButton(
              icon: Icon(
                audioProvider.isFavorite(song)
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: 20,
                color: audioProvider.isFavorite(song) ? Colors.pink : Colors.white38,
              ),
              onPressed: () {
                audioProvider.toggleFavorite(song);
              },
            ),
            // Options Menu (Add to Playlist / Remove from Playlist)
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.white38),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1E1E28),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (ctx) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.playlist_add, color: Colors.white),
                            title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showPlaylistMenu();
                            },
                          ),
                          if (!audioProvider.downloadedSongs.any((s) => s.id == song.id) && !audioProvider.downloadProgress.containsKey(song.id))
                            ListTile(
                              leading: const Icon(Icons.download, color: Colors.white),
                              title: const Text('Download for Offline', style: TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(ctx);
                                audioProvider.startDownload(song);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Downloading ${song.title}...'),
                                    backgroundColor: Colors.pink,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          if (audioProvider.downloadProgress.containsKey(song.id))
                            ListTile(
                              leading: const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink),
                              ),
                              title: const Text('Cancel Download', style: TextStyle(color: Colors.pink)),
                              onTap: () {
                                Navigator.pop(ctx);
                                audioProvider.cancelDownload(song.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Download cancelled'),
                                    backgroundColor: Colors.redAccent,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          if (audioProvider.downloadedSongs.any((s) => s.id == song.id))
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: const Text('Remove Download', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(ctx);
                                audioProvider.deleteDownloadedSong(song.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${song.title} removed from downloads'),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          if (playlistId != null)
                            ListTile(
                              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              title: const Text('Remove from this Playlist', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                audioProvider.removeSongFromPlaylist(playlistId!, song.id);
                                Navigator.pop(ctx);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
          ),
          if (isDownloading)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: LinearProgressIndicator(
                value: downloadProgress,
                backgroundColor: Colors.transparent,
                color: Colors.pink,
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
}
