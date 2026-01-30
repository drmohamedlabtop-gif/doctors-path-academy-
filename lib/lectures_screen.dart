import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctors_path_academy/video_player_screen.dart';
import 'package:flutter/material.dart';

class LecturesScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const LecturesScreen({Key? key, required this.courseId, required this.courseTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('course')
            .doc(courseId)
            .collection('lectures')
            .orderBy('order')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lectures = snapshot.data!.docs;

          if (lectures.isEmpty) {
            return const Center(child: Text('No lectures available for this course yet.'));
          }

          return ListView.builder(
            itemCount: lectures.length,
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              final data = lecture.data() as Map<String, dynamic>?;

              final String title = data?['title'] as String? ?? 'No Title';
              final int order = data?['order'] as int? ?? 0;
              
              final dynamic videoData = data?['videoId'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(order.toString()),
                  ),
                  title: Text(title),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () {
                    if (videoData is String && videoData.isNotEmpty) {
                      // Handle simple video URL
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(
                            videoUrl: videoData,
                            courseId: courseId,
                            lectureId: lecture.id,
                          ),
                        ),
                      );
                    } else if (videoData is Map) {
                      // Handle map of video qualities
                      final Map<String, String> videoQualities = Map<String, String>.from(videoData);
                      if (videoQualities.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              videoQualities: videoQualities,
                              courseId: courseId,
                              lectureId: lecture.id,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Video not available for this lecture.')),
                        );
                      }
                    } else {
                      // Handle case where video data is missing or invalid
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video not available for this lecture.')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
