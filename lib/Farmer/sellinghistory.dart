import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class PostDetailsModal extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String userName;
  final String userLocation;
  final String time;
  final String price;
  final String contact;

  const PostDetailsModal({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.userName,
    required this.userLocation,
    required this.time,
    required this.price,
    required this.contact,
  });

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty || text == 'No Contact') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No valid contact information to copy'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text(
                      'No Image Available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                title.isNotEmpty ? title : 'No Title',
                style: GoogleFonts.openSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  price.isNotEmpty ? price : 'N/A',
                  style: GoogleFonts.openSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Seller Information',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: GoogleFonts.openSans(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userName.isNotEmpty ? userName : 'Unknown Seller',
                              style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            userLocation.isNotEmpty ? '$userLocation • $time' : 'Unknown Location',
                            style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  description.isNotEmpty ? description : 'No description available',
                  style: GoogleFonts.openSans(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Contact Information',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        contact.isNotEmpty ? contact : 'No Contact',
                        style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(context, contact),
                      icon: Icon(Icons.copy, color: Colors.green[600], size: 20),
                      tooltip: 'Copy phone number',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling feature will be implemented')),
                    );
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Call Seller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}