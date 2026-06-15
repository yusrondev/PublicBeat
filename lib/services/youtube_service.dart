import 'dart:io';
import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

/// Holds the selected audio stream URL and quality metadata.
class AudioStreamResult {
  final String url;
  final String codec;
  final int bitrateKbps;

  const AudioStreamResult({
    required this.url,
    required this.codec,
    required this.bitrateKbps,
  });
}

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  // Search for songs using YouTube Explode
  Future<List<Song>> searchSongs(String query) async {
    try {
      // Append "audio" to the search query if not already present
      // to ensure we get higher quality audio/music video results instead of vlogs.
      final lowerQuery = query.toLowerCase();
      final String searchQuery;
      if (lowerQuery.contains('audio') || 
          lowerQuery.contains('song') || 
          lowerQuery.contains('music') ||
          lowerQuery.contains('official')) {
        searchQuery = query;
      } else {
        // Appending "topic" explicitly targets YouTube's auto-generated official 
        // audio tracks ("Artist - Topic"), guaranteeing no music video intros/outros.
        searchQuery = '$query topic';
      }

      final searchList = await _yt.search.search(searchQuery);
      final List<Song> songs = [];

      for (final video in searchList) {
        // Exclude live streams, videos without duration, and extremely long compilation videos (>15 mins)
        if (video.duration != null && 
            video.duration!.inMinutes > 0 && 
            video.duration!.inMinutes < 15) {
          
          final cleanTitle = _cleanTitle(video.title);
          
          songs.add(Song(
            id: video.id.value,
            title: cleanTitle,
            artist: _cleanArtist(video.author),
            thumbnailUrl: video.thumbnails.highResUrl,
            duration: video.duration!,
          ));
        }
      }
      return songs;
    } catch (e) {
      print('Error in YoutubeService.searchSongs: $e');
      return [];
    }
  }

  // Retrieve the direct streaming audio URL for a YouTube Video ID
  // Quality strategy:
  //   1. High Quality: Highest resolution muxed stream (best audio bitrate, high data usage)
  //   2. Data Saver: Lowest resolution muxed stream (adequate audio, low data usage)
  Future<AudioStreamResult?> getAudioStreamInfo(String videoId, {bool highQuality = false}) async {
    try {
      final manifest = await _yt.videos.streams.getManifest(videoId);
      
      // YouTube enforces strict 403 Forbidden blocks (via PO Tokens) exclusively on audioOnly streams.
      // By using muxed (video+audio) streams, we permanently bypass these bot protections.
      final muxedStreams = manifest.muxed.toList();
      if (muxedStreams.isEmpty) return null;
      
      // Sort streams by resolution (ascending)
      muxedStreams.sort((a, b) => a.videoResolution.height.compareTo(b.videoResolution.height));
      
      // Select the lowest resolution for Data Saver, or the highest resolution for High Quality
      final stream = highQuality ? muxedStreams.last : muxedStreams.first;
      
      return AudioStreamResult(
        url: stream.url.toString(),
        codec: stream.audioCodec,
        bitrateKbps: stream.bitrate.kiloBitsPerSecond.round(),
      );
    } catch (e) {
      print('Error in YoutubeService.getAudioStreamUrl: $e');
      return null;
    }
  }

  // Download the song to a specific path
  Future<bool> downloadSong(String videoId, String savePath, {
      bool highQuality = false, 
      Function(double)? onProgress,
      bool Function()? isCancelled,
  }) async {
    try {
      final manifest = await _yt.videos.streams.getManifest(videoId).timeout(const Duration(seconds: 15));
      
      StreamInfo streamInfo;
      final muxedStreams = manifest.muxed.toList();
      
      if (muxedStreams.isNotEmpty) {
        // Sort muxed streams by resolution ascending
        muxedStreams.sort((a, b) => a.videoResolution.height.compareTo(b.videoResolution.height));
        streamInfo = highQuality ? muxedStreams.last : muxedStreams.first;
      } else {
        // Fallback to audio only
        final audioStreams = manifest.audioOnly.toList();
        if (audioStreams.isEmpty) return false;
        streamInfo = highQuality ? audioStreams.withHighestBitrate() : audioStreams.first;
      }
      
      var stream = _yt.videos.streamsClient.get(streamInfo);
      var file = File(savePath);
      var fileStream = file.openWrite();
      
      var totalSize = streamInfo.size.totalBytes;
      int downloaded = 0;
      int lastDataTime = DateTime.now().millisecondsSinceEpoch;
      
      final completer = Completer<bool>();
      StreamSubscription? subscription;
      Timer? progressTimer;

      progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        // Handle explicit cancellation
        if (isCancelled != null && isCancelled()) {
          timer.cancel();
          subscription?.cancel();
          await fileStream.flush();
          await fileStream.close();
          if (await file.exists()) {
            await file.delete();
          }
          if (!completer.isCompleted) completer.complete(false);
          return;
        }
        
        // Handle stream timeout (15 seconds without data)
        if (DateTime.now().millisecondsSinceEpoch - lastDataTime > 15000) {
          timer.cancel();
          subscription?.cancel();
          await fileStream.flush();
          await fileStream.close();
          if (!completer.isCompleted) completer.completeError(Exception('Download stream timed out'));
        }
      });

      subscription = stream.listen(
        (data) {
          lastDataTime = DateTime.now().millisecondsSinceEpoch;
          fileStream.add(data);
          downloaded += data.length;
          if (onProgress != null && totalSize > 0) {
            onProgress(downloaded / totalSize);
          }
        },
        onError: (e) {
          progressTimer?.cancel();
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () async {
          progressTimer?.cancel();
          await fileStream.flush();
          await fileStream.close();
          if (!completer.isCompleted) completer.complete(true);
        },
        cancelOnError: true,
      );

      return await completer.future;
    } catch (e) {
      print('Error in YoutubeService.downloadSong: $e');
      return false;
    }
  }

  // Cleans the YouTube video title to resemble a music library track
  String _cleanTitle(String title) {
    // 1. Remove bracket expressions e.g. [Official Music Video], (Lyrics Video), etc.
    String cleaned = title
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\([^\)]*\)'), '');

    // 2. Remove standard marketing tags
    cleaned = cleaned.replaceAll(
        RegExp(r'(official\s+(music\s+)?video|music\s+video|lyric(\s+video)?|audio|hd|4k|mv|official\s+audio|prod\s+by\s+.*|visualizer)', 
        caseSensitive: false), 
        ''
    );

    // 3. Handle Title split (Artist - Title) if present
    if (cleaned.contains('-')) {
      final parts = cleaned.split('-');
      // Take the second part as title and clean it
      cleaned = parts.length > 1 ? parts[1] : parts[0];
    }

    // 4. Remove trailing/leading junk characters and excessive spaces
    cleaned = cleaned
        .replaceAll(RegExp(r'^\s*[-|:|•|~]\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.isNotEmpty ? cleaned : title;
  }

  // Cleans the channel name to look like a clean artist name
  String _cleanArtist(String author) {
    return author
        .replaceAll(RegExp(r'(VEVO|- Topic|Official|Music|Records|Entertainment|\s+YT)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void dispose() {
    _yt.close();
  }
}
