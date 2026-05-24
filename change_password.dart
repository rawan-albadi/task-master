import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  TextEditingController _currentPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Current Password'),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm New Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }



  void _changePassword() async {
    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (newPassword == confirmPassword) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          
          AuthCredential credential = EmailAuthProvider.credential(
              email: user.email!,
              password: currentPassword,
          );

          await user.reauthenticateWithCredential(credential);

          await user.updatePassword(newPassword);

          
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password changed successfully')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match')));
    }
  }
}
