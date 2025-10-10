import 'dart:convert';
import 'package:http/http.dart' as http;
import 'qr_generator.dart';

class OrderService {
  static const String baseUrl = 'https://farmercrate.onrender.com/api';

  static Future<Map<String, dynamic>?> createOrder(Map<String, dynamic> orderData) async {
    try {
      // First create the order
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Generate QR code with order details
          final qrImageUrl = await QRGenerator.generateOrderQR(responseData['order_data']);
          
          if (qrImageUrl != null) {
            // Update the order with QR image URL
            await _updateOrderQRImage(responseData['order_data']['qr_code'], qrImageUrl);
            
            // Add QR image URL to response
            responseData['order_data']['qr_image_url'] = qrImageUrl;
          }
          
          return responseData;
        }
      }
      return null;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  static Future<void> _updateOrderQRImage(String qrCode, String imageUrl) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/orders/qr-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'qr_code': qrCode,
          'qr_image_url': imageUrl,
        }),
      );
    } catch (e) {
      print('Error updating QR image: $e');
    }
  }
}