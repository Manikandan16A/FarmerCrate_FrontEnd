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
}