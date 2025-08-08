// lib/widgets/recording_card.dart

import 'package:flutter/material.dart';

class RecordingCard extends StatelessWidget {
  final String title;
  final String date;
  final VoidCallback onTap;

  const RecordingCard({
    super.key,
    required this.title,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2C2C2E), // Dark card color from your design
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.cases_rounded, color: Color(0xFFE0E0E0)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}