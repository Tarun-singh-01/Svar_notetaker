// lib/models/recording_model.dart

// ignore: unused_import
import 'dart:convert';

class Recording {
  final String id;
  final String title;
  final DateTime date;
  final String summary;
  final String transcript;

  Recording({
    required this.id,
    required this.title,
    required this.date,
    required this.summary,
    required this.transcript,
  });

  // This method converts our Recording object into a Map,
  // which can then be easily converted to a JSON string.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(), // Convert DateTime to a standard string format
      'summary': summary,
      'transcript': transcript,
    };
  }

  // This factory constructor creates a Recording object from a Map.
  // This is how we'll decode the data when we load it from storage.
  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']), // Convert the string back to DateTime
      summary: json['summary'],
      transcript: json['transcript'],
    );
  }
}