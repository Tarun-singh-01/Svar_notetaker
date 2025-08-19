// lib/screens/results_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Player Placeholder
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                recording.title,
                style: GoogleFonts.redHatDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Date and Time
              Text(
                DateFormat('MMMM d, yyyy  h:mm a').format(recording.createdAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 16),
              // TabBar
              const TabBar(
                indicatorColor: Color(0xFFBF8BFF),
                indicatorWeight: 3,
                labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontSize: 16),
                tabs: [
                  Tab(text: 'Summary'),
                  Tab(text: 'Transcript'),
                  Tab(text: 'Action Items'),
                ],
              ),
              // TabBarView
              Expanded(
                child: TabBarView(
                  children: [
                    // Summary Tab
                    _buildContentSection("Overview", recording.summary),
                    // Transcript Tab
                    _buildContentSection("Transcript", recording.transcript),
                    // Action Items Tab
                    _buildContentSection(
                      "Action Items",
                      recording.actionItems ?? "No action items were identified." // <-- DISPLAY THE DATA
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the content for each tab
  Widget _buildContentSection(String title, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.redHatDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFFE0E0E0)),
          ),
        ],
      ),
    );
  }
}