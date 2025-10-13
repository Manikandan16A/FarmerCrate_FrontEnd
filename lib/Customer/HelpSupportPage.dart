import 'package:flutter/material.dart';
import 'FAQpage.dart';
import 'FeedbackPage.dart';

class HelpSupportPage extends StatelessWidget {
  final String? token;
  const HelpSupportPage({Key? key, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.green[600],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.question_answer_outlined, color: Colors.green[700]),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FAQPage(token: token))),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.feedback_outlined, color: Colors.green[700]),
              title: const Text('Feedback'),
              subtitle: const Text('Share feedback after delivery or order completion'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeedbackPage(token: token))),
            ),
          ),
        ],
      ),
    );
  }
}
