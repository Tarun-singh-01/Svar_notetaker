// lib/main.dart

import 'package:flutter/material.dart';
import 'package:indic_notetaker/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lrzyfvxhkwkfudrihjub.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxyenlmdnhoa3drZnVkcmloanViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5OTM1OTgsImV4cCI6MjA3MDU2OTU5OH0.2EbnrFBU3IIMtOa-hcRC2gYnylDYWIl-B1qxf_juu5s',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Svar AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        primarySwatch: Colors.deepPurple,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}