import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final List<String> enrolledUsers;

  Course({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.enrolledUsers,
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? 'Untitled Course',
      thumbnailUrl: data['thumbnailUrl'],
      enrolledUsers: List<String>.from(data['authorizedUsers'] ?? []),
    );
  }
}
