// lib/widgets/recording_setup_sheet.dart

import 'package:flutter/material.dart';

class RecordingSetupSheet extends StatefulWidget {
  // We add a function parameter to be called when the button is pressed
  final Function(String language, String template) onStartRecording;

  const RecordingSetupSheet({
    super.key,
    required this.onStartRecording,
  });

  @override
  State<RecordingSetupSheet> createState() => _RecordingSetupSheetState();
}

class _RecordingSetupSheetState extends State<RecordingSetupSheet> {
  String _selectedLanguage = 'English';
  String _selectedTemplate = 'Meeting Notes';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (The DropdownButtonFormFields remain the same)
          const Text('Select Language', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            items: ['English', 'Hindi']
                .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedLanguage = value);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1C1C1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Template Type', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedTemplate,
            items: ['Meeting Notes', 'To-Do List']
                .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedTemplate = value);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1C1C1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Call the function passed from the HomeScreen
                widget.onStartRecording(_selectedLanguage, _selectedTemplate);
                Navigator.pop(context); // Close the bottom sheet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start recording', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}