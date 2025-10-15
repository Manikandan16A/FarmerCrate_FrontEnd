import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ProductEdit.dart';
import '../utils/notification_helper.dart';

class FarmerProductDetailPage extends StatefulWidget {
  final String productId;
  final String name;
  final String price;
  final String description;
  final String? imageUrl;
  final int quantity;
  final String? token;
  final String? category;
  final DateTime? harvestDate;
  final DateTime? expiryDate;
  final String? grade;

  const FarmerProductDetailPage({
    Key? key,
    required this.productId,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,
    required this.quantity,
    this.token,
    this.category,
    this.harvestDate,
    this.expiryDate,
    this.grade,
  }) : super(key: key);

  @override
  State<FarmerProductDetailPage> createState() => _FarmerProductDetailPageState();
}

class _FarmerProductDetailPageState extends State<FarmerProductDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isImageZoomed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getStockStatus() {
    if (widget.expiryDate != null) {
      final daysUntilExpiry = widget.expiryDate!.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 3 && daysUntilExpiry >= 0) return 'Near Expiry';
    }
    if (widget.quantity == 0) return 'Out of Stock';
    if (widget.quantity < 10) return 'Low Stock';
    return 'In Stock';
  }

  Color _getStockColor() {
    final status = _getStockStatus();
    if (status == 'Near Expiry') return Colors.orange;
    if (widget.quantity == 0) return Colors.red;
    if (widget.quantity < 10) return Colors.orange;
    return Colors.green;
  }

  IconData _getStockIcon() {
    final status = _getStockStatus();
    if (status == 'Near Expiry') return Icons.access_time;
    if (widget.quantity == 0) return Icons.cancel;
    if (widget.quantity < 10) return Icons.warning;
    return Icons.check_circle;
  }

  double _getTotalValue() {
    final priceValue = double.tryParse(widget.price.replaceAll('₹', '').trim()) ?? 0;
    return priceValue * widget.quantity;
  }

  List<String> _getAllImageUrls() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) return [];
    
    print('Raw imageUrl: ${widget.imageUrl}');
    
    List<String> urls = [];
    if (widget.imageUrl!.contains('|||')) {
      urls = widget.imageUrl!.split('|||').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (widget.imageUrl!.contains(',https://') || widget.imageUrl!.contains(',http://')) {
      urls = widget.imageUrl!.split(RegExp(r',(?=https?://)')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else {
      urls = [widget.imageUrl!.trim()];
    }
    
    print('Parsed ${urls.length} image URLs:');
    for (int i = 0; i < urls.length; i++) {
      print('Image $i: ${urls[i]}');
    }
    
    return urls;
  }

  void _showImageZoom(String imageUrl) {
    setState(() => _isImageZoomed = true);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() => _isImageZoomed = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Back to My Products', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[100],
              child: _getAllImageUrls().isEmpty
                  ? Center(child: Icon(Icons.image, size: 80, color: Colors.grey[400]))
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: _getAllImageUrls().length,
                          itemBuilder: (context, index) {
                            final imageUrl = _getAllImageUrls()[index];
                            return GestureDetector(
                              onTap: () => _showImageZoom(imageUrl),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 80, color: Colors.grey[400]),
                                        SizedBox(height: 8),
                                        Text('Image not available', style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        if (_getAllImageUrls().length > 1)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${_getAllImageUrls().length}',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (_getAllImageUrls().length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _getAllImageUrls().length,
                                (index) => AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentImageIndex == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index ? Colors.green[600] : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Tap to zoom', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStockColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStockColor(), width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(_getStockIcon(), color: _getStockColor(), size: 18),
                            SizedBox(width: 6),
                            Text(
                              _getStockStatus(),
                              style: TextStyle(color: _getStockColor(), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (widget.category != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🧺 ${widget.category}',
                        style: TextStyle(color: Colors.green[700], fontSize: 14),
                      ),
                    ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        widget.price,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green[700]),
                      ),
                      Text(' /kg', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 Quick Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInsightCard('Sold this week', '12 kg', Icons.trending_up, Colors.blue)),
                      SizedBox(width: 12),
                      Expanded(child: _buildInsightCard('Earnings', '₹600', Icons.currency_rupee, Colors.green)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInsightCard('Avg Rating', '4.5 ⭐', Icons.star, Colors.orange)),
                      SizedBox(width: 12),
                      Expanded(child: _buildInsightCard('Total Value', '₹${_getTotalValue().toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.purple)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📦 Product Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _buildInfoCard('Available Quantity', '${widget.quantity} kg', Icons.inventory),
                  SizedBox(height: 12),
                  if (widget.harvestDate != null)
                    _buildInfoCard('Harvest Date', DateFormat('dd MMM yyyy').format(widget.harvestDate!), Icons.calendar_today),
                  if (widget.harvestDate != null) SizedBox(height: 12),
                  if (widget.expiryDate != null)
                    _buildInfoCard('Expiry Date', DateFormat('dd MMM yyyy').format(widget.expiryDate!), Icons.event_busy),
                  if (widget.expiryDate != null) SizedBox(height: 12),
                  if (widget.grade != null)
                    _buildInfoCard('Quality Grade', widget.grade!, Icons.grade),
                  if (widget.grade != null) SizedBox(height: 12),
                  _buildInfoCard('Description', widget.description, Icons.description),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🧰 Product Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildActionButton('Edit', Icons.edit, Colors.green[600]!, _navigateToEdit)),
                      SizedBox(width: 12),
                      Expanded(child: _buildActionButton('Delete', Icons.delete, Colors.red[600]!, _confirmDelete)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green[700], size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  void _navigateToEdit() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FarmerProductsPage(token: widget.token),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            SizedBox(width: 8),
            Text('Delete Product?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${widget.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    try {
      final uri = Uri.parse('https://farmercrate.onrender.com/api/products/${widget.productId}');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        NotificationHelper.showSuccess(context, 'Product deleted successfully');
        Navigator.pop(context);
      } else {
        NotificationHelper.showError(context, 'Failed to delete product');
      }
    } catch (e) {
      NotificationHelper.showError(context, 'Network error: $e');
    }
  }
}
