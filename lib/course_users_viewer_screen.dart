import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CourseUsersViewerScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;
  final List<String> enrolledUsers;

  const CourseUsersViewerScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.enrolledUsers,
  });

  static const Color _adminColor = Color(0xFF673AB7); // Deep Purple

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _adminColor,
        foregroundColor: Colors.white,
      ),
      body: enrolledUsers.isEmpty
          ? Center(
              child: Text('No users are enrolled in this course yet.', style: TextStyle(color: theme.disabledColor, fontSize: 16)),
            )
          : ListView.builder(
              itemCount: enrolledUsers.length,
              itemBuilder: (context, index) {
                return UserProgressCard(userId: enrolledUsers[index], courseId: courseId);
              },
            ),
    );
  }
}

// A read-only card to display user progress.
class UserProgressCard extends StatefulWidget {
  final String userId;
  final String courseId;

  const UserProgressCard({super.key, required this.userId, required this.courseId});

  @override
  State<UserProgressCard> createState() => _UserProgressCardState();
}

class _UserProgressCardState extends State<UserProgressCard> {
  Future<Map<String, dynamic>>? _userDataFuture;
  static const Color _adminColor = Color(0xFF673AB7); // Deep Purple

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final userData = userDoc.data() ?? {};

    final lecturesSnapshot = await FirebaseFirestore.instance.collection('course').doc(widget.courseId).collection('lectures').get();
    final totalLectures = lecturesSnapshot.docs.length;

    final watchedSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('watched_lectures')
        .where('courseId', isEqualTo: widget.courseId)
        .get();
    final watchedCount = watchedSnapshot.docs.length;

    final double progress = (totalLectures > 0) ? (watchedCount / totalLectures) : 0.0;
    
    return {
      'name': userData['name'] ?? 'No Name',
      'email': userData['email'] ?? 'No Email',
      'phone': userData['phone'] ?? 'No Phone',
      'progress': progress,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: Center(heightFactor: 2.5, child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Error loading user data'),
            ),
          );
        }

        final data = snapshot.data!;
        final name = data['name'];
        final email = data['email'];
        final phone = data['phone']; // Get the phone number
        final progress = data['progress'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                          // Display the phone number if it exists and is not the default placeholder
                          if (phone != null && phone != 'No Phone')
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(phone, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(_adminColor),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
