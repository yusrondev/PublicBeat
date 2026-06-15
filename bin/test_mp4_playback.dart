import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Searching youtube...');
    final searchList = await yt.search.search('Sheila on 7 Dan audio');
    if (searchList.isEmpty) {
      print('No videos found.');
      return;
    }
    
    final video = searchList.first;
    print('Video Title: ${video.title} (ID: ${video.id})');
    
    print('Fetching manifest...');
    final manifest = await yt.videos.streams.getManifest(video.id);
    
    // Get all audio streams
    print('\nAll audio streams found:');
    for (var i = 0; i < manifest.audioOnly.length; i++) {
      final s = manifest.audioOnly.elementAt(i);
      print('Stream $i: Container: ${s.container.name}, Codec: ${s.audioCodec}, Bitrate: ${s.bitrate}, MIME: ${s.codec.mimeType}');
    }
    
    // Filter to audio/mp4 streams
    final mp4Streams = manifest.audioOnly.where((s) => s.codec.mimeType.contains('mp4')).toList();
    if (mp4Streams.isEmpty) {
      print('No mp4 audio streams found!');
      return;
    }
    
    // Sort mp4 streams by bitrate (bps) in ascending order
    mp4Streams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
    final bestMp4Stream = mp4Streams.last;
    
    print('\nSelected best mp4 stream: Bitrate: ${bestMp4Stream.bitrate}, MIME: ${bestMp4Stream.codec.mimeType}');
    print('URL: ${bestMp4Stream.url}');
    
    print('\nTesting HTTP GET with browser headers for mp4 stream...');
    final res = await http.get(
      bestMp4Stream.url,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.youtube.com/',
      },
    );
    print('Status Code: ${res.statusCode}');
    print('Content Length: ${res.contentLength}');
    
  } catch (e, s) {
    print('Error: $e');
    print(s);
  } finally {
    yt.close();
  }
}
