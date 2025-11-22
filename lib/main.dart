import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PoorSpotApp());
}

class PoorSpotApp extends StatelessWidget {
  const PoorSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoorSpot',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        // Fond "Slate" (Gris Ardoise Profond)
        scaffoldBackgroundColor: const Color(0xFF0F172A), 
        primaryColor: const Color(0xFF38BDF8), // Light Blue Sky
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFFB7185), // Rose pastel
          surface: Color(0xFF1E293B), // Slate 800 pour les cartes
          onSurface: Color(0xFFE2E8F0), // Blanc cassé pour le texte
        ),
        
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}