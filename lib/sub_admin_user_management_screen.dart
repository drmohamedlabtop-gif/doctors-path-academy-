import 'package:doctors_path_academy/course_model.dart';
import 'package:doctors_path_academy/manage_courses_screen.dart';
import 'package:doctors_path_academy/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class SubAdminUserManagementScreen extends StatelessWidget {
  const SubAdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final accessibleCourseIds = userProvider.accessibleCourseIds;

    if (accessibleCourseIds.isEmpty) {
      return const Center(
        child: Text(
          'You have not been assigned any courses to manage.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
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
            return const Center(
                child: Text(
              'No courses found matching your permissions.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ));
          }

          final courses = snapshot.data!.docs;

          return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.80,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return CourseAccessCard(course: course);
          },
        );
        },
      ),
    );
  }
}
