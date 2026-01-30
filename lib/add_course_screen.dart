import 'package:doctors_path_academy/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class AddCourseScreen extends StatelessWidget {
  const AddCourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Permission Check
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.hasPermission('canAddCourses')) {
      return const Center(child: Text('You do not have permission to add courses.'));
    }

    return const AddCourseForm(); // Proceed to show the form
  }
}

class AddCourseForm extends StatefulWidget {
  const AddCourseForm({super.key});

  @override
  _AddCourseFormState createState() => _AddCourseFormState();
}

class _AddCourseFormState extends State<AddCourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addCourse() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('course').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'thumbnailUrl': _thumbnailUrlController.text,
          'createdAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course added successfully!'), backgroundColor: Colors.green));
        _formKey.currentState!.reset();
        _thumbnailUrlController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add course: $e'), backgroundColor: Colors.red));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildSectionTitle(context, 'Course Details'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _titleController, label: 'Course Title', icon: Icons.title, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _descriptionController, label: 'Course Description', icon: Icons.description, maxLines: 4, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _thumbnailUrlController,
                    label: 'Course Thumbnail URL',
                    icon: Icons.link,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (Uri.tryParse(v)?.isAbsolute != true) return 'Invalid URL';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSubmitButton(context),
                ],
              ),
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, String? Function(String?)? validator}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, icon: Icon(icon), border: InputBorder.none),
          maxLines: maxLines,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.onPrimary),
      label: Text('Add Course', style: TextStyle(color: theme.colorScheme.onPrimary)),
      onPressed: _addCourse,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: theme.colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
    );
  }
}
