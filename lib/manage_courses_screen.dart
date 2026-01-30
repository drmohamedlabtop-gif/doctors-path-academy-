import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================
// ======== MANAGE COURSES SCREEN
// =============================================
class ManageCoursesScreen extends StatelessWidget {
  const ManageCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('course').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No Courses Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Add a new course to get started.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
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
    );
  }
}

// =============================================
// ======== COURSE ACCESS CARD WIDGET
// =============================================
class CourseAccessCard extends StatelessWidget {
  final QueryDocumentSnapshot course;

  const CourseAccessCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final courseData = course.data() as Map<String, dynamic>;
    final title = courseData['title'] ?? 'No Title';
    final thumbnailUrl = courseData['thumbnailUrl'];
    final authorizedUsers = List<String>.from(courseData['authorizedUsers'] ?? []);
    const adminColor = Color(0xFF673AB7); // Deep Purple

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditCourseUsersScreen(course: course),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
              )
            else
              const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)),
            
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.black.withOpacity(0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: adminColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${authorizedUsers.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================
// ======== EDIT COURSE USERS SCREEN
// =============================================
class EditCourseUsersScreen extends StatefulWidget {
  final QueryDocumentSnapshot course;

  const EditCourseUsersScreen({super.key, required this.course});

  @override
  State<EditCourseUsersScreen> createState() => _EditCourseUsersScreenState();
}

class _EditCourseUsersScreenState extends State<EditCourseUsersScreen> {
  late Set<String> _authorizedUsers;
  final _searchController = TextEditingController();
  String _searchTerm = '';
  bool _isSaving = false;
  static const Color _adminColor = Color(0xFF673AB7); // Deep Purple

  @override
  void initState() {
    super.initState();
    final data = widget.course.data() as Map<String, dynamic>?;
    _authorizedUsers = Set<String>.from(data?['authorizedUsers'] ?? []);
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateAuthorizedUsers() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('course')
          .doc(widget.course.id)
          .update({'authorizedUsers': _authorizedUsers.toList()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseData = widget.course.data() as Map<String, dynamic>?;
    final courseTitle = courseData?['title'] ?? 'Untitled Course';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _adminColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Access for",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
              ),
            ),
            Text(
              courseTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateAuthorizedUsers,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search to add new users...',
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
  }

  Widget _buildUsersList() {
    if (_searchTerm.isNotEmpty) {
      return _buildSearchList();
    } else {
      return _buildAuthorizedList();
    }
  }

  // Widget for searching ALL users
  Widget _buildSearchList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('email').snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final filteredUsers = userSnapshot.data!.docs.where((doc) {
          final userData = doc.data() as Map<String, dynamic>?;
          final userEmail = userData?['email']?.toString().toLowerCase() ?? '';
          final name = userData?['name']?.toString().toLowerCase() ?? '';
          return userEmail.contains(_searchTerm) || name.contains(_searchTerm);
        }).toList();

        if (filteredUsers.isEmpty) return const Center(child: Text('No users match your search.'));
        
        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final userData = user.data() as Map<String, dynamic>?;
            final userEmail = userData?['email'] ?? 'No Email';
            final userId = user.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: SwitchListTile.adaptive(
                title: Text(userEmail),
                secondary: CircleAvatar(child: Text(userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?')),
                value: _authorizedUsers.contains(userId),
                onChanged: (bool value) {
                  setState(() {
                    if (value) {
                      _authorizedUsers.add(userId);
                    } else {
                      _authorizedUsers.remove(userId);
                    }
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  // Widget for displaying ONLY authorized users with details
  Widget _buildAuthorizedList() {
    if (_authorizedUsers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No users have access to this course.\nUse the search bar above to find and add them.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final userIds = _authorizedUsers.toList();

    return ListView.builder(
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index];
        return AuthorizedUserCard(
          key: ValueKey(userId),
          userId: userId,
          courseId: widget.course.id,
          onRemove: () {
            setState(() {
              _authorizedUsers.remove(userId);
            });
          },
        );
      },
    );
  }
}

// =============================================
// ======== AUTHORIZED USER CARD (NEW WIDGET)
// =============================================
class AuthorizedUserCard extends StatefulWidget {
  final String userId;
  final String courseId;
  final VoidCallback onRemove;

  const AuthorizedUserCard({super.key, required this.userId, required this.courseId, required this.onRemove});

  @override
  State<AuthorizedUserCard> createState() => _AuthorizedUserCardState();
}

class _AuthorizedUserCardState extends State<AuthorizedUserCard> {
  Future<Map<String, dynamic>>? _userDataFuture;
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _remainingAmountController = TextEditingController();
  static const Color _adminColor = Color(0xFF673AB7); // Deep Purple

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchData();
  }
  
  @override
  void dispose(){
      _paymentController.dispose();
      _remainingAmountController.dispose();
      super.dispose();
  }

  Future<void> _showRemoveConfirmationDialog(String userName) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Removal'),
          content: Text('Are you sure you want to remove "$userName" from this course?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onRemove();
    }
  }
  
  Future<void> _updatePayment() async {
    final amountPaid = double.tryParse(_paymentController.text) ?? 0.0;
    final amountRemaining = double.tryParse(_remainingAmountController.text) ?? 0.0;
    try {
      await FirebaseFirestore.instance
          .collection('users').doc(widget.userId)
          .collection('enrolledCourses').doc(widget.courseId)
          .set({
              'amountPaid': amountPaid,
              'amountRemaining': amountRemaining,
            }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update payment: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final userData = userDoc.data() ?? {};

    final enrolledCourseDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('enrolledCourses').doc(widget.courseId).get();
    final paymentData = enrolledCourseDoc.data() ?? {};
    final amountPaid = (paymentData['amountPaid'] ?? 0.0).toDouble();
    final amountRemaining = (paymentData['amountRemaining'] ?? 0.0).toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _paymentController.text = amountPaid.toStringAsFixed(1);
        _remainingAmountController.text = amountRemaining.toStringAsFixed(1);
      }
    });

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
      'phone': userData['phone'] ?? 'Not Provided',
      'progress': progress,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Center(heightFactor: 2.5, child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Error loading user data'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: widget.onRemove,
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final name = data['name'];
        final email = data['email'];
        final phone = data['phone'];
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
                    CircleAvatar(
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(email, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14)),
                          if (phone != 'Not Provided') ...[
                            const SizedBox(height: 2),
                            Text(phone, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14)),
                          ]
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      tooltip: 'Remove Access',
                      onPressed: () => _showRemoveConfirmationDialog(name),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(_adminColor),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                 Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _paymentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                            labelText: 'Amount Paid',
                            labelStyle: TextStyle(color: Colors.green),
                            prefixIcon: Icon(Icons.monetization_on_outlined, size: 18, color: Colors.green),
                            isDense: true,
                        ),
                        onEditingComplete: _updatePayment,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _remainingAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                            labelText: 'Amount Remaining',
                            labelStyle: TextStyle(color: Colors.red),
                            prefixIcon: Icon(Icons.money_off, size: 18, color: Colors.red),
                            isDense: true,
                        ),
                        onEditingComplete: _updatePayment,
                      ),
                    ),
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
