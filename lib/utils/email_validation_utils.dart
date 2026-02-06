import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailValidationUtils {
  static const String baseUrl = 'https://farmercrate.onrender.com';

  /// Check if email exists across all user types
  static Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'exists': false};
      }
    } catch (e) {
      print('Error checking email: $e');
      return {'exists': false};
    }
  }

  /// Show email conflict dialog
  static void showEmailConflictDialog(
    BuildContext context, 
    String existingRole, 
    String requestedRole,
    {VoidCallback? onLoginPressed}
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Email Already Registered'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This email is already registered as a $existingRole.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                requestedRole != null 
                  ? 'You cannot sign up as a $requestedRole with this email. Please use a different email or sign in with your existing account.'
                  : 'Please use a different email or sign in with your existing account.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
            if (onLoginPressed != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onLoginPressed();
                },
                child: Text('Go to Login'),
              ),
          ],
        );
      },
    );
  }

  /// Validate email format and uniqueness
  static String? validateEmailUniqueness(String? value, {String? excludeRole}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(value)) {
      return 'Please enter a valid Gmail address (@gmail.com)';
    }
    return null;
  }
}