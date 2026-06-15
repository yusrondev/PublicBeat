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
    final audioStream = manifest.audioOnly.withHighestBitrate();
    final url = audioStream.url;
    print('Stream URL: $url');
    
    // Test 1: No headers
    print('\n--- Test 1: HTTP GET with No Headers ---');
    try {
      final res = await http.get(url);
      print('Status Code: ${res.statusCode}');
      print('Content Length: ${res.contentLength}');
    } catch (e) {
      print('Error in Test 1: $e');
    }
    
    // Test 2: Standard Browser User-Agent and Referer headers
    print('\n--- Test 2: HTTP GET with Browser Headers ---');
    try {
      final res = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.youtube.com/',
        },
      );
      print('Status Code: ${res.statusCode}');
      print('Content Length: ${res.contentLength}');
    } catch (e) {
      print('Error in Test 2: $e');
    }
  } catch (e, s) {
    print('General Error: $e');
    print(s);
  } finally {
    yt.close();
  }
}
