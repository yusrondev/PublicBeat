import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../widgets/glassmorphic_panel.dart';
import '../widgets/track_tile.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) changeTab; // To switch to Search tab

  const HomeScreen({
    Key? key,
    required this.changeTab,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitializing = true;
  List<Song> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadInitialMusic();
  }

  Future<void> _loadInitialMusic() async {
    try {
      final provider = Provider.of<AudioProvider>(context, listen: false);
      
      final results = await provider.getRecommendations();
      
      if (mounted) {
        setState(() {
          _recommendations = results;
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error loading initial music: $e');
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 17) {
      return 'Selamat Siang';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Promoted / Featured Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassmorphicPanel(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SOROTAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Public Beat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Aplikasi gratis untuk mendengarkan musik sepuasnya tanpa iklan.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/public-beat-logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Quick Listen Section (Lofi / Hits)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Rekomendasi Untukmu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              if (_isInitializing)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                    ),
                  ),
                )
              else if (_recommendations.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Belum ada rekomendasi.\nCoba cari lagu di tab Cari.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recommendations.length > 5 ? 5 : _recommendations.length,
                  itemBuilder: (context, index) {
                    final song = _recommendations[index];
                    return TrackTile(
                      song: song,
                      contextQueue: _recommendations,
                    );
                  },
                ),
              
              const SizedBox(height: 100), // Bottom spacer for persistent miniplayer
            ],
          ),
        ),
      ),
    );
  }
}
