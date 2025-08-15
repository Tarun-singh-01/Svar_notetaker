// lib/home_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart'; // Import dio
import 'package:flutter/material.dart';
import 'package:indic_notetaker/main.dart';
import 'package:indic_notetaker/models/recording_model.dart';
import 'package:indic_notetaker/screens/results_screen.dart';
import 'package:indic_notetaker/widgets/recording_card.dart';
import 'package:indic_notetaker/widgets/recording_setup_sheet.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _isLoading = false;
  String _selectedTemplate = 'Meeting Notes';
  String? _recordingPath;

  // Make sure this points to your live Render server URL
  final String _serverUrl = 'https://svar-ai-server.onrender.com/transcribe'; 

  late Future<List<Map<String, dynamic>>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _fetchNotes();
  }

  Future<void> _initializeRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to record audio.')),
        );
      }
      return;
    }
    await _audioRecorder.openRecorder();
    _isRecorderInitialized = true;
  }

  void _fetchNotes() {
    if (supabase.auth.currentUser == null) return;
    setState(() {
      _notesFuture = supabase
          .from('notes')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
    });
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    super.dispose();
  }
  
  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showRecordingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return RecordingSetupSheet(
          onStartRecording: (language, template) {
            _startRecording(language, template);
          },
        );
      },
    );
  }

  void _startRecording(String language, String template) {
    setState(() => _selectedTemplate = template);
    _performRecording();
  }

  Future<void> _performRecording() async {
    if (!_isRecorderInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorder not initialized. Please grant microphone permissions.')),
      );
      return;
    }
    try {
      final Directory tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/flutter_sound.aac';
      await _audioRecorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );
      setState(() => _isRecording = true);
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _isLoading = true;
      });
      if (_recordingPath != null) {
        _uploadRecording(_recordingPath!);
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadRecording(String filePath) async {
    // 1. Configure Dio with a longer timeout
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60), // 60 seconds to connect
      receiveTimeout: const Duration(seconds: 60), // 60 seconds to receive response
    ));

    try {
      // 2. Prepare the file for upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      // 3. Send the request
      final response = await dio.post(_serverUrl, data: formData);

      setState(() => _isLoading = false);

      // 4. Handle the response
      if (response.statusCode == 200) {
        final decodedResponse = response.data;
        
        final summary = decodedResponse['summary'] ?? 'No summary found.';
        final transcript = decodedResponse['transcript'] ?? 'No transcript found.';
        final now = DateTime.now();
        final title = 'Recording from ${DateFormat.yMMMd().format(now)}';

        // Insert the new note AND get the created record back
        final newNoteData = await supabase.from('notes').insert({
          'title': title,
          'summary': summary,
          'transcript': transcript,
          'user_id': supabase.auth.currentUser!.id,
        }).select().single();

        final newRecording = Recording.fromJson(newNoteData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to the ResultsScreen with the new recording
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ResultsScreen(recording: newRecording),
          ));
        }
        
        _fetchNotes(); 
    
      } else {
        print("Server Error Response: ${response.data}");
        if (mounted){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Could not get response from server.')));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Connection Error: $e");
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Failed to connect to the server.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recordings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _notesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No recordings yet.\nTap the mic to start!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final notes = snapshot.data!;
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final noteData = notes[index];
                      final recording = Recording.fromJson(noteData);

                      return RecordingCard(
                        title: recording.title,
                        date: DateFormat.yMMMd().format(recording.createdAt),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => ResultsScreen(
                              recording: recording,
                            ),
                          ));
                        },
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _showRecordingSheet,
        backgroundColor: _isRecording ? Colors.red : const Color(0xFFBF8BFF),
        child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2C2C2E),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(icon: const Icon(Icons.home), color: _selectedIndex == 0 ? const Color(0xFFBF8BFF) : Colors.grey, onPressed: () => _onItemTapped(0)),
            IconButton(icon: const Icon(Icons.book_outlined), color: _selectedIndex == 1 ? const Color(0xFFBF8BFF) : Colors.grey, onPressed: () => _onItemTapped(1)),
            IconButton(icon: const Icon(Icons.settings), color: _selectedIndex == 2 ? const Color(0xFFBF8BFF) : Colors.grey, onPressed: () => _onItemTapped(2)),
          ],
        ),
      ),
    );
  }
}