// lib/main.dart

import 'package:flutter/material.dart';
import 'package:indic_notetaker/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indic Notetaker',
      // Set the theme to dark mode
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E), // A dark background color
        primarySwatch: Colors.deepPurple,
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: const HomeScreen(),
    );
  }
}