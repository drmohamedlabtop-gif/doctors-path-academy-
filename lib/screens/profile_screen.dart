
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:doctors_path_academy/my_certificates_screen.dart';
import 'package:doctors_path_academy/screens/edit_profile_screen.dart';

import 'auth_check.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthCheck()),
                  (route) => false,
                );
              }
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Change Password"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await FirebaseAuth.instance.currentUser
                        ?.updatePassword(newPasswordController.text);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Password changed successfully!")),
                    );
                  } on FirebaseAuthException catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.message}")),
                    );
                  }
                }
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found."));
          }

          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          String displayName = data['name'] ?? "Dr Mohamed";
          String displayEmail = user.email ?? "nmm@gmail.com";

          return Column(
            children: [
              _buildProfileHeader(context, displayName, displayEmail),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  children: [
                    _buildSectionHeader(context, "Account"),
                    const SizedBox(height: 10),
                    _buildProfileOption(
                      context,
                      icon: Icons.person_outline,
                      iconBgColor: Colors.blue,
                      title: "Edit Profile",
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ));
                      },
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    _buildProfileOption(
                      context,
                      icon: Icons.lock_outline,
                      iconBgColor: Colors.green,
                      title: "Change Password",
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionHeader(context, "General"),
                    const SizedBox(height: 10),
                     _buildProfileOption(
                        context,
                        icon: Icons.school_outlined,
                        iconBgColor: Colors.orange,
                        title: "My Certificates",
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const MyCertificatesScreen(),
                          ));
                        },
                      ),
                    const Divider(indent: 16, endIndent: 16),
                    _buildProfileOption(
                      context,
                      icon: Icons.logout,
                      iconBgColor: Colors.red,
                      title: "Logout",
                      onTap: () => _showLogoutConfirmationDialog(context),
                      titleColor: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email) {
    final theme = Theme.of(context);
    const profileHeaderColor = Color(0xFF673AB7); // Deep Purple

    return SizedBox(
      height: 300, // Increased from 280 to give more space
      child: Stack(
        children: [
          ClipPath(
            clipper: ProfileHeaderClipper(),
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [profileHeaderColor.withOpacity(0.8), profileHeaderColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Text(
              "My Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'D',
                      style: TextStyle(
                        fontSize: 48,
                        color: profileHeaderColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: iconBgColor.withOpacity(0.15),
        child: Icon(icon, color: iconBgColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: titleColor),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
