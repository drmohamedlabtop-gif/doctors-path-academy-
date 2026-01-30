import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctors_path_academy/admin/add_edit_course_screen.dart';
import 'package:doctors_path_academy/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  Future<void> _deleteCourse(String courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('course').doc(courseId).delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _navigateToAddEditScreen([DocumentSnapshot? course]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditCourseScreen(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    // Decide which query to use based on user role
    Query query = FirebaseFirestore.instance.collection('course');
    if (user != null && user.role == 'subAdmin') {
      final accessibleCourseIds = user.accessibleCourseIds;
      if (accessibleCourseIds.isNotEmpty) {
        query = query.where(FieldPath.documentId, whereIn: accessibleCourseIds);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }

          final courses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final courseData = course.data() as Map<String, dynamic>;
              final String title = courseData['title'] ?? 'No Title';

              return ListTile(
                title: Text(title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToAddEditScreen(course),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCourse(course.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(),
        child: const Icon(Icons.add),
      ),
    );
  }
}