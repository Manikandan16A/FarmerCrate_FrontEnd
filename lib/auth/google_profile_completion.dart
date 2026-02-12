import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Customer/customerhomepage.dart';
import '../Farmer/homepage.dart';
import '../Transpoter/transporter_dashboard.dart';
import '../utils/snackbar_utils.dart';

class GoogleProfileCompletionPage extends StatefulWidget {
  final String email;
  final String name;
  final String googleId;
  final String role;

  const GoogleProfileCompletionPage({
    Key? key,
    required this.email,
    required this.name,
    required this.googleId,
    required this.role,
  }) : super(key: key);

  @override
  _GoogleProfileCompletionPageState createState() => _GoogleProfileCompletionPageState();
}

class _GoogleProfileCompletionPageState extends State<GoogleProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _zoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _zoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    print('[PROFILE] Starting profile completion...');
    print('[PROFILE] Email: ${widget.email}');
    print('[PROFILE] Name: ${widget.name}');
    print('[PROFILE] Role: ${widget.role}');
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final requestBody = {
          'email': widget.email,
          'name': widget.name,
          'googleId': widget.googleId,
          'role': widget.role,
          'mobile_number': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'zone': _zoneController.text.trim(),
          'state': _stateController.text.trim(),
          'district': _districtController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
        };
        
        print('[PROFILE] Request body: $requestBody');
        
        final response = await http.put(
          Uri.parse('https://farmercrate.onrender.com/api/auth/google-complete-profile'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        print('[PROFILE] Response status: ${response.statusCode}');
        print('[PROFILE] Response body: ${response.body}');

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final token = data['token'];
          final user = data['user'];
          
          print('[PROFILE] Token received: ${token?.substring(0, 20)}...');
          print('[PROFILE] User data: $user');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('auth_token', token);
          await prefs.setString('role', widget.role);
          await prefs.setInt('user_id', user['id']);
          await prefs.setString('username', widget.name);
          await prefs.setString('email', widget.email);
          await prefs.setBool('is_logged_in', true);
          
          print('[PROFILE] Navigating to ${widget.role} home page...');

          if (widget.role == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CustomerHomePage(token: token)),
            );
          } else if (widget.role == 'transporter') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TransporterDashboard(token: token)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FarmersHomePage(token: token)),
            );
          }
        } else if (response.statusCode == 400) {
          final data = jsonDecode(response.body);
          print('[PROFILE ERROR] User already exists: ${data['message']}');
          SnackBarUtils.showError(context, 'User already exists. Please login instead.');
        } else {
          print('[PROFILE ERROR] Failed with status ${response.statusCode}');
          SnackBarUtils.showError(context, 'Failed to complete profile. Please try again.');
        }
      } catch (e, stackTrace) {
        print('[PROFILE ERROR] Exception: $e');
        print('[PROFILE ERROR] Stack trace: $stackTrace');
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, 'Error: $e');
      }
    } else {
      print('[PROFILE] Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[PROFILE] Building page for ${widget.name} (${widget.role})');
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.name}!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please complete your profile to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  prefixText: '+91 ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 100) return 'Age must be 18-100';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _zoneController,
                decoration: InputDecoration(
                  labelText: 'Zone',
                  prefixIcon: Icon(Icons.map),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Complete Profile', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
