import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    final related = await yt.videos.getRelatedVideos(VideoId('dQw4w9WgXcQ'));
    if (related != null) {
      print('Related count: ${related?.length ?? 0}');
    } else {
      print('Related is null');
    }
  } catch (e) {
    print('Error: $e');
  }
  yt.close();
}
