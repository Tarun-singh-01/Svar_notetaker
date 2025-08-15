// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:indic_notetaker/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _signInWithGoogle() async {
    try {
      const webClientId = '970435663213-the6m17lon0s7qrevjh79opg7bdm4797.apps.googleusercontent.com'; // ** Remember to paste your ID here **
      const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // User cancelled the sign-in
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Svar AI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _signInWithGoogle,
          icon: const Icon(Icons.login),
          label: const Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }
}