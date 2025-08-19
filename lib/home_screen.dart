// lib/home_screen.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final String _serverUrl = 'https://svar-ai-server.onrender.com/transcribe'; 

  List<Recording> _notes = [];
  bool _isFetching = true;

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
          const SnackBar(content: Text('Microphone permission is required.')),
        );
      }
      return;
    }
    await _audioRecorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> _fetchNotes() async {
    if (supabase.auth.currentUser == null) return;
    if (mounted) setState(() { _isFetching = true; });
    try {
      final data = await supabase
          .from('notes')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      
      final List<Recording> tempNotes = [];
      for (final item in data) {
        try {
          tempNotes.add(Recording.fromJson(item));
        } catch (e) {
          print("❌ FAILED TO PARSE RECORDING: ID=${item['id']}");
          print("   RAW DATA: $item");
          print("   ERROR: $e");
        }
      }
      
      if (mounted) {
        setState(() {
          _notes = tempNotes;
          _isFetching = false;
        });
      }
    } catch (e) {
      print("Error fetching notes list: $e");
      if (mounted) setState(() { _isFetching = false; });
    }
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    super.dispose();
  }
  
  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) { /* Handle error */ }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showRecordingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2E),
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
    if (!_isRecorderInitialized) return;
    try {
      final Directory tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/flutter_sound.aac';
      await _audioRecorder.startRecorder(toFile: _recordingPath, codec: Codec.aacADTS);
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
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ));

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'template_type': _selectedTemplate,
      });

      final response = await dio.post(_serverUrl, data: formData);
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final decodedResponse = response.data;
        
        // --- THIS IS THE KEY CHANGE ---
        final List<dynamic> newNoteData = await supabase.from('notes').insert({
          'title': 'Recording from ${DateFormat.yMMMd().format(DateTime.now())}',
          'summary': decodedResponse['summary'] ?? 'No summary.',
          'transcript': decodedResponse['transcript'] ?? 'No transcript.',
          'action_items': decodedResponse['action_items'] ?? 'No action items.', // <-- SAVE THE NEW DATA
          'user_id': supabase.auth.currentUser!.id,
        }).select();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note saved successfully!'), backgroundColor: Colors.green),
          );
        }

        if (newNoteData.isNotEmpty) {
           final newRecording = Recording.fromJson(newNoteData.first);
           setState(() {
             _notes.insert(0, newRecording);
           });

           if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ResultsScreen(recording: newRecording),
            ));
          }
        } else {
          await _fetchNotes();
        }

      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: const Text('T', style: TextStyle(fontWeight: FontWeight.bold)), // Placeholder for profile
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
            onRefresh: _fetchNotes,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                    child: Text(
                      'Latest',
                      style: GoogleFonts.redHatDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _isFetching
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  : _notes.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No recordings yet.\nTap the mic to start!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final recording = _notes[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: RecordingCard(
                                title: recording.title,
                                date: DateFormat.yMMMd().format(recording.createdAt),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => ResultsScreen(recording: recording),
                                  ));
                                },
                              ),
                            );
                          },
                          childCount: _notes.length,
                        ),
                      ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _showRecordingSheet,
        backgroundColor: _isRecording ? Colors.red : const Color(0xFFBF8BFF),
        child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1C1C1E),
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(icon: const Icon(Icons.home_filled), color: _selectedIndex == 0 ? const Color(0xFFBF8BFF) : Colors.grey, onPressed: () => _onItemTapped(0)),
            IconButton(icon: const Icon(Icons.book_outlined), color: _selectedIndex == 1 ? const Color(0xFFBF8BFF) : Colors.grey, onPressed: () => _onItemTapped(1)),
            IconButton(icon: const Icon(Icons.settings_outlined), color: _selectedIndex == 2 ? const Color(0xFFBF8BFF) : Colors.grey, onPressed: () => _onItemTapped(2)),
          ],
        ),
      ),
    );
  }
}
