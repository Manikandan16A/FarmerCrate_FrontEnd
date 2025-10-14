import 'package:flutter/material.dart';
import 'faq_page.dart';
import 'feedback_page.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQPage())),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.feedback_outlined, color: Colors.green[700]),
              title: const Text('Feedback'),
              subtitle: const Text('Share feedback after delivery or order completion'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackPage())),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.contact_support_outlined, color: Colors.green[700]),
              title: const Text('Contact Us'),
              subtitle: const Text('Get in touch with our team'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showContactUs(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 20),
              _buildContactItem(Icons.phone, 'Phone', '+91 9876543210'),
              _buildContactItem(Icons.email, 'Email', 'support@farmercrate.com'),
              _buildContactItem(Icons.location_on, 'Address', '123 Farm Street, Agriculture City, India'),
              _buildContactItem(Icons.access_time, 'Business Hours', 'Mon-Sat: 9:00 AM - 6:00 PM'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
      ),
    );
  }
}