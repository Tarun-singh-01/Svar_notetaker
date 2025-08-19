// lib/models/recording_model.dart

class Recording {
  final String? id;
  final String title;
  final DateTime createdAt;
  final String summary;
  final String transcript;
  final String? actionItems; // <-- ADD THIS NEW FIELD

  Recording({
    this.id,
    required this.title,
    required this.createdAt,
    required this.summary,
    required this.transcript,
    this.actionItems, // <-- ADD TO CONSTRUCTOR
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String?,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      summary: json['summary'] as String,
      transcript: json['transcript'] as String,
      actionItems: json['action_items'] as String?, // <-- PARSE THE NEW FIELD
    );
  }
}
