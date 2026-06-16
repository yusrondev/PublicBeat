import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../widgets/glassmorphic_panel.dart';
import '../widgets/cached_cover_image.dart';
import '../widgets/lyrics_view.dart';
import '../services/lyrics_service.dart';
import '../models/lyric_line.dart';

class PlayerScreen extends StatefulWidget {
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
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  String? _currentVideoUrl;
  
  List<LyricLine>? _lyrics;
  bool _isFetchingLyrics = false;
  String? _lastLyricsSongId;

  @override
  void initState() {
    super.initState();
    _checkVideoInitialization();
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkVideoInitialization();
    
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _checkLyricsInitialization(audioProvider, audioProvider.currentSong);
  }

  void _checkLyricsInitialization(AudioProvider audioProvider, Song? song) {
    if (song != null && audioProvider.enableLyrics && widget.slideValue > 0) {
      if (_lastLyricsSongId != song.id) {
        _lastLyricsSongId = song.id;
        _fetchLyrics(song);
      }
    } else if (widget.slideValue == 0 || !audioProvider.enableLyrics) {
      _lyrics = null;
      _lastLyricsSongId = null;
    }
  }

  Future<void> _fetchLyrics(Song song) async {
    setState(() {
      _isFetchingLyrics = true;
      _lyrics = null;
    });
    
    final lyrics = await LyricsService.fetchLyrics(song.id);
    
    if (mounted && _lastLyricsSongId == song.id) {
      setState(() {
        _lyrics = lyrics;
        _isFetchingLyrics = false;
      });
    }
  }

  void _checkVideoInitialization() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final song = audioProvider.currentSong;
    
