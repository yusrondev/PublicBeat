import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Searching youtube raw...');
    final searchList = await yt.search.search('indonesia lo fi audio');
    print('Search result count: ${searchList.length}');
    for (var i = 0; i < searchList.length && i < 5; i++) {
      final v = searchList[i];
      print('Video $i:');
      print('  Title: ${v.title}');
      print('  Duration: ${v.duration}');
      print('  ID: ${v.id}');
      print('  Author: ${v.author}');
    }
    
    if (searchList.isNotEmpty) {
      final v = searchList.first;
      print('\nGetting manifest for video ID: ${v.id}');
      final manifest = await yt.videos.streams.getManifest(v.id);
      print('Audio streams: ${manifest.audioOnly.length}');
      if (manifest.audioOnly.isNotEmpty) {
        final audio = manifest.audioOnly.withHighestBitrate();
        print('Audio stream URL: ${audio.url}');
      }
    }
  } catch (e, s) {
    print('Error: $e');
    print(s);
  } finally {
    yt.close();
  }
}
