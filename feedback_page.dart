import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      // Get the current time
      final timestamp = Timestamp.now();
      
      // Send the feedback to Firestore
      await FirebaseFirestore.instance.collection('feedback').add({
        'text': _feedbackController.text,
        'timestamp': timestamp,
      });

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
      );

      // Clear the input field
      _feedbackController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'We value your feedback!',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your feedback here',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Feedback cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitFeedback,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
