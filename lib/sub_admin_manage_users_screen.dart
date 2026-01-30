
import 'package:doctors_path_academy/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctors_path_academy/sub_admin_user_card.dart';

class SubAdminUserManagementScreen extends StatefulWidget {
  const SubAdminUserManagementScreen({super.key});

  @override
  State<SubAdminUserManagementScreen> createState() => _SubAdminUserManagementScreenState();
}

class _SubAdminUserManagementScreenState extends State<SubAdminUserManagementScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _searchTerm = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!userProvider.hasPermission('canManageUsers')) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'You do not have permission to manage users.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildUsersList(userProvider)),
      ],
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
            hintText: 'Search by email or name...',
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

  Widget _buildUsersList(UserProvider userProvider) {
    // Base query for users
    Query query = FirebaseFirestore.instance.collection('users').orderBy('name');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading users: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        // Filter users based on search term
        final filteredUsers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          return name.contains(_searchTerm) || email.contains(_searchTerm);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text('No users match your search.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 80),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return SubAdminUserCard(key: ValueKey(user.id), user: user, userProvider: userProvider);
          },
        );
      },
    );
  }
}
