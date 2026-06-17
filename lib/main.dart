import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/meeting_provider.dart';
import 'screens/home_screen.dart';
import 'screens/recording_screen.dart';
import 'screens/transcript_screen.dart';
import 'screens/mom_editor_screen.dart';
import 'screens/share_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => MeetingProvider(),
      child: const MomGeneratorApp(),
    ),
  );
}

class MomGeneratorApp extends StatelessWidget {
  const MomGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MeetingProvider>(context);

    //  elegant dark theme (Obsidian & Chalk)
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Color(0xFF8E8E93), //  neutral grey
        background: Color(0xFF000000), // Pure Black
        surface: Color(0xFF121212), // Dark Charcoal
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
        error: Color(0xFFFF453A),
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      dividerColor: const Color(0xFF262626), 
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: -0.5),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white, letterSpacing: -0.2),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFE5E5E7), height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF8E8E93), height: 1.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121212),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF262626), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF262626), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF262626), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
        hintStyle: const TextStyle(color: Color(0xFF48484A)),
      ),
    );

    // elegant light theme (Alabaster & Charcoal)
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Color(0xFF6C6C70),
        background: Color(0xFFF2F2F7), // Light Slate grey
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onBackground: Colors.black,
        onSurface: Colors.black,
        error: Color(0xFFFF3B30),
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      dividerColor: const Color(0xFFE5E5EA),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black, letterSpacing: -0.5),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black, letterSpacing: -0.2),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF1C1C1E), height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6C6C70), height: 1.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6C6C70)),
        hintStyle: const TextStyle(color: Color(0xFFAEAEB2)),
      ),
    );

    return MaterialApp(
      title: 'MoM Generator',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: provider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/recording': (context) => const RecordingScreen(),
        '/transcript': (context) => const TranscriptScreen(),
        '/editor': (context) => const MomEditorScreen(),
        '/share': (context) => const ShareScreen(),
      },
    );
  }
}
