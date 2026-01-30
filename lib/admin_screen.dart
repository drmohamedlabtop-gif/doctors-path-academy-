import 'package:doctors_path_academy/add_course_screen.dart';
import 'package:doctors_path_academy/add_lecture_screen.dart';
import 'package:doctors_path_academy/admin/manage_admins_screen.dart';
import 'package:doctors_path_academy/manage_courses_screen.dart';
import 'package:doctors_path_academy/admin/manage_users_screen.dart';
import 'package:doctors_path_academy/sub_admin_courses_screen.dart';
import 'package:doctors_path_academy/sub_admin_user_management_screen.dart'; // Updated import
import 'package:doctors_path_academy/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late String _currentTitle;
  Widget? _currentScreen;

  late Map<String, Widget> _availableScreens;

  static const Color _adminColor = Color(0xFF673AB7); // Deep Purple

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeScreens();
  }

  // This function clearly defines which screens are available for which role.
  Map<String, Widget> _getScreensForUser(UserProvider userProvider) {
    final Map<String, Widget> screens = {};

    if (userProvider.isSuperAdmin) {
      // Super Admin sees all management screens.
      screens['Manage Courses'] = const ManageCoursesScreen();
      screens['Manage Users'] = const ManageUsersScreen();
      screens['Manage Admins'] = const ManageAdminsScreen();
      screens['Add New Course'] = const AddCourseScreen();
      screens['Add New Lecture'] = const AddLectureScreen();

    } else if (userProvider.isSubAdmin) {
      // Sub Admin sees a limited, permission-based set of screens.
      if (userProvider.hasPermission('canViewCourses')) {
        screens['View Courses'] = const SubAdminCoursesScreen();
      }

      if (userProvider.hasPermission('canManageUsers')) {
        // This now correctly points to the new management screen.
        screens['Manage Users'] = const SubAdminUserManagementScreen();
      } 
      if (userProvider.hasPermission('canAddCourses')) {
        screens['Add New Course'] = const AddCourseScreen();
      }
      if (userProvider.hasPermission('canAddLectures')) {
        screens['Add New Lecture'] = const AddLectureScreen();
      }
    }
    
    return screens;
  }

  void _initializeScreens() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _availableScreens = _getScreensForUser(userProvider);

    if (_availableScreens.isNotEmpty) {
      setState(() {
        _currentTitle = _availableScreens.keys.first;
        _currentScreen = _availableScreens.values.first;
      });
    } else {
      // This state occurs if a user is an admin but has no permissions assigned.
      setState(() {
        _currentTitle = 'Access Denied';
        _currentScreen = const Center(child: Text('You do not have any admin permissions.'));
      });
    }
  }

  void _selectScreen(String title) {
    // Check if the screen exists before attempting to switch
    if (mounted && _availableScreens.containsKey(title)) {
      setState(() {
        _currentTitle = title;
        _currentScreen = _availableScreens[title]!;
      });
      Navigator.of(context).pop(); // Close the drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Determine the screens available for the current user.
    final newScreens = _getScreensForUser(userProvider);

    // If the available screens have changed (e.g., due to a permission update),
    // rebuild the widget tree safely in the next frame.
    if (!_areMapsEqual(newScreens, _availableScreens)) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeScreens();
        });
    }
    
    // Ensure a screen is always selected if available.
    if (_currentScreen == null && newScreens.isNotEmpty) {
      _currentTitle = newScreens.keys.first;
      _currentScreen = newScreens.values.first;
    } else if (newScreens.isEmpty) {
      _currentTitle = 'Access Denied';
      _currentScreen = const Center(child: Text('You do not have any admin permissions.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _adminColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      // Pass the list of available screen titles to the drawer.
      drawer: _buildAdminDrawer(userProvider, newScreens.keys.toList()),
      body: _currentScreen,
    );
  }

  Widget _buildAdminDrawer(UserProvider userProvider, List<String> screenTitles) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: _adminColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(
                  userProvider.isSuperAdmin ? 'Super Admin Panel' : 'Admin Panel',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(userProvider.user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          // These items will only appear if they are in the screenTitles list.
          if (screenTitles.contains('View Courses'))
            _buildDrawerItem(title: 'View Courses', icon: Icons.collections_bookmark),
          if (screenTitles.contains('Manage Courses'))
            _buildDrawerItem(title: 'Manage Courses', icon: Icons.collections_bookmark),
          if (screenTitles.contains('Manage Users'))
            _buildDrawerItem(title: 'Manage Users', icon: Icons.people_alt),
          if (screenTitles.contains('Manage Admins'))
            _buildDrawerItem(title: 'Manage Admins', icon: Icons.security),
          
          if (screenTitles.contains('Add New Course') || screenTitles.contains('Add New Lecture')) const Divider(),

          if (screenTitles.contains('Add New Course'))
            _buildDrawerItem(title: 'Add New Course', icon: Icons.add_box),
          if (screenTitles.contains('Add New Lecture'))
            _buildDrawerItem(title: 'Add New Lecture', icon: Icons.video_library),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required String title, required IconData icon}) {
    final theme = Theme.of(context);
    final isSelected = _currentTitle == title;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? _adminColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? _adminColor : theme.iconTheme.color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? _adminColor : theme.textTheme.bodyLarge?.color,
          ),
        ),
        onTap: () => _selectScreen(title),
      ),
    );
  }
  
  // Helper to compare if the available screens have changed.
  bool _areMapsEqual(Map<String, Widget> a, Map<String, Widget> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
    }
    return true;
  }
}
