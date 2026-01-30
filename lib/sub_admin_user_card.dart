
import 'package:doctors_path_academy/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubAdminUserCard extends StatefulWidget {
  final QueryDocumentSnapshot user;
  final UserProvider userProvider;
  const SubAdminUserCard({super.key, required this.user, required this.userProvider});

  @override
  State<SubAdminUserCard> createState() => _SubAdminUserCardState();
}

class _SubAdminUserCardState extends State<SubAdminUserCard> {
  Future<List<QueryDocumentSnapshot>>? _enrolledCoursesFuture;
  List<String> _accessibleCourseIds = [];

  @override
  void initState() {
    super.initState();
    _accessibleCourseIds = widget.userProvider.accessibleCourseIds;
    _enrolledCoursesFuture = _fetchEnrolledCourses();
  }

  Future<List<QueryDocumentSnapshot>> _fetchEnrolledCourses() async {
    Query query = FirebaseFirestore.instance.collection('course').where('authorizedUsers', arrayContains: widget.user.id);

    if (widget.userProvider.user?.role == 'subAdmin' && _accessibleCourseIds.isNotEmpty) {
      query = query.where(FieldPath.documentId, whereIn: _accessibleCourseIds);
    }

    final coursesSnapshot = await query.get();
    return coursesSnapshot.docs;
  }

  Future<void> _updateUserCourseAccess(List<String> newCourseIds) async {
    final enrolledCourseDocs = await _enrolledCoursesFuture ?? [];
    final oldCourseIds = enrolledCourseDocs.map((doc) => doc.id).toList();
    final userId = widget.user.id;

    final coursesToAdd = newCourseIds.where((id) => !oldCourseIds.contains(id)).toList();
    final coursesToRemove = oldCourseIds.where((id) => !newCourseIds.contains(id)).toList();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating user access...')));
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final courseId in coursesToAdd) {
        batch.update(FirebaseFirestore.instance.collection('course').doc(courseId), {
          'authorizedUsers': FieldValue.arrayUnion([userId])
        });
      }

      for (final courseId in coursesToRemove) {
        batch.update(FirebaseFirestore.instance.collection('course').doc(courseId), {
          'authorizedUsers': FieldValue.arrayRemove([userId])
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User course access updated successfully.'), backgroundColor: Colors.green));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Permission Error: ${e.message}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _showCourseManagementDialog() async {
    Query query = FirebaseFirestore.instance.collection('course');
    if (widget.userProvider.user?.role == 'subAdmin' && _accessibleCourseIds.isNotEmpty) {
      query = query.where(FieldPath.documentId, whereIn: _accessibleCourseIds);
    }
    final allManageableCoursesSnapshot = await query.orderBy('title').get();
    final allManageableCourses = allManageableCoursesSnapshot.docs;

    final enrolledCourseDocs = await _enrolledCoursesFuture ?? [];
    final enrolledCourseIds = enrolledCourseDocs.map((doc) => doc.id).toList();

    await showDialog(
      context: context,
      builder: (context) {
        final tempSelectedCourseIds = List<String>.from(enrolledCourseIds);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Manage Courses for ${widget.user['name']}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allManageableCourses.length,
                  itemBuilder: (context, index) {
                    final course = allManageableCourses[index];
                    final isSelected = tempSelectedCourseIds.contains(course.id);
                    return CheckboxListTile(
                      title: Text(course['title'] ?? 'No Title'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedCourseIds.add(course.id);
                          } else {
                            tempSelectedCourseIds.remove(course.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _updateUserCourseAccess(tempSelectedCourseIds);
                    if (mounted) {
                       setState(() {
                         _enrolledCoursesFuture = _fetchEnrolledCourses();
                       });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userData = widget.user.data() as Map<String, dynamic>;
    final name = userData['name'] ?? 'No Name';
    final email = userData['email'] ?? 'No Email';
    final phone = userData['phone'] ?? 'Not Provided';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                      if (phone != 'Not Provided')
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(phone, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                        ),
                    ],
                  ),
                ),
                if (widget.userProvider.hasPermission('canEditCourseAccess'))
                  IconButton(
                    icon: Icon(Icons.manage_accounts, color: theme.colorScheme.secondary),
                    tooltip: 'Manage Course Access',
                    onPressed: _showCourseManagementDialog,
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildEnrolledCourses(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledCourses() {
    final theme = Theme.of(context);
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _enrolledCoursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2.0)));
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}")); // Show error if fetching courses fails
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Text('Not enrolled in any courses.', style: TextStyle(color: theme.disabledColor));
        
        final courseDocs = snapshot.data!;
        final courseTitles = courseDocs.map((doc) => (doc.data() as Map<String, dynamic>)['title'] ?? 'Untitled').toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enrolled Courses (${courseTitles.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: courseTitles.map((title) => Chip(label: Text(title), backgroundColor: theme.chipTheme.backgroundColor, labelStyle: theme.chipTheme.labelStyle)).toList(),
            ),
          ],
        );
      },
    );
  }
}
