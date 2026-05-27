import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MinimalistNotesApp());
}

class MinimalistNotesApp extends StatelessWidget {
  const MinimalistNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF0F172A),
        dividerColor: const Color(0xFFE5E7EB),
        fontFamily: 'System',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}