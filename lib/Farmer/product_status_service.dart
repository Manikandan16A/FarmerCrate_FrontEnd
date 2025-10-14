import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductStatusService {
  static const String baseUrl = 'https://farmercrate.onrender.com/api';

  static Future<List<dynamic>> getProductsByStatus(String token, String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/status/$status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching products by status: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getAcceptedProducts(String token) async {
    return getProductsByStatus(token, 'accepted');
  }

  static Future<List<dynamic>> getRejectedProducts(String token) async {
    return getProductsByStatus(token, 'rejected');
  }
}
