import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../widgets/glassmorphic_panel.dart';

class PlayerScreen extends StatelessWidget {
  final double slideValue;
  final VoidCallback onCollapse;
  final VoidCallback onExpand;

  const PlayerScreen({
    Key? key,
    required this.slideValue,
    required this.onCollapse,
    required this.onExpand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong;

    if (song == null) return const SizedBox.shrink();

    // Opacities for smooth crossfade
    final miniPlayerOpacity = (1.0 - slideValue * 4.5).clamp(0.0, 1.0);
    final fullPlayerOpacity = ((slideValue - 0.18) * 1.3).clamp(0.0, 1.0);

    return Stack(
      children: [
        // 1. DYNAMIC BLURRED ARTWORK BACKGROUND (Full Player)
        if (slideValue > 0.05)
          Positioned.fill(
            child: Opacity(
              opacity: slideValue,
              child: Stack(
                children: [
                  // Raw background image
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(song.thumbnailUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Frosted glass filter over the image
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: Colors.black.withOpacity(0.55 + (slideValue * 0.15)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // If collapsed or opening, show mini player
        if (miniPlayerOpacity > 0)
          Opacity(
            opacity: miniPlayerOpacity,
            child: _buildMiniPlayer(context, audioProvider, song),
          ),

        // If expanded or expanding, show full player
        if (fullPlayerOpacity > 0)
          Opacity(
            opacity: fullPlayerOpacity,
            child: _buildFullPlayer(context, audioProvider, song),
          ),
      ],
    );
  }

  // ==========================================
  // MINI PLAYER WIDGET (Spotify-style persistent)
  // ==========================================
  Widget _buildMiniPlayer(
    BuildContext context,
    AudioProvider audioProvider,
    Song song,
  ) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0x33121212), // Translucent black
        border: const Border(
          bottom: BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
          top: BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: InkWell(
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Small album thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      song.thumbnailUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite Toggle
                  IconButton(
                    icon: Icon(
                      audioProvider.isFavorite(song)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: audioProvider.isFavorite(song) ? Colors.pink : Colors.white70,
                      size: 22,
                    ),
                    onPressed: () => audioProvider.toggleFavorite(song),
                  ),
                  // Play/Pause Action
                  audioProvider.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () {
                            if (audioProvider.isPlaying) {
                              audioProvider.pause();
                            } else {
                              audioProvider.play();
                            }
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FULL PLAYER WIDGET (Apple Music-style details)
  // ==========================================
  Widget _buildFullPlayer(
    BuildContext context,
    AudioProvider audioProvider,
    Song song,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isPlaying = audioProvider.isPlaying;

    return Column(
      children: [
        // Top handle to drag down
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 30),
                  onPressed: onCollapse,
                ),
                const Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 2.0,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    audioProvider.isFavorite(song)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: audioProvider.isFavorite(song) ? Colors.pink : Colors.white70,
                    size: 24,
                  ),
                  onPressed: () => audioProvider.toggleFavorite(song),
                ),
              ],
            ),
          ),
        ),

        // Space before artwork
        SizedBox(height: screenHeight * 0.02),

        // Album Artwork Card with Playback scale micro-animation
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                margin: EdgeInsets.all(isPlaying ? screenHeight * 0.03 : screenHeight * 0.06), // Scales down on small screens
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isPlaying ? 0.45 : 0.2),
                      blurRadius: isPlaying ? 32 : 18,
                      offset: Offset(0, isPlaying ? 16 : 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    song.thumbnailUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.black38,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.pink),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // Text & Progress Seek Bar Column
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Song Title (Large & Bold)
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Artist Name
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 28),

              // Audio Progress Bar
              StreamBuilder<PositionData>(
                stream: audioProvider.positionDataStream,
                builder: (context, snapshot) {
                  final positionData = snapshot.data;
                  return ProgressBar(
                    progress: positionData?.position ?? Duration.zero,
                    buffered: positionData?.bufferedPosition ?? Duration.zero,
                    total: positionData?.duration ?? Duration.zero,
                    progressBarColor: Colors.pinkAccent,
                    baseBarColor: Colors.white12,
                    bufferedBarColor: Colors.white24,
                    thumbColor: Colors.white,
                    thumbRadius: 6.0,
                    thumbGlowRadius: 16.0,
                    timeLabelTextStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    timeLabelPadding: 8.0,
                    onSeek: (duration) {
                      audioProvider.seek(duration);
                    },
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Controls bar (Shuffle, Prev, Play/Pause, Next, Repeat)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle Button
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: audioProvider.isShuffle ? Colors.pinkAccent : Colors.white54,
                  size: 22,
                ),
                onPressed: audioProvider.toggleShuffle,
              ),

              // Previous Button
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                onPressed: audioProvider.skipToPrevious,
              ),

              // Large Play/Pause Button
              GestureDetector(
                onTap: () {
                  if (audioProvider.isPlaying) {
                    audioProvider.pause();
                  } else {
                    audioProvider.play();
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: audioProvider.isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          )
                        : Icon(
                            audioProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 44,
                          ),
                  ),
                ),
              ),

              // Next Button
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                onPressed: audioProvider.skipToNext,
              ),

              // Repeat Button
              IconButton(
                icon: Icon(
                  audioProvider.loopMode == LoopMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  color: audioProvider.loopMode != LoopMode.off
                      ? Colors.pinkAccent
                      : Colors.white54,
                  size: 22,
                ),
                onPressed: audioProvider.toggleRepeat,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Volume control slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.volume_down_rounded, color: Colors.white54, size: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.white70,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: audioProvider.volume,
                    onChanged: (val) {
                      audioProvider.setVolume(val);
                    },
                  ),
                ),
              ),
              const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 16),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SafeArea(top: false, child: const SizedBox(height: 8)),
      ],
    );
  }
}
