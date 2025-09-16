import 'package:flutter/material.dart';
import 'navigation_utils.dart';

class FAQPage extends StatefulWidget {
  final String? token;
  const FAQPage({super.key, this.token});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I use this app?',
      'answer': 'This app helps farmers manage their products and customers.'
    },
    {
      'question': 'Where can I see my orders?',
      'answer': 'Orders can be viewed in the cart section.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: CustomerNavigationUtils.buildCustomerDrawer(
        parentContext: context,
        token: widget.token,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                faqs[index]['question']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(faqs[index]['answer']!),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomerNavigationUtils.buildCustomerBottomNav(
        currentIndex: 3, // FAQ is index 3
        onTap: (index) => CustomerNavigationUtils.handleNavigation(index, context, widget.token),
      ),
    );
  }
}