import 'package:doctors_path_academy/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddLectureScreen extends StatelessWidget {
  const AddLectureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Permission Check
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.hasPermission('canAddLectures')) {
      return const Scaffold(
        body: Center(child: Text('You do not have permission to add lectures.')),
      );
    }

    return const AddLectureForm(); // Proceed to show the form
  }
}

class AddLectureForm extends StatefulWidget {
  const AddLectureForm({super.key});

  @override
  _AddLectureFormState createState() => _AddLectureFormState();
}

class _AddLectureFormState extends State<AddLectureForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _orderController = TextEditingController();
  String? _selectedCourseId;
  bool _isLoading = false;

  Future<void> _addLecture() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('course').doc(_selectedCourseId).collection('lectures').add({
          'title': _titleController.text,
          'videoId': _videoUrlController.text,
          'order': int.tryParse(_orderController.text) ?? 0,
          'createdAt': Timestamp.now(),
          'isActive': true,
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lecture added successfully!'), backgroundColor: Colors.green));
        _formKey.currentState!.reset();
        _titleController.clear();
        _videoUrlController.clear();
        _orderController.clear();
        setState(() => _selectedCourseId = null);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add lecture: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
                  _buildSectionTitle(context, 'Course Information'),
                  const SizedBox(height: 16),
                  _buildCourseDropdown(context), // Pass context
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Lecture Details'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _titleController, label: 'Lecture Title', icon: Icons.title, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _videoUrlController,
                    label: 'Video URL',
                    icon: Icons.video_library,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (Uri.tryParse(v)?.isAbsolute != true) return 'Invalid URL';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _orderController, label: 'Lecture Order', icon: Icons.format_list_numbered, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
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

  Widget _buildCourseDropdown(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);

    // Admins see all courses. Sub-admins only see their assigned courses.
    Query query = FirebaseFirestore.instance.collection('course');
    if (userProvider.isSubAdmin) {
      final accessibleCourseIds = userProvider.accessibleCourseIds;
      if (accessibleCourseIds.isEmpty) {
        // This sub-admin has no courses, so show a message instead of the dropdown.
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'You have not been assigned any courses to manage.',
              style: TextStyle(color: theme.disabledColor),
            ),
          ),
        );
      }
      // Filter courses by the IDs the sub-admin has access to.
      query = query.where(FieldPath.documentId, whereIn: accessibleCourseIds);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: query.orderBy('title').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            if (snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No courses found.', textAlign: TextAlign.center),
              );
            }

            final courses = snapshot.data!.docs.map((doc) {
              final title = doc.get('title') ?? 'Untitled Course';
              return DropdownMenuItem(value: doc.id, child: Text(title));
            }).toList();

            return DropdownButtonFormField<String>(
              value: _selectedCourseId,
              items: courses,
              onChanged: (value) => setState(() => _selectedCourseId = value),
              decoration: const InputDecoration(labelText: 'Select Course', icon: Icon(Icons.school), border: InputBorder.none),
              validator: (v) => v == null ? 'Required' : null,
              isExpanded: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, icon: Icon(icon), border: InputBorder.none),
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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
      label: Text('Add Lecture', style: TextStyle(color: theme.colorScheme.onPrimary)),
      onPressed: _addLecture,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: theme.colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
    );
  }
}
