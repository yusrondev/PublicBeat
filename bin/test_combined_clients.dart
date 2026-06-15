import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'IWvo2fld3s4'; // Sheila On 7 - Dan...
  
  try {
    print('Fetching manifest with combined clients (safari, mweb, tv)...');
    final manifest = await yt.videos.streams.getManifest(
      videoId,
      ytClients: [
        YoutubeApiClient.safari,
        YoutubeApiClient.mweb,
        YoutubeApiClient.tv,
      ],
    );
    
    print('\nAll audio streams found:');
    for (var i = 0; i < manifest.audioOnly.length; i++) {
      final s = manifest.audioOnly.elementAt(i);
      final urlStr = s.url.toString();
      final cMatch = RegExp(r'[?&]c=([^&]+)').firstMatch(urlStr);
      final clientParam = cMatch != null ? cMatch.group(1) : 'unknown';
      print('Stream $i: Container: ${s.container.name}, Bitrate: ${s.bitrate}, MIME: ${s.codec.mimeType}, Client: c=$clientParam');
    }
    
    final bestAudio = manifest.audioOnly.withHighestBitrate();
    print('\nSelected best audio stream: Bitrate: ${bestAudio.bitrate}, MIME: ${bestAudio.codec.mimeType}');
    
    final res = await http.get(
      bestAudio.url,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.youtube.com/',
      },
    );
    print('Testing HTTP GET for best stream -> Status Code: ${res.statusCode}');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
