// lib/home_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:indic_notetaker/models/recording_model.dart';
import 'package:indic_notetaker/screens/results_screen.dart';
import 'package:indic_notetaker/services/local_storage_service.dart';
import 'package:indic_notetaker/widgets/recording_card.dart';
import 'package:indic_notetaker/widgets/recording_setup_sheet.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isLoading = false;
  String _selectedTemplate = 'Meeting Notes';

  // !!! IMPORTANT: MAKE SURE THIS IS YOUR COMPUTER'S IP ADDRESS !!!
  final String _serverUrl = 'http://YOUR_COMPUTER_IP:8000/transcribe';
  
  // A future to hold our list of recordings
  late Future<List<Recording>> _recordingsFuture;

  @override
  void initState() {
    super.initState();
    // Load recordings when the screen first opens
    _loadRecordings();
  }

  void _loadRecordings() {
    setState(() {
      _recordingsFuture = LocalStorageService.getRecordings();
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
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
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocumentsDir.path}/my_recording.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final String? path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isLoading = true;
      });
      if (path != null) {
        _uploadRecording(path);
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadRecording(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_serverUrl));
      String templateApiValue =
          _selectedTemplate == 'Meeting Notes' ? 'meeting_notes' : 'todo_list';
      request.fields['template_type'] = templateApiValue;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var response = await request.send();

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = jsonDecode(responseBody);
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              summary: decodedResponse['summary'] ?? 'No summary found.',
              transcript: decodedResponse['transcript'] ?? 'No transcript found.',
            ),
          ),
        );

        // After returning from the results screen, reload the list
        _loadRecordings();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not get response from server.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Failed to connect to the server.')));
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(backgroundColor: Colors.teal.shade300, child: const Text('T')),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // Use a FutureBuilder to handle loading the data
              child: FutureBuilder<List<Recording>>(
                future: _recordingsFuture,
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

                  // If we have data, display it in a list
                  final recordings = snapshot.data!;
                  // Sort by date, newest first
                  recordings.sort((a, b) => b.date.compareTo(a.date));

                  return ListView(
                    children: [
                      const SizedBox(height: 16),
                      const Text('Latest', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...recordings.map((rec) {
                        return RecordingCard(
                          title: rec.title,
                          date: DateFormat.yMMMd().format(rec.date),
                          onTap: () {
                            // Navigate to results page with the saved data
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ResultsScreen(
                                summary: rec.summary,
                                transcript: rec.transcript,
                              ),
                            ));
                          },
                        );
                      }).toList(),
                    ],
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