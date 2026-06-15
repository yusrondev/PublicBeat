import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'IWvo2fld3s4'; // Sheila On 7 - Dan...
  
  try {
    print('Fetching manifest using YoutubeApiClient.ios...');
    final manifest = await yt.videos.streams.getManifest(
      videoId,
      ytClients: [YoutubeApiClient.ios],
    );
    
    print('\nAll audio streams found for ios client:');
    for (var i = 0; i < manifest.audioOnly.length; i++) {
      final s = manifest.audioOnly.elementAt(i);
      print('Stream $i: Container: ${s.container.name}, Codec: ${s.audioCodec}, Bitrate: ${s.bitrate}, MIME: ${s.codec.mimeType}');
      
      // Test HTTP GET
      final res = await http.get(
        s.url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.youtube.com/',
        },
      );
      print('  -> Status Code: ${res.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
