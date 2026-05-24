import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'settings_screen.dart';
import 'feedback_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  late File _imageFile;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      String imageUrl = pickedFile.path;

     
      await user?.updatePhotoURL(imageUrl);

      
      FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'photoURL': imageUrl,
      });

      
      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return FutureBuilder(
    future: FirebaseAuth.instance.currentUser?.reload().then((_) {
      return FirebaseAuth.instance.currentUser;
    }),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      User? updatedUser = snapshot.data as User?;

      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                updatedUser?.displayName ?? 'No Name',
                style: const TextStyle(color: Colors.black),
              ),
              accountEmail: Text(
                updatedUser?.email ?? 'No Email',
                style: const TextStyle(color: Colors.black),
              ),
              currentAccountPicture: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  backgroundImage: const AssetImage('assets/p3.png') as ImageProvider,
                ),
              ),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/drawer_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
      leading: const Icon(Icons.question_answer),
      title: const Text('Feedback'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeedbackPage()),
        );
      },
    ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Go back'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
}

