import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String searchQuery = '';
  String selectedRole = 'All';

  final List<String> roles = ['All', 'admin', 'user'];

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF512DA8),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButton<String>(
                  value: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  items: roles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role == 'All' ? 'All Roles' : role),
                    );
                  }).toList(),
                  underline: Container(),
                  dropdownColor: Colors.white,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  icon: const Icon(Icons.arrow_drop_down),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // User List
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = data['email']?.toLowerCase() ?? '';
                  final role = data['role'] ?? '';
                  final matchesSearch = email.contains(searchQuery);
                  final matchesRole = selectedRole == 'All' || role == selectedRole;
                  return matchesSearch && matchesRole;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final userData = doc.data() as Map<String, dynamic>;
                    final email = userData['email'] ?? 'No Email';
                    final role = userData['role'] ?? 'No Role';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, size: 30, color: Colors.deepPurple),
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Role: $role'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit Role',
                              onPressed: () async {
                                final newRole = await _showEditRoleDialog(context, role);
                                if (newRole != null && newRole != role) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(doc.id)
                                      .update({'role': newRole});
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete User',
                              onPressed: () async {
                                final confirm = await _confirmDelete(context);
                                if (confirm) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(doc.id)
                                      .delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Feedback Section
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('User Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('feedback').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No feedback submitted.'));
                }

                final feedbacks = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final doc = feedbacks[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final feedbackText = data['text'] ?? 'No Content';
                    final timestamp = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate().toString()
                        : 'No Time';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.feedback, color: Colors.deepPurple),
                        title: Text(feedbackText),
                        subtitle: Text('Submitted on: $timestamp'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this user?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _showEditRoleDialog(BuildContext context, String currentRole) async {
    final controller = TextEditingController(text: currentRole);
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Role'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Role'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }
}
