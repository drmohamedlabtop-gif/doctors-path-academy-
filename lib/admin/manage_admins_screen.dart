import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// =============================================
// ======== MANAGE ADMINS SCREEN
// =============================================
class ManageAdminsScreen extends StatelessWidget {
  const ManageAdminsScreen({super.key});

  void _navigateToAddEdit(BuildContext context, {QueryDocumentSnapshot? admin}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditAdminScreen(admin: admin)),
    );
  }

  Future<void> _removeAdminRole(BuildContext context, String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin Role'),
        content: Text('Are you sure you want to remove all admin privileges from $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'role': 'student',
          'permissions': FieldValue.delete(),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$userName is no longer an admin.'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to remove admin role: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['superAdmin', 'subAdmin']).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Admins Found'));
          }

          final admins = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8).copyWith(bottom: 80),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              return AdminCard(
                admin: admin,
                onEdit: () => _navigateToAddEdit(context, admin: admin),
                onDelete: () => _removeAdminRole(context, admin.id, admin['name'] ?? 'N/A'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(context),
        label: const Text('Add New Admin'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}

class AdminCard extends StatefulWidget {
  final QueryDocumentSnapshot admin;
  final VoidCallback onEdit, onDelete;
  const AdminCard({super.key, required this.admin, required this.onEdit, required this.onDelete});

  @override
  State<AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<AdminCard> {
  Future<Map<String, dynamic>>? _detailsFuture;
  bool? _isAccountEnabled;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchAdminDetails();
  }

  Future<Map<String, dynamic>> _fetchAdminDetails() async {
    final adminData = widget.admin.data() as Map<String, dynamic>;
    final permissions = adminData['permissions'] as Map<String, dynamic>? ?? {};
    final rawCourseIds = permissions['accessibleCourseIds'] as List<dynamic>?;
    final courseIds = rawCourseIds?.map((id) => id.toString()).toList() ?? <String>[];

    if (courseIds.isEmpty) {
      return {
        'phone': adminData['phone'] ?? 'N/A',
        'email': adminData['email'] ?? 'N/A',
        'courses': <String>[],
        'accountEnabled': adminData['accountEnabled'] ?? true,
      };
    }

    final coursesSnapshot = await FirebaseFirestore.instance
        .collection('course')
        .where(FieldPath.documentId, whereIn: courseIds)
        .get();
    
    final courseNames = coursesSnapshot.docs.map<String>((doc) {
      final data = doc.data();
      return (data as Map<String, dynamic>)['title']?.toString() ?? 'Untitled Course';
    }).toList();

    return {
      'phone': adminData['phone'] ?? 'N/A',
      'email': adminData['email'] ?? 'N/A',
      'courses': courseNames,
      'accountEnabled': adminData['accountEnabled'] ?? true,
    };
  }

  Future<void> _toggleAccountStatus(bool isEnabled) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.admin.id).update({
        'accountEnabled': isEnabled,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update account status: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminData = widget.admin.data() as Map<String, dynamic>;
    final role = adminData['role'] ?? 'N/A';
    final isSuperAdmin = role == 'superAdmin';
    final name = adminData['name'] ?? 'No Name';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSuperAdmin ? Colors.amber : theme.colorScheme.secondary,
                  child: Icon(isSuperAdmin ? Icons.star : Icons.shield, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(isSuperAdmin ? 'Super Admin' : 'Sub Admin', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(icon: Icon(Icons.edit, color: theme.colorScheme.primary), onPressed: widget.onEdit),
                if (!isSuperAdmin) IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: widget.onDelete),
              ],
            ),
            const Divider(height: 20),
            FutureBuilder<Map<String, dynamic>>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.only(top: 8.0), child: Center(child: LinearProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Text('Could not load details: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                if (!snapshot.hasData) {
                   return const Text('Could not load details.', style: TextStyle(color: Colors.red));
                }

                final details = snapshot.data!;
                final phone = details['phone'];
                final email = details['email'];
                final courses = details['courses'] as List<String>;
                final accountEnabled = details['accountEnabled'] as bool;

                 if (_isAccountEnabled == null) {
                  _isAccountEnabled = accountEnabled;
                } 


                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.email, size: 16), const SizedBox(width: 8), Text(email)]),
                    const SizedBox(height: 8),
                    Row(children: [const Icon(Icons.phone, size: 16), const SizedBox(width: 8), Text(phone)]),
                    const SizedBox(height: 8),
                    if (courses.isNotEmpty) ...[
                       Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school, size: 16), 
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(courses.join(', '), style: theme.textTheme.bodyMedium)
                          )
                        ]
                      )
                    ] else if (!isSuperAdmin) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school, size: 16), 
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('No courses assigned', style: theme.textTheme.bodySmall)
                          )
                        ]
                      )
                    ],
                    if (!isSuperAdmin) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Account Enabled'),
                          Switch(
                            value: _isAccountEnabled ?? true,
                            onChanged: (value) {
                               setState(() {
                                _isAccountEnabled = value;
                              });
                              _toggleAccountStatus(value);
                            },
                          ),
                        ],
                      ),
                    ]
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================
// ======== ADD/EDIT ADMIN SCREEN
// =============================================
class AddEditAdminScreen extends StatefulWidget {
  final QueryDocumentSnapshot? admin;
  const AddEditAdminScreen({super.key, this.admin});

  @override
  State<AddEditAdminScreen> createState() => _AddEditAdminScreenState();
}

