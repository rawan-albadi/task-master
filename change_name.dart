import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangeNameScreen extends StatefulWidget {
  @override
  _ChangeNameScreenState createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  TextEditingController _nameController = TextEditingController();
  String currentName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  void _loadCurrentName() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (doc.exists && doc.data()!.containsKey('name')) {
      setState(() {
        currentName = doc['name'];
      });
    } else {
      setState(() {
        currentName = "No name set";
      });
    }
  }

  void _changeName() async {
  final newName = _nameController.text.trim();
  if (newName.isNotEmpty) {
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;

    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'name': newName});

    
    await user.updateDisplayName(newName);

    setState(() {
      currentName = newName;
      _nameController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Name changed successfully')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Current Name: $currentName'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Enter New Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changeName,
              child: const Text('Change Name'),
            ),
          ],
        ),
      ),
    );
  }
}
