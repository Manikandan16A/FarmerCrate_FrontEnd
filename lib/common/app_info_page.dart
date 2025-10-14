import 'package:flutter/material.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoCard(
                      'App Information',
                      Icons.info_outline,
                      [
                        _buildInfoItem('Version', '1.0.0'),
                        _buildInfoItem('Build', '1'),
                        _buildInfoItem('Developer', 'Farmer Crate Team'),
                        _buildInfoItem('Release Date', '2024'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      'Privacy Policy',
                      Icons.privacy_tip_outlined,
                      'Learn how we protect your data',
                      () => _showPrivacyPolicy(context),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      'Help & Support',
                      Icons.help_outline,
                      'Get help and find answers',
                      () => _showHelpSupport(context),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      'Contact Us',
                      Icons.contact_support_outlined,
                      'Get in touch with our team',
                      () => _showContactUs(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade600,
            Colors.green.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.info,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Information',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'About Farmer Crate',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.green.shade700, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'At Farmer Crate, we are committed to protecting your privacy and ensuring the security of your personal information.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Information We Collect',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Personal information (name, email, phone number)\n• Location data for delivery purposes\n• Order history and preferences\n• Device information for app optimization',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'How We Use Your Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• To process and fulfill your orders\n• To provide customer support\n• To improve our services\n• To send important updates about your orders',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                'Help & Support',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 20),
              _buildFAQItem('How do I place an order?', 'Browse products, add to cart, and checkout with your preferred payment method.'),
              _buildFAQItem('How can I track my order?', 'Go to Order History to see real-time updates on your order status.'),
              _buildFAQItem('What payment methods do you accept?', 'We accept UPI, credit/debit cards, and cash on delivery.'),
              _buildFAQItem('How do I cancel an order?', 'You can cancel orders before they are processed in the Order History section.'),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
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