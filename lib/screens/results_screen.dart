// lib/screens/results_screen.dart

import 'package:flutter/material.dart';
import 'package:indic_notetaker/models/recording_model.dart';
import 'package:intl/intl.dart';

class ResultsScreen extends StatelessWidget {
  final Recording recording;

  const ResultsScreen({
    super.key,
    required this.recording,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // We now have 3 tabs as per your design
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
              Tab(text: 'Action Items'), // Added Action Items tab
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // We'll add the audio player UI here in a future step
              Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              // Use the title and date from the recording object
              Text(
                recording.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM d, yyyy  h:mm a').format(recording.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  children: [
                    // --- This is the fix ---
                    // Display the summary from the passed 'recording' object
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        recording.summary,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    // Display the transcript from the passed 'recording' object
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        recording.transcript,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    // Placeholder for Action Items
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