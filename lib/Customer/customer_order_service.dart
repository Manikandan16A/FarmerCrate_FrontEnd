import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerOrderService {
  static const String baseUrl = 'https://farmercrate.onrender.com/api';

  /// Get all active shipments for customer
  static Future<Map<String, dynamic>> getActiveShipments(String token) async {
    try {
      // Debug: Log token info (without exposing the full token)
      print('DEBUG: Token length: ${token.length}, starts with: ${token.substring(0, 10)}...');
      
      final uri = Uri.parse('$baseUrl/orders/active');
      print('DEBUG: Making request to: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
      
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

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
        print('DEBUG: Failed with status ${response.statusCode}, body: ${response.body}');
        return {
          'success': false,
          'error': 'Failed to fetch active shipments (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching active shipments: $e',
      };
    }
  }

  /// Track specific order with detailed steps
  static Future<Map<String, dynamic>> trackOrder(String token, String orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/$orderId/track');
      print('DEBUG: Tracking order at: $uri');
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

  /// Get real-time tracking updates for specific order
  static Future<Map<String, dynamic>> getOrderUpdates(String token, String orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/$orderId/updates');
      print('DEBUG: Getting order updates from: $uri');
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
            'message': body['message'] ?? 'Order updates fetched successfully',
          };
        } else {
          return {
            'success': false,
            'error': body['message'] ?? 'Failed to fetch order updates',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch order updates (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching order updates: $e',
      };
    }
  }

  /// Get all orders for customer (existing functionality)
  static Future<Map<String, dynamic>> getCustomerOrders(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/orders');
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
            'message': body['message'] ?? 'Orders fetched successfully',
          };
        } else {
          return {
            'success': false,
            'error': body['message'] ?? 'Failed to fetch orders',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch orders (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching orders: $e',
      };
    }
  }
}