import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'screens/dashboard_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system status bar and navigation bar overlays to transparent and matching dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0F0F14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioProvider(),
      child: const MusicApp(),
    ),
  );
}

class MusicApp extends StatelessWidget {
  const MusicApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fusion Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        
        // Use the Outfit Google Font for a clean and sleek Apple Music typography style
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        
        colorScheme: const ColorScheme.dark(
          primary: Colors.pink,
          secondary: Colors.pinkAccent,
          surface: Color(0xFF1E1E24),
          error: Colors.redAccent,
        ),
        
        useMaterial3: true,
      ),
      home: const DashboardLayout(),
    );
  }
}
