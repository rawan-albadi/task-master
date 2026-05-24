import 'package:flutter/material.dart';
import 'change_password.dart';
import 'change_name.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'WelcomePage.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
 
  double fontSize = 16.0;
  bool receiveAlerts = true;


  void _showPlaceholderDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(fontSize: fontSize)),
        content: Text(title, style: TextStyle(fontSize: fontSize)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontSize: fontSize)),
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut(); 
    _showPlaceholderDialog(context, "Signed Out");

    Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (context) =>WelcomePage()),
);
  } catch (e) {
    
    _showPlaceholderDialog(context, "Error signing out: $e");
  }
}

  void _syncAccount() {
    _showPlaceholderDialog(context, "Account Synced");
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: fontSize);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: textStyle),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Account',
              style: textStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text('Sync Account', style: textStyle),
            onTap: _syncAccount,
          ),
          ListTile(
  leading: const Icon(Icons.logout),
  title: Text('Sign Out', style: textStyle),
  onTap: () => _signOut(context),
),
          SwitchListTile(
  secondary: const Icon(Icons.notifications),
  title: Text('Receive Alerts', style: textStyle),
  value: receiveAlerts,
  onChanged: (value) {
    setState(() => receiveAlerts = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receiveAlerts ? 'Alerts Enabled' : 'Alerts Disabled',
          style: textStyle.copyWith(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  },
),

          
         
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Accessibility',
              style: textStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text('Font Size (${fontSize.toInt()})', style: textStyle),
            subtitle: Slider(
              value: fontSize,
              min: 12,
              max: 24,
              divisions: 6,
              label: fontSize.toInt().toString(),
              onChanged: (value) => setState(() => fontSize = value),
            ),
          ),
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  ChangePasswordScreen(),
                ),
              );
            },
          ),
          ListTile(
  leading: Icon(Icons.person),
  title: Text('Change Name'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangeNameScreen()),
    );
  },
),
        ],
      ),
    );
  }
}
