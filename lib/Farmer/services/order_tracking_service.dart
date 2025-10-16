import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_tracking.dart';

class OrderTrackingService {
  static const String baseUrl = 'https://farmercrate.onrender.com/api/farmers';

  static Future<OrderTrackingResponse?> getOrderUpdates(String orderId, String? token) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/$orderId/updates');
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('Fetching order updates for order: $orderId');
      print('Request URL: $uri');

      final response = await http.get(uri, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return OrderTrackingResponse.fromJson(responseData);
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching order updates: $e');
      return null;
    }
  }

  static Future<OrderTrackingFullResponse?> getOrderTrack(String orderId, String? token) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/$orderId/track');
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('Fetching order track for order: $orderId');
      print('Request URL: $uri');

      final response = await http.get(uri, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return OrderTrackingFullResponse.fromJson(responseData);
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching order track: $e');
      return null;
    }
  }

  static Future<ActiveOrdersResponse?> getActiveOrders(String? token) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/active');
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('Fetching active orders');
      print('Request URL: $uri');

      final response = await http.get(uri, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ActiveOrdersResponse.fromJson(responseData);
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching active orders: $e');
      return null;
    }
  }

  /// Get all active shipments for farmer (matching customer service pattern)
  static Future<Map<String, dynamic>> getActiveShipments(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/active');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return {
            'success': true,
            'data': body['data'] ?? [],
            'message': body['message'] ?? 'Active shipments fetched successfully',
          };
        } else {
          return {
            'success': false,
            'error': body['message'] ?? 'Failed to fetch active shipments',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch active shipments (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching active shipments: $e',
      };
    }
  }

  /// Track specific order with detailed steps (matching customer service pattern)
  static Future<Map<String, dynamic>> trackOrder(String token, String orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/$orderId/track');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return {
            'success': true,
            'data': body['data'] ?? {},
            'message': body['message'] ?? 'Order tracking data fetched successfully',
          };
        } else {
          return {
            'success': false,
            'error': body['message'] ?? 'Failed to fetch order tracking data',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch order tracking data (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching order tracking data: $e',
      };
    }
  }
}