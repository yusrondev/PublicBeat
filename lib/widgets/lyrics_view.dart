import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lyric_line.dart';
import '../providers/audio_provider.dart';

class LyricsView extends StatefulWidget {
  final List<LyricLine> lyrics;
  final double slideValue;

  const LyricsView({Key? key, required this.lyrics, required this.slideValue}) : super(key: key);

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = -1;
  bool _isUserScrolling = false;
  late List<GlobalKey> _lyricKeys;

  @override
  void initState() {
    super.initState();
    _lyricKeys = List.generate(widget.lyrics.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics != widget.lyrics) {
      _lyricKeys = List.generate(widget.lyrics.length, (_) => GlobalKey());
      _currentIndex = -1;
      
      // Reset scroll posisi ke atas (0) saat lirik berubah (lagu berganti)
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
    
    // If the player was minimized and is now fully maximized, recenter the active lyric line.
    // We trigger it just as the slide animation finishes (slideValue reaches 1.0)
    // or crosses a high threshold.
    if (oldWidget.slideValue < 1.0 && widget.slideValue == 1.0 && _currentIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentLine(_currentIndex);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLine(int index) {
    if (_isUserScrolling || index < 0 || index >= _lyricKeys.length) return;
    
    final key = _lyricKeys[index];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        alignment: 0.5, // Scrolls so the item is exactly in the vertical center
      );
    } else if (_scrollController.hasClients) {
      // The item is not built yet (too far down the lazy list).
      // Let's jump close to it based on an estimated height (e.g. 50 pixels per line).
      final estimatedOffset = index * 50.0;
      
      // Prevent jumping out of max extent
      final maxExtent = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(estimatedOffset > maxExtent ? maxExtent : estimatedOffset);
      
      // Now that we jumped, the item should be built in the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: 0.5,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    return StreamBuilder<PositionData>(
      stream: audioProvider.positionDataStream,
      builder: (context, snapshot) {
        final position = snapshot.data?.position ?? Duration.zero;

        // Find the current lyric index
        int newIndex = widget.lyrics.indexWhere((line) => line.time > position) - 1;
        if (newIndex < -1) {
          newIndex = widget.lyrics.length - 1; // Song finished, stick to last
        } else if (newIndex == -2) {
          newIndex = -1; // Song hasn't reached first line
        }

        if (newIndex != _currentIndex) {
          _currentIndex = newIndex;
          
          if (_currentIndex >= 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentLine(_currentIndex);
            });
          } else {
            // _currentIndex is -1 (hasn't reached first line)
            // Remove highlight and scroll back to top
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
        }

        return GestureDetector(
          onPanDown: (_) => _isUserScrolling = true,
          onPanCancel: () => _isUserScrolling = false,
          onPanEnd: (_) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                _isUserScrolling = false;
                _scrollToCurrentLine(_currentIndex);
              }
            });
          },
          child: ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 0, // Posisi awal mentok di atas
              bottom: MediaQuery.of(context).size.height / 2.5, // Keep large bottom padding for center scrolling
            ),
            children: List.generate(widget.lyrics.length, (index) {
              final lyric = widget.lyrics[index];
              final isActive = index == _currentIndex;

              return GestureDetector(
                onTap: () {
                  // User taps on a lyric line -> seek the audio player to that timestamp
                  audioProvider.seek(lyric.time);
                  
                  // Temporarily disable scrolling block so it snaps to the new lyric
                  _isUserScrolling = false;
                },
                child: Padding(
                  key: _lyricKeys[index],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: isActive ? 28 : 22,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                      shadows: isActive
                          ? [
                              Shadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      lyric.text.isEmpty ? "• • •" : lyric.text,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
