import 'package:doctors_path_academy/course_model.dart';
import 'package:doctors_path_academy/course_users_viewer_screen.dart';
import 'package:doctors_path_academy/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class SubAdminCoursesScreen extends StatelessWidget {
  const SubAdminCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final accessibleCourseIds = userProvider.accessibleCourseIds;

    if (accessibleCourseIds.isEmpty) {
      return Center(
        child: Text(
          'You have not been assigned any courses yet.',
          style: TextStyle(fontSize: 16, color: theme.disabledColor),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('course')
            .where(FieldPath.documentId, whereIn: accessibleCourseIds)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(
              'No courses found matching your permissions.',
              style: TextStyle(fontSize: 16, color: theme.disabledColor),
            ));
          }

          final courses = snapshot.data!.docs
              .map((doc) => Course.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text('Enrolled Users: ${course.enrolledUsers.length}'),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseUsersViewerScreen(
                          courseId: course.id,
                          courseTitle: course.title,
                          enrolledUsers: course.enrolledUsers,
                        ),
                      ),
                    );
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
