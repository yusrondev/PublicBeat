import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({Key? key}) : super(key: key);

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _slideController;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Screens list
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    // Animation for sliding up the player panel
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _screens = [
      HomeScreen(changeTab: (index) {
        setState(() {
          _currentTab = index;
        });
      }),
      const SearchScreen(),
      const LibraryScreen(),
    ];
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _expandPlayer() {
    _slideController.forward();
  }

  void _collapsePlayer() {
    _slideController.reverse();
  }

  // Handle drag updates on player panel to follow finger
  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight > 0) {
      _slideController.value -= details.primaryDelta! / screenHeight;
    }
  }

  // Snap open/close on drag end based on velocity or drag percentage
  void _handleVerticalDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (_slideController.isAnimating ||
        _slideController.status == AnimationStatus.completed) return;

    final double flingVelocity = details.velocity.pixelsPerSecond.dy / screenHeight;
    
    if (flingVelocity < -2.0) {
      // Fling up
      _slideController.fling(velocity: 1.0);
    } else if (flingVelocity > 2.0) {
      // Fling down
      _slideController.fling(velocity: -1.0);
    } else if (_slideController.value > 0.45) {
      // Dragged past midpoint -> open
      _slideController.forward();
    } else {
      // Dragged less than midpoint -> close
      _slideController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final currentSong = audioProvider.currentSong;
    final screenHeight = MediaQuery.of(context).size.height;
    final double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    const miniPlayerHeight = 72.0;
    
    // Navigation bar height on Android/iOS is typically around 56-64
    final bottomNavBarHeight = kBottomNavigationBarHeight;

    return WillPopScope(
      onWillPop: () async {
        if (_slideController.isAnimating || _slideController.value > 0) {
          _collapsePlayer();
          return false; // Prevent exit, collapse player instead
        }
        if (_currentTab != 0) {
          setState(() {
            _currentTab = 0;
          });
          return false; // Prevent exit, return to Home tab instead
        }
        return true; // Allow exit if player is closed and on Home tab
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F14), // Dark metallic grey background
        body: Stack(
          children: [
          // 1. DYNAMIC COLOR GRADIENT SHADOW (Home/Search Background)
          Container(
            color: const Color(0xFF0A0A0E), // Deeper pure dark
          ),
          // Top right pink glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.pinkAccent.withOpacity(0.15),
                    Colors.pinkAccent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom left purple glow
          Positioned(
            bottom: 0,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepPurpleAccent.withOpacity(0.12),
                    Colors.deepPurpleAccent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Center subtle blue glow
          Positioned(
            top: screenHeight * 0.3,
            left: screenHeight * 0.1,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.08),
                    Colors.blueAccent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. MAIN ACTIVE TAB CONTENT
          IndexedStack(
            index: _currentTab,
            children: _screens,
          ),

          // 3. PERSISTENT PLAYER SLIDER DRAWER
          if (currentSong != null)
            AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                final double slideVal = _slideController.value;
                
                // Pushes the player panel top alignment based on slide controller value
                final double collapsedTop = screenHeight - miniPlayerHeight - bottomNavBarHeight - safeAreaBottom;
                final double currentTop = collapsedTop * (1.0 - slideVal);
                final double currentHeight = screenHeight - currentTop;

                return Positioned(
                  left: 0,
                  right: 0,
                  top: currentTop,
                  height: currentHeight,
                  child: GestureDetector(
                    onVerticalDragUpdate: _handleVerticalDragUpdate,
                    onVerticalDragEnd: _handleVerticalDragEnd,
                    child: Material(
                      color: Colors.transparent,
                      elevation: slideVal > 0.01 ? 24 : 0,
                      child: PlayerScreen(
                        slideValue: slideVal,
                        onCollapse: _collapsePlayer,
                        onExpand: _expandPlayer,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),

      // 4. BOTTOM NAVIGATION TABS (Spotify layout)
      // We hide the bottom navigation bar by shrinking it to 0 height as the player opens
      bottomNavigationBar: AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          final double slideVal = _slideController.value;
          
          return Container(
            height: bottomNavBarHeight * (1.0 - slideVal) + safeAreaBottom * (1.0 - slideVal),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: OverflowBox(
              minHeight: bottomNavBarHeight + safeAreaBottom,
              maxHeight: bottomNavBarHeight + safeAreaBottom,
              alignment: Alignment.topCenter,
              child: BottomNavigationBar(
                currentIndex: _currentTab,
                onTap: (index) {
                  setState(() {
                    _currentTab = index;
                  });
                },
                backgroundColor: const Color(0xFF0F0F14).withOpacity(0.95),
                selectedItemColor: Colors.pinkAccent,
                unselectedItemColor: Colors.white54,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    activeIcon: Icon(Icons.search_outlined),
                    label: 'Cari',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_outline),
                    activeIcon: Icon(Icons.favorite),
                    label: 'Koleksi',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ));
  }
}
