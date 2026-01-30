import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  Future<Map<String, double>> _calculateProgress() async {
    if (userId == null) return {};

    final watchedLecturesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('watched_lectures')
        .get();

    final Map<String, int> watchedCount = {};
    for (var doc in watchedLecturesSnapshot.docs) {
      final courseId = doc.data()['courseId'] as String?;
      if (courseId != null) {
        watchedCount[courseId] = (watchedCount[courseId] ?? 0) + 1;
      }
    }

    final coursesSnapshot = await FirebaseFirestore.instance.collection('course').get();
    final Map<String, int> totalLectures = {};
    for (var courseDoc in coursesSnapshot.docs) {
      final lecturesSnapshot = await courseDoc.reference.collection('lectures').where('isActive', isEqualTo: true).get();
      totalLectures[courseDoc.id] = lecturesSnapshot.docs.length;
    }

    final Map<String, double> progress = {};
    watchedCount.forEach((courseId, count) {
      if (totalLectures.containsKey(courseId) && totalLectures[courseId]! > 0) {
        progress[courseId] = count / totalLectures[courseId]!;
      }
    });

    return progress;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'My Certificates',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _calculateProgress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading progress.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No progress to show yet. Start watching lectures!'));
          }

          final progressData = snapshot.data!;

          return ListView.builder(
            itemCount: progressData.length,
            itemBuilder: (context, index) {
              final courseId = progressData.keys.elementAt(index);
              final progress = progressData[courseId]!;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('course').doc(courseId).get(),
                builder: (context, courseSnapshot) {
                  if (!courseSnapshot.hasData) {
                    return const ListTile(title: Text('Loading course...'));
                  }

                  final courseData = courseSnapshot.data!.data() as Map<String, dynamic>;
                  final courseTitle = courseData['title'] ?? 'Unknown Course';

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(courseTitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 4),
                          Text('${(progress * 100).toStringAsFixed(0)}% Complete'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
