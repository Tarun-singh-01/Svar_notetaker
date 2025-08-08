// lib/screens/results_screen.dart

import 'package:flutter/material.dart';
import 'package:indic_notetaker/models/recording_model.dart';
import 'package:indic_notetaker/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class ResultsScreen extends StatefulWidget {
  final String summary;
  final String transcript;

  const ResultsScreen({
    super.key,
    required this.summary,
    required this.transcript,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    // When this screen loads, automatically save the recording.
    _saveThisRecording();
  }

  Future<void> _saveThisRecording() async {
    final now = DateTime.now();
    final newRecording = Recording(
      id: now.millisecondsSinceEpoch.toString(), // A unique ID based on time
      title: 'Recording from ${DateFormat.yMMMd().format(now)}', // A generated title
      date: now,
      summary: widget.summary,
      transcript: widget.transcript,
    );

    await LocalStorageService.saveRecording(newRecording);
    print('Recording saved successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFFBF8BFF),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Transcript'),
              Tab(text: 'Action Items'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a').format(DateTime.now()),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(widget.summary),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(widget.transcript),
                    ),
                    const Center(child: Text('Action Items will be shown here.')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}