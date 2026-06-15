import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';

class TrackTile extends StatelessWidget {
  final Song song;
  final List<Song> contextQueue;

  const TrackTile({
    Key? key,
    required this.song,
    required this.contextQueue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final isCurrent = audioProvider.currentSong?.id == song.id;
    final isPlaying = isCurrent && audioProvider.isPlaying;

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
      child: ListTile(
        onTap: () {
          audioProvider.playSong(song, contextQueue: contextQueue);
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
          ],
        ),
      ),
    );
  }
}
