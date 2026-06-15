import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
  
  // Settings & Downloads
  bool _isHighQuality = false;
  String _downloadPath = '';
  List<Song> _downloadedSongs = [];
  Map<String, double> _downloadProgress = {};
  Map<String, Song> _activeDownloads = {};
  Map<String, bool> _cancelFlags = {};

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
  bool get isHighQuality => _isHighQuality;
  String get downloadPath => _downloadPath;
  List<Song> get downloadedSongs => _downloadedSongs;
  Map<String, double> get downloadProgress => _downloadProgress;
  Map<String, Song> get activeDownloads => _activeDownloads;

  Stream<PositionData> get positionDataStream =>
      Rx.merge([
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
      ]).map((_) => PositionData(
          _player.position,
          _player.bufferedPosition,
          _player.duration ?? _duration));

  AudioProvider() {
    _initStreams();
    _loadFavorites();
    _loadPlaylists();
    _loadRecentSearchedSongs();
    _loadSettings();
    _loadDownloadedSongs();
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

    // Listen to index changes to detect Next/Prev button clicks from background notification
    _player.currentIndexStream.listen((index) {
      if (index != null && _queue.isNotEmpty && index != _currentIndex && !_isLoading) {
        if (index >= 0 && index < _queue.length) {
          // Pause immediately to prevent PlayerException from dummy URLs
          _player.pause();
          playSong(_queue[index], contextQueue: _queue);
        }
      }
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

  // Load and save settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isHighQuality = prefs.getBool('isHighQuality') ?? false;
      _downloadPath = prefs.getString('downloadPath') ?? '';
      
      if (_downloadPath.isEmpty) {
        // Fallback to external storage Documents or Music folder
        if (Platform.isAndroid) {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            _downloadPath = '${extDir.path}/Public Beat';
          }
        } else {
          final docDir = await getApplicationDocumentsDirectory();
          _downloadPath = '${docDir.path}/Public Beat';
        }
      }
      
      // Ensure directory exists
      if (_downloadPath.isNotEmpty) {
        final dir = Directory(_downloadPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> setHighQuality(bool value) async {
    _isHighQuality = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isHighQuality', value);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> setDownloadPath(String path) async {
    _downloadPath = path;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('downloadPath', path);
    } catch (e) {
      print('Error saving download path: $e');
    }
  }

  // Load and Save Downloaded Songs
  Future<void> _loadDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('downloaded_songs');
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        _downloadedSongs = jsonList.map((json) => Song.fromJson(json)).toList();
        
        // Verify files still exist
        _downloadedSongs.removeWhere((song) {
          if (song.localPath != null) {
            return !File(song.localPath!).existsSync();
          }
          return true;
        });
        
        notifyListeners();
      }
    } catch (e) {
      print('Error loading downloaded songs: $e');
    }
  }

  Future<void> _saveDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = json.encode(_downloadedSongs.map((e) => e.toJson()).toList());
      await prefs.setString('downloaded_songs', data);
    } catch (e) {
      print('Error saving downloaded songs: $e');
    }
  }

  Future<void> startDownload(Song song) async {
    if (_downloadedSongs.any((s) => s.id == song.id)) return;
    if (_downloadProgress.containsKey(song.id)) return;
    
    _downloadProgress[song.id] = 0.0;
    _activeDownloads[song.id] = song;
    notifyListeners();
    
    try {
      // Ensure directory exists
      final dir = Directory(_downloadPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Sanitize title for filename
      final sanitizedTitle = song.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
      final fileName = '$sanitizedTitle - ${song.artist}.mp4';
      final savePath = '$_downloadPath/$fileName';
      
      final success = await _ytService.downloadSong(
        song.id, 
        savePath, 
        highQuality: _isHighQuality,
        onProgress: (progress) {
          _downloadProgress[song.id] = progress;
          notifyListeners();
        },
        isCancelled: () => _cancelFlags[song.id] ?? false,
      );
      
      if (_cancelFlags[song.id] == true) {
        // Download was cancelled, clean up already handled in youtube_service
        return;
      }
      
      if (success) {
        song.localPath = savePath;
        _downloadedSongs.add(song);
        await _saveDownloadedSongs();
      } else {
        throw Exception('Download failed inside YoutubeService');
      }
    } catch (e) {
      print('Download error: $e');
      // Remove partially created file if any
      try {
        final sanitizedTitle = song.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
        final fileName = '$sanitizedTitle - ${song.artist}.mp4';
        final file = File('$_downloadPath/$fileName');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    } finally {
      _downloadProgress.remove(song.id);
      _activeDownloads.remove(song.id);
      _cancelFlags.remove(song.id);
      notifyListeners();
    }
  }

  // Cancel an active download
  void cancelDownload(String songId) {
    if (_activeDownloads.containsKey(songId)) {
      _cancelFlags[songId] = true;
      _activeDownloads.remove(songId);
      _downloadProgress.remove(songId);
      notifyListeners();
    }
  }

  // Delete a downloaded song
  Future<void> deleteDownloadedSong(String songId) async {
    final index = _downloadedSongs.indexWhere((s) => s.id == songId);
    if (index != -1) {
      final song = _downloadedSongs[index];
      if (song.localPath != null) {
        try {
          final file = File(song.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting file: $e');
        }
      }
      _downloadedSongs.removeAt(index);
      await _saveDownloadedSongs();
      notifyListeners();
    }
  }

  // Reorder downloaded songs
  Future<void> reorderDownloadedSongs(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _downloadedSongs.removeAt(oldIndex);
    _downloadedSongs.insert(newIndex, item);
    await _saveDownloadedSongs();
    notifyListeners();
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
    
    // Keep max 5 songs
    if (_recentSearchedSongs.length > 5) {
      _recentSearchedSongs = _recentSearchedSongs.sublist(0, 5);
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

      // Check if song is downloaded
      String playUrl = '';
      bool isLocal = false;
      
      final downloadedMatch = _downloadedSongs.firstWhere(
        (s) => s.id == song.id, 
        orElse: () => song
      );
      
      if (downloadedMatch.localPath != null && File(downloadedMatch.localPath!).existsSync()) {
        playUrl = downloadedMatch.localPath!;
        isLocal = true;
        print('▶ Playing from local file: $playUrl');
      } else {
        // Fetch audio stream URL
        final streamResult = await _ytService.getAudioStreamInfo(
          song.id, 
          highQuality: _isHighQuality,
        );

        if (streamResult == null) {
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        playUrl = streamResult.url;
        song.streamUrl = playUrl;
        print('▶ Audio stream: ${streamResult.codec} @ ${streamResult.bitrateKbps}kbps');
      }

      // Initialize player media with an Android Chrome User-Agent.
      // This prevents YouTube from detecting the internal "ExoPlayer" default agent and returning 403 Forbidden.
      // Create a ConcatenatingAudioSource representing the entire queue
      // This tricks just_audio_background into showing the Next/Prev buttons.
      // We use a dummy URL for all non-current items, and when the user clicks next/prev,
      // our currentIndexStream listener intercepts it and calls playSong to fetch the real URL.
      final playlist = ConcatenatingAudioSource(
        children: _queue.map((s) {
          final isCurrent = s.id == song.id;
          final uri = isCurrent 
              ? (isLocal ? Uri.file(playUrl) : Uri.parse(playUrl)) 
              : Uri.parse('https://example.com/dummy.mp3');
              
          return AudioSource.uri(
            uri,
            headers: (isCurrent && !isLocal) ? {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
            } : {},
            tag: MediaItem(
              id: s.id,
              album: 'PublicBeat',
              title: s.title,
              artist: s.artist,
              artUri: Uri.parse(s.thumbnailUrl),
            ),
          );
        }).toList(),
      );

      await _player.setAudioSource(playlist, initialIndex: _currentIndex, initialPosition: Duration.zero);
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

  Future<void> closePlayer() async {
    await _player.stop();
    _currentSong = null;
    _isPlaying = false;
    notifyListeners();
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

  // Generate dynamic recommendations based on user history
  Future<List<Song>> getRecommendations() async {
    try {
      // Added "official audio" and removed generic "music" to avoid live streamed videos
      // which currently cause a parsing bug in youtube_explode_dart 3.1.0 ("Invalid radix-10 number: Streamed")
      return await _ytService.searchSongs("top 50 global pop hits official audio");
    } catch (e) {
      print('Error fetching recommendations: $e');
      return [];
    }
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
