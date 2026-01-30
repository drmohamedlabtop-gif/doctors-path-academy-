
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  const Text('No Users Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('User accounts will appear here when they register.', style: TextStyle(color: theme.disabledColor)),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final String email = userData['email'] ?? 'No Email';
              final String name = userData['name'] ?? 'No Name';
              final String phone = userData['phone'] ?? 'No Phone';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8))),
                      Text(phone, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8))),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteUserDialog(user.id, name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteUserDialog(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the user "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
            );
        }
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.red),
            );
        }
      }
    }
  }
}
