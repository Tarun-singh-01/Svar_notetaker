// lib/services/local_storage_service.dart

import 'dart:convert';
import 'package:indic_notetaker/models/recording_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  // A key to find our data in storage
  static const String _recordingsKey = 'recordings_key';

  // Method to save a new recording
  static Future<void> saveRecording(Recording newRecording) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Get the existing list of recordings
    final recordings = await getRecordings();
    
    // 2. Add the new recording to the list
    recordings.add(newRecording);
    
    // 3. Convert the list of Recording objects to a list of Maps
    List<Map<String, dynamic>> recordingsMapList = 
        recordings.map((r) => r.toJson()).toList();
    
    // 4. Encode the list of maps into a single JSON string
    String encodedData = jsonEncode(recordingsMapList);
    
    // 5. Save the JSON string to shared_preferences
    await prefs.setString(_recordingsKey, encodedData);
  }

  // Method to get all saved recordings
  static Future<List<Recording>> getRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Get the saved JSON string from storage
    final String? recordingsJson = prefs.getString(_recordingsKey);
    
    if (recordingsJson != null) {
      // 2. Decode the JSON string into a list of dynamic objects
      final List<dynamic> decodedList = jsonDecode(recordingsJson);
      
      // 3. Convert the list of dynamic objects into a list of Recording objects
      List<Recording> recordings = decodedList
          .map((jsonItem) => Recording.fromJson(jsonItem))
          .toList();
          
      return recordings;
    } else {
      // If no data is found, return an empty list
      return [];
    }
  }
}