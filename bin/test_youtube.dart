import 'dart:io';
import 'package:music_player/services/youtube_service.dart';

void main(List<String> args) async {
  final query = args.isNotEmpty ? args.join(' ') : 'indonesia lo fi';
  print('===================================================');
  print('Running YouTube Audio Stream Extraction Test');
  print('Query: "$query"');
  print('===================================================\n');
  
  final service = YoutubeService();
  
  try {
    print('Searching songs...');
    final songs = await service.searchSongs(query);
    
    if (songs.isEmpty) {
      print('[-] Error: No songs found for the query.');
      service.dispose();
      exit(1);
    }
    
    print('[+] Found ${songs.length} results. Displaying top 3:');
    for (int i = 0; i < songs.length && i < 3; i++) {
      final s = songs[i];
      final minutes = s.duration.inMinutes;
      final seconds = (s.duration.inSeconds % 60).toString().padLeft(2, '0');
      print('  $i. [${minutes}:${seconds}] "${s.title}" by "${s.artist}" (ID: ${s.id})');
    }
    
    final selectedSong = songs.first;
    print('\n[+] Extracting highest bitrate audio stream URL for:');
    print('    Title:  ${selectedSong.title}');
    print('    ID:     ${selectedSong.id}');
    print('    Artist: ${selectedSong.artist}');
    
    print('Fetching stream manifest...');
    final streamUrl = await service.getAudioStreamUrl(selectedSong.id);
    
    if (streamUrl != null) {
      print('\n[+] SUCCESS!');
      print('Stream URL matches expected YouTube server URL. First 150 chars:');
      print(streamUrl.substring(0, streamUrl.length > 150 ? 150 : streamUrl.length));
      print('...\n');
      service.dispose();
      exit(0);
    } else {
      print('\n[-] FAILED to retrieve direct audio stream url.');
      service.dispose();
      exit(1);
    }
  } catch (e, stack) {
    print('\n[-] Error during execution: $e');
    print(stack);
    service.dispose();
    exit(1);
  }
}
