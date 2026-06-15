import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/youtube_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer(
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    useProxyForRequestHeaders: false,
  );
  final YoutubeService _ytService = YoutubeService();

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isLoading = false;
  List<Song> _searchResults = [];
  bool _isSearching = false;
  List<Song> _favorites = [];
  List<Playlist> _playlists = [];
  List<Song> _recentSearchedSongs = [];

  // Playback States
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;

  // Getters
  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  double get volume => _player.volume;
  List<Song> get favorites => _favorites;
  List<Playlist> get playlists => _playlists;
  List<Song> get searchResults => _searchResults;
  List<Song> get recentSearchedSongs => _recentSearchedSongs;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  AudioProvider() {
    _initStreams();
    _loadFavorites();
    _loadPlaylists();
    _loadRecentSearchedSongs();
  }

  void _initStreams() {
    // Listen to play/pause and completion status
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompleted();
      }
      notifyListeners();
    });

    // Listen to current elapsed time
    _player.positionStream.listen((pos) {
      _position = pos;
    });

    // Listen to current audio source duration
    _player.durationStream.listen((dur) {
      _duration = dur ?? _currentSong?.duration ?? Duration.zero;
    });

    // Listen to buffer timeline
    _player.bufferedPositionStream.listen((buff) {
      _bufferedPosition = buff;
    });
  }

  // Load favorites from local storage
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList('favorites') ?? [];
      _favorites = favoritesJson
          .map((item) => Song.fromJson(json.decode(item) as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Save favorites list to local storage
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = _favorites
          .map((song) => json.encode(song.toJson()))
          .toList();
      await prefs.setStringList('favorites', favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  bool isFavorite(Song song) {
    return _favorites.any((s) => s.id == song.id);
  }

  void toggleFavorite(Song song) {
    if (isFavorite(song)) {
      _favorites.removeWhere((s) => s.id == song.id);
    } else {
      _favorites.add(song);
    }
    _saveFavorites();
    notifyListeners();
  }

  // Load playlists from local storage
  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getStringList('playlists') ?? [];
      _playlists = playlistsJson
          .map((item) => Playlist.fromJson(json.decode(item) as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading playlists: $e');
    }
  }

  // Save playlists to local storage
  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = _playlists
          .map((playlist) => json.encode(playlist.toJson()))
          .toList();
      await prefs.setStringList('playlists', playlistsJson);
    } catch (e) {
      print('Error saving playlists: $e');
    }
  }

  void createPlaylist(String name) {
    if (name.trim().isEmpty) return;
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      songs: [],
      createdAt: DateTime.now(),
    );
    _playlists.add(newPlaylist);
    _savePlaylists();
    notifyListeners();
  }

  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    _savePlaylists();
    notifyListeners();
  }

  void addSongToPlaylist(String playlistId, Song song) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      // Check if song already exists in the playlist
      if (!_playlists[index].songs.any((s) => s.id == song.id)) {
        _playlists[index].songs.add(song);
        _savePlaylists();
        notifyListeners();
      }
    }
  }

  void removeSongFromPlaylist(String playlistId, String songId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index].songs.removeWhere((s) => s.id == songId);
      _savePlaylists();
      notifyListeners();
    }
  }

  // Load recent searches from local storage
  Future<void> _loadRecentSearchedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getStringList('recent_searches') ?? [];
      _recentSearchedSongs = recentJson
          .map((item) => Song.fromJson(json.decode(item) as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  // Save recent searches to local storage
  Future<void> _saveRecentSearchedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = _recentSearchedSongs
          .map((song) => json.encode(song.toJson()))
          .toList();
      await prefs.setStringList('recent_searches', recentJson);
    } catch (e) {
      print('Error saving recent searches: $e');
    }
  }

  void addRecentSearchedSong(Song song) {
    // Remove if exists to place it at the front
    _recentSearchedSongs.removeWhere((s) => s.id == song.id);
    _recentSearchedSongs.insert(0, song);
    
    // Keep max 4 songs
    if (_recentSearchedSongs.length > 4) {
      _recentSearchedSongs = _recentSearchedSongs.sublist(0, 4);
    }
    
    _saveRecentSearchedSongs();
    notifyListeners();
  }

  void reorderPlaylistSongs(String playlistId, int oldIndex, int newIndex) {
    final pIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (pIndex != -1) {
      final playlist = _playlists[pIndex];
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final song = playlist.songs.removeAt(oldIndex);
      playlist.songs.insert(newIndex, song);
      _savePlaylists();
      
      // If the current queue matches this playlist, update the queue as well
      // This ensures "next song" respects the new order
      if (_queue.length == playlist.songs.length) {
        bool matches = true;
        for (var s in _queue) {
          if (!playlist.songs.any((ps) => ps.id == s.id)) {
            matches = false;
            break;
          }
        }
        if (matches) {
          _queue = List.from(playlist.songs);
          if (_currentSong != null) {
            _currentIndex = _queue.indexWhere((s) => s.id == _currentSong!.id);
          }
        }
      }
      
      notifyListeners();
    }
  }

  // Playback Control Actions
  Future<void> playSong(Song song, {List<Song>? contextQueue}) async {
    if (_currentSong?.id == song.id) {
      // Toggle play/pause if selecting the currently active track
      if (_isPlaying) {
        await pause();
      } else {
        await play();
      }
      return;
    }

    try {
      _isLoading = true;
      _currentSong = song;
      _position = Duration.zero;
      _duration = song.duration;
      _bufferedPosition = Duration.zero;
      notifyListeners();

      // Configure playing queue context
      if (contextQueue != null) {
        _queue = List.from(contextQueue);
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      } else {
        if (!_queue.contains(song)) {
          _queue.add(song);
        }
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      }

      // Fetch audio stream URL
      final streamResult = await _ytService.getAudioStreamInfo(song.id);

      if (streamResult == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final url = streamResult.url;
      song.streamUrl = url;
      print('▶ Audio stream: ${streamResult.codec} @ ${streamResult.bitrateKbps}kbps');

      // Initialize player media with an Android Chrome User-Agent.
      // This prevents YouTube from detecting the internal "ExoPlayer" default agent and returning 403 Forbidden.
      await _player.setUrl(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
        },
      );
      
      _player.play();
      
    } catch (e) {
      print('Error in AudioProvider.playSong: $e');
      _isLoading = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double val) async {
    await _player.setVolume(val.clamp(0.0, 1.0));
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
      _player.setLoopMode(LoopMode.one);
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
      _player.setLoopMode(LoopMode.all);
    } else {
      _loopMode = LoopMode.off;
      _player.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  void skipToNext() {
    if (_queue.isEmpty) return;

    if (_loopMode == LoopMode.one) {
      seek(Duration.zero);
      return;
    }

    if (_isShuffle) {
      final otherIndices = List.generate(_queue.length, (idx) => idx)..remove(_currentIndex);
      if (otherIndices.isNotEmpty) {
        otherIndices.shuffle();
        _currentIndex = otherIndices.first;
      } else {
        _currentIndex = 0;
      }
    } else {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    }

    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      playSong(_queue[_currentIndex]);
    }
  }

  void skipToPrevious() {
    if (_queue.isEmpty) return;

    // Restart the current song if we've played for more than 4 seconds
    if (_position.inSeconds > 4) {
      seek(Duration.zero);
      return;
    }

    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      playSong(_queue[_currentIndex]);
    }
  }

  void _handleSongCompleted() {
    if (_loopMode == LoopMode.one) {
      seek(Duration.zero);
      play();
    } else {
      skipToNext();
    }
  }

  // Active Query Search trigger
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final results = await _ytService.searchSongs(query);
    _searchResults = results;

    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    _ytService.dispose();
    super.dispose();
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
