// lib/models/recording_model.dart

class Recording {
  final String? id; // Can be null if the object hasn't been saved yet
  final String title;
  final DateTime createdAt;
  final String summary;
  final String transcript;
  // We will use user_id in a later phase

  Recording({
    this.id,
    required this.title,
    required this.createdAt,
    required this.summary,
    required this.transcript,
  });

  // A factory constructor to create a Recording from a Map (JSON)
  // This is how we'll read data from Supabase
  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String?,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      summary: json['summary'] as String,
      transcript: json['transcript'] as String,
    );
  }

  // A method to convert a Recording object into a Map
  // This is how we'll send data to Supabase
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'transcript': transcript,
      // We will add the 'user_id' here later when we implement authentication
    };
  }
}