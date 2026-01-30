import 'package:doctors_path_academy/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// =============================================
// ======== MANAGE USERS SCREEN (FINAL REVISION)
// =============================================
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _searchTerm = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.hasPermission('canViewCourseAccess')) {
      return const Center(child: Text('You do not have permission to view this page.'));
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildUsersList(userProvider)),
      ],
    );
  }

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by email or name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      );

  Widget _buildUsersList(UserProvider userProvider) {
    Query query = FirebaseFirestore.instance.collection('users').orderBy('name');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading users: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        final filteredUsers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          return name.contains(_searchTerm) || email.contains(_searchTerm);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text('No users match your search.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 80),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return UserCard(key: ValueKey(user.id), user: user, userProvider: userProvider);
          },
        );
      },
    );
  }
}

// =============================================
// ======== USER CARD WIDGET
// =============================================
class UserCard extends StatefulWidget {
  final QueryDocumentSnapshot user;
  final UserProvider userProvider;

  const UserCard({super.key, required this.user, required this.userProvider});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  Future<List<QueryDocumentSnapshot>>? _enrolledCoursesFuture;
  List<String> _accessibleCourseIds = [];

  // New function to toggle the 'inactive' status
  Future<void> _toggleInactiveStatus() async {
    final userData = widget.user.data() as Map<String, dynamic>;
    final currentStatus = userData['inactive'] ?? 'no';
    final newStatus = currentStatus == 'yes' ? 'no' : 'yes';

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.id).update({'inactive': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User status set to ${newStatus.toUpperCase()}"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

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

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating user access...')));

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final courseId in coursesToAdd) {
        batch.update(FirebaseFirestore.instance.collection('course').doc(courseId), {'authorizedUsers': FieldValue.arrayUnion([userId])});
      }
      for (final courseId in coursesToRemove) {
        batch.update(FirebaseFirestore.instance.collection('course').doc(courseId), {'authorizedUsers': FieldValue.arrayRemove([userId])});
      }
      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access updated.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
                          if (value == true) tempSelectedCourseIds.add(course.id);
                          else tempSelectedCourseIds.remove(course.id);
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
                    if (mounted) setState(() => _enrolledCoursesFuture = _fetchEnrolledCourses());
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
    final isInactive = userData['inactive'] == 'yes'; // Check the inactive status

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      color: isInactive ? Colors.grey[350] : theme.cardColor, // Visually distinguish inactive users
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
                IconButton(
                  icon: Icon(isInactive ? Icons.lock : Icons.lock_open, color: isInactive ? Colors.red : Colors.green),
                  tooltip: isInactive ? 'Unblock User' : 'Block User',
                  onPressed: _toggleInactiveStatus,
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2.0)));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('Not enrolled in any courses.', style: TextStyle(color: theme.disabledColor));
        }

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
              children: courseTitles.map((title) => Chip(label: Text(title))).toList(),
            ),
          ],
        );
      },
    );
  }
}
