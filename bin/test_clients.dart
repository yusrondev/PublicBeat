import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'IWvo2fld3s4'; // Sheila On 7 - Dan...
  
  final clientsToTest = {
    'ios': YoutubeApiClient.ios,
    'androidVr': YoutubeApiClient.androidVr,
    'androidMusic': YoutubeApiClient.androidMusic,
    'safari': YoutubeApiClient.safari,
    'tv': YoutubeApiClient.tv,
    'mweb': YoutubeApiClient.mweb,
  };
  
  for (var entry in clientsToTest.entries) {
    final name = entry.key;
    final client = entry.value;
    print('\n========================================');
    print('Testing Client: $name');
    print('========================================');
    
    try {
      final manifest = await yt.videos.streams.getManifest(
        videoId,
        ytClients: [client],
      );
      
      if (manifest.audioOnly.isEmpty) {
        print('[-] No audio streams found for client: $name');
        continue;
      }
      
      // Get highest bitrate audio stream
      final stream = manifest.audioOnly.withHighestBitrate();
      print('[+] Resolved stream URL (first 120 chars):');
      final urlStr = stream.url.toString();
      print('    ${urlStr.substring(0, urlStr.length > 120 ? 120 : urlStr.length)}...');
      
      // Check client parameter
      final cMatch = RegExp(r'[?&]c=([^&]+)').firstMatch(urlStr);
      final clientParam = cMatch != null ? cMatch.group(1) : 'unknown';
      print('[+] Client parameter in URL: c=$clientParam');
      
      // Test HTTP GET
      print('[+] Testing HTTP GET...');
      final res = await http.get(
        stream.url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.youtube.com/',
        },
      );
      print('[+] Status Code: ${res.statusCode}');
      print('[+] Content Length: ${res.contentLength}');
    } catch (e) {
      print('[-] Error for client $name: $e');
    }
  }
  
  yt.close();
}
