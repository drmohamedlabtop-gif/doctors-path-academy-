import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && doc.data()!.containsKey('name')) {
          setState(() {
            _nameController.text = doc.data()!['name'];
          });
        }
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty"), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
       }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildStyledTextField(
              controller: _nameController,
              labelText: "Full Name",
              icon: Icons.person_outline,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 30),
            _buildSaveChangesButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: iconColor.withOpacity(0.15),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            border: InputBorder.none,
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildSaveChangesButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateProfile,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24, height: 24, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
