import 'dart:convert';
import 'package:http/http.dart' as http;

class TransporterOrderService {
  static const String baseUrl = 'https://farmercrate.onrender.com/api/transporters';

  static Future<Map<String, dynamic>> getActiveShipments(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/active'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? []};
      }
      return {'success': false, 'error': 'Failed to fetch active shipments'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> trackOrder(String token, String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/track'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'error': 'Failed to track order'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
