import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({Key? key}) : super(key: key);

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
                    _buildFAQItem(
                      'How do I place an order?',
                      'Browse products, select items, add to cart, and proceed to checkout. Choose your payment method and confirm your order.',
                    ),
                    _buildFAQItem(
                      'How can I track my order?',
                      'Go to Order History to see real-time updates on your order status. You\'ll receive notifications for each status change.',
                    ),
                    _buildFAQItem(
                      'What payment methods do you accept?',
                      'We accept UPI, credit/debit cards, net banking, and cash on delivery for your convenience.',
                    ),
                    _buildFAQItem(
                      'How do I cancel an order?',
                      'You can cancel orders before they are processed in the Order History section. Once processed, cancellation may not be possible.',
                    ),
                    _buildFAQItem(
                      'What is your delivery time?',
                      'Delivery typically takes 2-5 business days depending on your location and product availability.',
                    ),
                    _buildFAQItem(
                      'Do you deliver to my area?',
                      'We deliver to most areas. Enter your pincode during checkout to check delivery availability.',
                    ),
                    _buildFAQItem(
                      'What if I receive damaged products?',
                      'Contact our support team immediately with photos of the damaged items. We\'ll arrange for replacement or refund.',
                    ),
                    _buildFAQItem(
                      'How do I return a product?',
                      'Returns are accepted within 7 days of delivery. Contact support to initiate the return process.',
                    ),
                    _buildFAQItem(
                      'Is my personal information secure?',
                      'Yes, we use industry-standard encryption to protect your personal and payment information.',
                    ),
                    _buildFAQItem(
                      'How do I contact customer support?',
                      'You can reach us through the Contact Us section, call our helpline, or email support@farmercrate.com.',
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
                    Icons.help_outline,
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
                        'FAQ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Frequently Asked Questions',
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

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconColor: Colors.green.shade700,
        collapsedIconColor: Colors.green.shade700,
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}