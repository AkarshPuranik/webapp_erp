import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String id;
  String title;
  String description;
  DateTime date;
  List<String> mediaUrls;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.mediaUrls,
  });

  // Create an Event object from Firestore document
  factory Event.fromFirestore(Map<String, dynamic> data, String id) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
    );
  }

  // Convert Event object to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'mediaUrls': mediaUrls,
    };
  }
}