    // Only initialize video if the player is at least partially expanded (slideValue > 0)
    // This prevents background PlayerScreens (like the global one when covered by another route)
    // from simultaneously initializing a second heavy VideoPlayerController.
    if (widget.slideValue > 0 && audioProvider.enableVideoCanvas && song != null && song.streamUrl != null) {
      if (_currentVideoUrl != song.streamUrl) {
        _currentVideoUrl = song.streamUrl;
        _initVideoPlayer(song.streamUrl!);
      }
    } else if (widget.slideValue == 0 || !audioProvider.enableVideoCanvas) {
      _disposeVideoPlayer();
    }
  }

  void _initVideoPlayer(String url) {
    _disposeVideoPlayer();
    _currentVideoUrl = url;
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        _videoController?.setVolume(0); // Mute video
        _videoController?.seekTo(Duration.zero); // Start from 0s
        _videoController?.play();
        setState(() {}); // Rebuild after init
      });

    _videoController?.addListener(() {
      if (_videoController != null && _videoController!.value.isInitialized) {
        // Loop between 0 and 10 seconds
        if (_videoController!.value.position.inSeconds >= 10) {
          _videoController?.seekTo(Duration.zero);
        }
      }
    });
  }

  void _disposeVideoPlayer() {
    _videoController?.dispose();
    _videoController = null;
    _currentVideoUrl = null;
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong;

    if (song == null) return const SizedBox.shrink();

    // Initialize or dispose video player dynamically based on state and visibility
    if (widget.slideValue > 0 && audioProvider.enableVideoCanvas && song.streamUrl != null) {
      if (_currentVideoUrl != song.streamUrl) {
        _currentVideoUrl = song.streamUrl;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _initVideoPlayer(song.streamUrl!);
        });
      }
    } else if ((widget.slideValue == 0 || !audioProvider.enableVideoCanvas) && _currentVideoUrl != null) {
      _currentVideoUrl = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _disposeVideoPlayer();
          setState(() {});
        }
      });
    }

    _checkLyricsInitialization(audioProvider, song);

    // Pause or play video based on audio state
    if (audioProvider.isPlaying) {
      _videoController?.play();
    } else {
      _videoController?.pause();
    }

    // Opacities for smooth crossfade
    final miniPlayerOpacity = (1.0 - widget.slideValue * 4.5).clamp(0.0, 1.0);
    final fullPlayerOpacity = ((widget.slideValue - 0.18) * 1.3).clamp(0.0, 1.0);

    return Stack(
      children: [
        // 1. DYNAMIC BLURRED ARTWORK BACKGROUND OR VIDEO CANVAS
        if (widget.slideValue > 0.05)
          Positioned.fill(
            child: Opacity(
              opacity: widget.slideValue,
              child: Stack(
                fit: StackFit.expand,
                children: [
                    // Raw background image (fallback or base layer)
                    CachedCoverImage(
                      song: song,
                      fit: BoxFit.cover,
                    ),
                  
                  // Video Canvas Background
                  if (audioProvider.enableVideoCanvas && _videoController != null && _videoController!.value.isInitialized)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  else
                    // Frosted glass filter over the image if no video
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: audioProvider.enableLyrics ? 60 : 30, 
                        sigmaY: audioProvider.enableLyrics ? 60 : 30
                      ),
                      child: Container(
                        color: Colors.black.withOpacity(
                           audioProvider.enableLyrics ? 0.70 : (0.55 + (widget.slideValue * 0.15))
                        ),
                      ),
                    ),

                  // Dramatic Full-Screen Gradient for MV Canvas effect
                  if (audioProvider.enableVideoCanvas && _videoController != null && _videoController!.value.isInitialized) ...[
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.15, 0.4, 0.65, 0.85, 1.0],
                            colors: [
                              const Color(0xFF0F0F14), // Solid dark at the very top
                              const Color(0xFF0F0F14).withOpacity(0.8), // Steep fade
                              const Color(0xFF0F0F14).withOpacity(0.35), // Center has some tint to avoid extreme brightness
                              const Color(0xFF0F0F14).withOpacity(0.85), // Gets darker towards the text
                              const Color(0xFF0F0F14).withOpacity(0.98), // Very dark behind title/controls
                              const Color(0xFF0F0F14), // Solid dark at the bottom
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // If collapsed or opening, show mini player
        if (miniPlayerOpacity > 0)
          Opacity(
            opacity: miniPlayerOpacity,
            child: GestureDetector(
              onTap: widget.onExpand,
              child: _buildMiniPlayer(context, audioProvider, song),
            ),
          ),

        // 3. FULL PLAYER CONTENT
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
            onTap: widget.onExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Small album thumbnail
                  CachedCoverImage(
                    song: song,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(6),
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
                  // Close Action
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                    onPressed: () {
                      audioProvider.closePlayer();
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
  // OPTIONS MENU (Advanced Options)
  // ==========================================
  void _showOptionsMenu(BuildContext context, AudioProvider audioProvider, Song song) {
    void showPlaylistMenu() {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E28),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (audioProvider.playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No playlists created yet.', style: TextStyle(color: Colors.white54)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: audioProvider.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = audioProvider.playlists[index];
                      return ListTile(
                        leading: const Icon(Icons.queue_music, color: Colors.pinkAccent),
                        title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          audioProvider.addSongToPlaylist(playlist.id, song);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${playlist.name}'),
                              backgroundColor: Colors.pink,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E28),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white),
                title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  showPlaylistMenu();
                },
              ),
              if (!audioProvider.downloadedSongs.any((s) => s.id == song.id) && !audioProvider.downloadProgress.containsKey(song.id))
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.white),
                  title: const Text('Download for Offline', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    audioProvider.startDownload(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${song.title}...'),
                        backgroundColor: Colors.pink,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (audioProvider.downloadProgress.containsKey(song.id))
                ListTile(
                  leading: const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink),
                  ),
                  title: const Text('Cancel Download', style: TextStyle(color: Colors.pink)),
                  onTap: () {
                    Navigator.pop(ctx);
                    audioProvider.cancelDownload(song.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download cancelled'),
                        backgroundColor: Colors.redAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (audioProvider.downloadedSongs.any((s) => s.id == song.id))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Download', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    audioProvider.deleteDownloadedSong(song.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${song.title} removed from downloads'),
                        backgroundColor: Colors.redAccent,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
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
                  onPressed: widget.onCollapse,
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
          child: (audioProvider.enableVideoCanvas && _videoController != null && _videoController!.value.isInitialized)
              ? const SizedBox.expand() // Fill empty space so background video is visible
              : audioProvider.enableLyrics
                  ? _buildLyricsSection(widget.slideValue)
                  : Center(
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
                          child: CachedCoverImage(
                            song: song,
                            borderRadius: BorderRadius.circular(24),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
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
                        const SizedBox(height: 12),
                        // Lyrics Toggle
                        GestureDetector(
                          onTap: () => audioProvider.setLyrics(!audioProvider.enableLyrics),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: audioProvider.enableLyrics ? Colors.pinkAccent.withOpacity(0.2) : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: audioProvider.enableLyrics ? Colors.pinkAccent.withOpacity(0.5) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lyrics, 
                                  size: 14, 
                                  color: audioProvider.enableLyrics ? Colors.pinkAccent : Colors.white70
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Lyrics',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: audioProvider.enableLyrics ? Colors.pinkAccent : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showOptionsMenu(context, audioProvider, song),
                    child: const Icon(Icons.more_vert, color: Colors.white70, size: 28),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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


        SafeArea(top: false, child: const SizedBox(height: 8)),
      ],
    );
  }

  Widget _buildLyricsSection(double slideValue) {
    if (_isFetchingLyrics) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );
    }
    
    if (_lyrics == null || _lyrics!.isEmpty) {
      return const Center(
        child: Text(
          "Lirik tidak tersedia",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    
    return LyricsView(lyrics: _lyrics!, slideValue: slideValue);
  }
}