class _AddEditAdminScreenState extends State<AddEditAdminScreen> {
  QueryDocumentSnapshot? _selectedUser;
  bool _isSuperAdmin = false;
  final Map<String, bool> _permissions = {
    'canViewCourses': false,
    'canManageUsers': false,
    'canAddLectures': false,
    'canAddCourses': false,
  };
  List<String> _accessibleCourseIds = [];
  bool _isSaving = false;

  late Future<List<QueryDocumentSnapshot>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = FirebaseFirestore.instance.collection('course').orderBy('title').get().then((s) => s.docs);
    if (widget.admin != null) {
      _selectedUser = widget.admin;
      final data = widget.admin!.data() as Map<String, dynamic>;
      _isSuperAdmin = data['role'] == 'superAdmin';
      final perms = data['permissions'] as Map<String, dynamic>? ?? {};
      _permissions.forEach((key, value) {
        if (perms.containsKey(key)) {
          _permissions[key] = perms[key];
        }
      });
      final rawIds = perms['accessibleCourseIds'] as List<dynamic>?;
      if (rawIds != null) {
        _accessibleCourseIds = rawIds.map((id) => id.toString()).toList();
      }
    }
  }

  Future<void> _saveAdmin() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a user.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final role = _isSuperAdmin ? 'superAdmin' : 'subAdmin';
      final finalPermissions = _isSuperAdmin ? {} : {
        ..._permissions,
        'accessibleCourseIds': _accessibleCourseIds,
      };

      await FirebaseFirestore.instance.collection('users').doc(_selectedUser!.id).update({
        'role': role,
        'permissions': finalPermissions,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Permissions updated for ${_selectedUser!['name']}.'),
        backgroundColor: Colors.green,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.admin == null ? 'Add Admin' : 'Edit Permissions'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                if (widget.admin == null && _selectedUser == null)
                  _buildUserSearch()
                else if (_selectedUser != null)
                  _buildUserInfoCard(_selectedUser!, theme),
                if (_selectedUser != null || widget.admin != null) ...[
                  const SizedBox(height: 24),
                  _buildSuperAdminCard(theme),
                  if (!_isSuperAdmin) ...[
                    const SizedBox(height: 16),
                    _buildSubAdminPermissionsCard(theme),
                  ]
                ]
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAdmin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(QueryDocumentSnapshot user, ThemeData theme) {
    final name = user['name'] as String? ?? 'No Name';
    final email = user['email'] as String? ?? 'No Email';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(radius: 24, child: Text(name.isNotEmpty ? name[0] : '?')),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
                ],
              ),
            ),
            if (widget.admin == null)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                tooltip: 'Select a different user',
                onPressed: () => setState(() => _selectedUser = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearch() {
    return Autocomplete<QueryDocumentSnapshot>(
      optionsBuilder: (text) async {
        if (text.text.isEmpty) return const Iterable.empty();
        final s = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isGreaterThanOrEqualTo: text.text)
            .where('email', isLessThanOrEqualTo: '${text.text}')
            .limit(10)
            .get();
        return s.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final role = data?['role'] as String?;
          return role == 'student' || role == null;
        });
      },
      displayStringForOption: (o) => o['email'] ?? '',
      onSelected: (s) => setState(() => _selectedUser = s),
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        onEditingComplete: onEditingComplete,
        decoration: const InputDecoration(
          labelText: 'Find user by email',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildSuperAdminCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text('Super Admin', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('Grants all permissions automatically.', style: theme.textTheme.bodySmall),
        value: _isSuperAdmin,
        onChanged: (val) => setState(() => _isSuperAdmin = val),
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSubAdminPermissionsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Sub-Admin Permissions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const Divider(indent: 16, endIndent: 16),
          _buildCourseMultiSelect(theme),
          _buildPermissionSwitch('canViewCourses', 'View Courses', 'Can view assigned courses.', theme),
          _buildPermissionSwitch('canManageUsers', 'Manage Course Users', 'Can add/remove users from their accessible courses.', theme),
          _buildPermissionSwitch('canAddLectures', 'Add Lectures', 'Can add new lectures to accessible courses.', theme),
          _buildPermissionSwitch('canAddCourses', 'Add New Courses', 'Can create brand new courses.', theme),
        ],
      ),
    );
  }

  Widget _buildCourseMultiSelect(ThemeData theme) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text("Loading courses...")));
        }
        final allCourses = snapshot.data!;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: const Text('Accessible Courses'),
          subtitle: Text(_accessibleCourseIds.isEmpty ? 'None Selected' : '${_accessibleCourseIds.length} course(s) selected', style: theme.textTheme.bodySmall),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () async {
            final selected = await showDialog<List<String>>(
              context: context,
              builder: (context) {
                final tempSelected = List<String>.from(_accessibleCourseIds);
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      title: const Text('Select Accessible Courses'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: allCourses.length,
                          itemBuilder: (context, index) {
                            final course = allCourses[index];
                            final isSelected = tempSelected.contains(course.id);
                            return CheckboxListTile(
                              title: Text(course['title'] ?? 'No Title'),
                              value: isSelected,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    tempSelected.add(course.id);
                                  } else {
                                    tempSelected.remove(course.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.of(context).pop(tempSelected), child: const Text('Confirm')),
                      ],
                    );
                  },
                );
              },
            );
            if (selected != null) {
              setState(() => _accessibleCourseIds = selected);
            }
          },
        );
      },
    );
  }

  Widget _buildPermissionSwitch(String key, String title, String subtitle, ThemeData theme) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      value: _permissions[key] ?? false,
      onChanged: (val) => setState(() => _permissions[key] = val),
      activeColor: theme.colorScheme.primary,
    );
  }
}
