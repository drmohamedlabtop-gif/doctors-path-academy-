import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEditCourseScreen extends StatefulWidget {
  final DocumentSnapshot? course;

  const AddEditCourseScreen({super.key, this.course});

  @override
  State<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends State<AddEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _thumbnailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final courseData = widget.course?.data() as Map<String, dynamic>?;
    _titleController = TextEditingController(text: courseData?['title'] ?? '');
    _descriptionController = TextEditingController(text: courseData?['description'] ?? '');
    _thumbnailController = TextEditingController(text: courseData?['thumbnailUrl'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final courseData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'thumbnailUrl': _thumbnailController.text,
      };

      try {
        if (widget.course == null) {
          // Add new course
          await FirebaseFirestore.instance.collection('course').add(courseData);
        } else {
          // Update existing course
          await FirebaseFirestore.instance.collection('course').doc(widget.course!.id).update(courseData);
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if(mounted) {
            setState(() {
                _isLoading = false;
            });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? 'Add Course' : 'Edit Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                 validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              TextFormField(
                controller: _thumbnailController,
                decoration: const InputDecoration(labelText: 'Thumbnail URL'),
                 validator: (value) => value!.isEmpty ? 'Please enter a thumbnail URL' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveCourse,
                      child: const Text('Save Course'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}