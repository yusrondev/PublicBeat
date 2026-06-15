import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  final yt = YoutubeExplode();
  final videoIds = [
    'IWvo2fld3s4', // Sheila On 7 - Dan...
    '8JHw00UE8Xs', // Walau Habis Terang
    'zN3t4j9b3l8', // Dan
  ];
  
  final clients = {
    'safari (WEB)': YoutubeApiClient.safari,
    'androidVr': YoutubeApiClient.androidVr,
    'tv': YoutubeApiClient.tv,
    'mweb': YoutubeApiClient.mweb,
  };
  
  for (var videoId in videoIds) {
    print('\n==================================================');
    print('Testing Video ID: $videoId');
    print('==================================================');
    
    for (var entry in clients.entries) {
      final name = entry.key;
      final client = entry.value;
      
      try {
        final manifest = await yt.videos.streams.getManifest(
          videoId,
          ytClients: [client],
        );
        
        if (manifest.audioOnly.isEmpty) {
          print('  [-] Client $name: No audio streams');
          continue;
        }
        
        final stream = manifest.audioOnly.withHighestBitrate();
        final urlStr = stream.url.toString();
        
        final cMatch = RegExp(r'[?&]c=([^&]+)').firstMatch(urlStr);
        final clientParam = cMatch != null ? cMatch.group(1) : 'unknown';
        
        final res = await http.get(
          stream.url,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.youtube.com/',
          },
        );
        
        print('  [+] Client $name: Success! (c=$clientParam, MIME=${stream.codec.mimeType}, HTTP=${res.statusCode})');
      } catch (e) {
        print('  [-] Client $name: Failed with error: $e');
      }
    }
  }
  
  yt.close();
}
