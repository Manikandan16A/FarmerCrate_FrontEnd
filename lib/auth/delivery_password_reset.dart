import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../delivery/delivery_dashboard.dart';

class DeliveryPasswordResetPage extends StatefulWidget {
  final String tempToken;
  final int userId;

  const DeliveryPasswordResetPage({
    Key? key,
    required this.tempToken,
    required this.userId,
  }) : super(key: key);

  @override
  _DeliveryPasswordResetPageState createState() => _DeliveryPasswordResetPageState();
}

class _DeliveryPasswordResetPageState extends State<DeliveryPasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _confirmPasswordController.addListener(_validatePasswordMatch);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordMatch() {
    setState(() {
      _passwordsMatch = _newPasswordController.text.isNotEmpty &&
          _newPasswordController.text == _confirmPasswordController.text &&
          _newPasswordController.text.length >= 8;
    });
  }

  Future<void> _handleSubmit() async {
    print('\n🔘 BUTTON CLICKED - Starting password reset...');
    if (_formKey.currentState!.validate()) {
      print('✓ Form validation passed');
      print('\n========== PASSWORD RESET ==========');
      print('User ID: ${widget.userId}');
      print('Token: ${widget.tempToken.substring(0, 20)}...');
      print('Password Length: ${_newPasswordController.text.length}');
      setState(() => _isLoading = true);
      print('Loading state set to true');

      try {
        final payload = {
          'deliveryPersonId': widget.userId,
          'newPassword': _newPasswordController.text,
          'tempToken': widget.tempToken,
        };
        print('Payload: ${jsonEncode(payload)}');
        
        final response = await http.post(
          Uri.parse('https://farmercrate.onrender.com/api/auth/delivery-person-first-login-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
        setState(() => _isLoading = false);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          print('✓ Success');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password set successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDashboard(
                user: responseData['user'],
                token: responseData['token'],
              ),
            ),
          );
        } else {
          print('✗ Failed');
          String msg = 'Failed to set password.';
          try {
            final err = jsonDecode(response.body);
            msg = err['message'] ?? err['error'] ?? msg;
            print('Error details: $err');
          } catch (e) {
            print('Could not parse error: $e');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
        print('===================================\n');
      } catch (e, s) {
        print('✗ Error: $e');
        print('Stack: $s');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF81C784)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                    ),
                    child: Icon(Icons.delivery_dining, size: 60, color: Color(0xFF2E7D32)),
                  ),
                  SizedBox(height: 24),
                  Text('Welcome, Delivery Partner!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Set your new password to continue', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  SizedBox(height: 32),
                  Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, 15))],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          SizedBox(height: 24),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: !_isNewPasswordVisible,
                            validator: (v) => v == null || v.isEmpty ? 'Enter password' : v.length < 8 ? 'Min 8 characters' : null,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF4CAF50)),
                              suffixIcon: IconButton(
                                icon: Icon(_isNewPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2)),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            validator: (v) => !_passwordsMatch ? 'Passwords do not match' : null,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF4CAF50)),
                              suffixIcon: IconButton(
                                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2)),
                            ),
                          ),
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_passwordsMatch) ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _passwordsMatch ? Color(0xFF4CAF50) : Colors.grey,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : Text('Set Password & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
