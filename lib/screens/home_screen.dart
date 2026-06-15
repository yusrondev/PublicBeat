import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../widgets/glassmorphic_panel.dart';
import '../widgets/track_tile.dart';

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

  final List<Map<String, dynamic>> _quickGenres = [
    {'title': 'Lofi Study', 'query': 'lofi study beats', 'icon': Icons.book, 'color': Colors.indigo},
    {'title': 'Chill Acoustic', 'query': 'acoustic covers chill', 'icon': Icons.music_note, 'color': Colors.teal},
    {'title': 'Gaming Synth', 'query': 'synthwave gaming beats', 'icon': Icons.gamepad, 'color': Colors.deepPurple},
    {'title': 'Morning Piano', 'query': 'relaxing piano morning', 'icon': Icons.wb_sunny, 'color': Colors.amber},
    {'title': 'Rainy Day Jazz', 'query': 'coffee shop jazz rain', 'icon': Icons.beach_access, 'color': Colors.brown},
    {'title': 'Workout Gym', 'query': 'workout music gym playlist', 'icon': Icons.fitness_center, 'color': Colors.redAccent},
  ];

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
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
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
                    const Icon(Icons.history, color: Colors.white70),
                  ],
                ),
              ),

              // Quick Access Grid (Spotify style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quickGenres.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.7,
                  ),
                  itemBuilder: (context, index) {
                    final item = _quickGenres[index];
                    return GestureDetector(
                      onTap: () async {
                        // Switch to search tab and execute search
                        widget.changeTab(1); // 1 is Search tab
                        audioProvider.search(item['query']);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x0FFFFFFF)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: double.infinity,
                              color: item['color'],
                              child: Icon(item['icon'], color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

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
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pure Glassmorphic Audio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Stream music freely without limits, account logins, or advertisements.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.pink,
                        child: Icon(Icons.play_arrow, size: 40, color: Colors.white),
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
                  'Recommended For You',
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
                      'No recommendations yet.\nTry searching in the Search tab to play music.',
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
