// lib/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:indic_notetaker/home_screen.dart';
import 'package:indic_notetaker/main.dart';
import 'package:indic_notetaker/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final session = snapshot.data?.session;
          if (session != null) {
            return const HomeScreen();
          }
        }
        
        return const LoginScreen();
      },
    );
  }
}