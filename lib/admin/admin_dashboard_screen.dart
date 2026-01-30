import 'package:doctors_path_academy/admin/manage_courses_screen.dart';
import 'package:doctors_path_academy/admin/manage_users_screen.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context,
            icon: Icons.school,
            title: 'Manage Courses',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ManageCoursesScreen()),
              );
            },
          ),
          _buildDashboardItem(
            context,
            icon: Icons.people,
            title: 'Manage Users',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
