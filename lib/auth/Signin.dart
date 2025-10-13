import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Admin/requstaccept.dart';
import '../Customer/customerhomepage.dart';
import '../Farmer/homepage.dart';
import '../Transpoter/transporter_dashboard.dart';
import '../delivery/delivery_dashboard.dart';
import 'Forget.dart';
import 'Signup.dart';
import 'customerFTL.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://farmercrate.onrender.com/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text.trim(),
            'password': _passwordController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          // Check if OTP verification is required for first-time customer login
          if (responseData['requiresOTP'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationPage(
                  email: responseData['email'],
                  tempToken: responseData['tempToken'],
                  userName: _usernameController.text.trim(),
                ),
              ),
            );
          } else {
            // Normal login success - existing logic
            final token = responseData['token'];
            final user = responseData['user'];

            // Debug: Print user role for troubleshooting
            print('User role: ${user['role']}');
            print('User data: $user');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login Successful! Welcome, ${user['role']?.toUpperCase()}'),
                backgroundColor: Colors.green,
              ),
            );

            if (user['role'] == 'farmer') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmersHomePage(token: token),
                ),
              );
            } else if (user['role'] == 'customer') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerHomePage(token: token),
                ),
              );
            } else if (user['role'] == 'transporter') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterDashboard(token: token),
                ),
              );
            } else if (user['role'] == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminManagementPage(user: user, token: token),
                ),
              );
            } else if (user['role'] == 'delivery') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryDashboard(user: user, token: token),
                ),
              );
            } else {
              // Unknown role - show error and stay on login page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unknown user role: ${user['role']}. Please contact support.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
              print('Unknown user role: ${user['role']}');
            }
          }
        } else {
          String errorMessage = 'Invalid credentials';
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorData['error'] ?? 'Invalid credentials';
          } catch (e) {
            errorMessage = 'Login failed. Please try again.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFF81C784),
                  Color(0xFFB2FF59),
                  Color(0xFF388E3C),
                ],
              ),
            ),
          ),
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24.0,
                MediaQuery.of(context).padding.top + 24.0,
                24.0,
                MediaQuery.of(context).padding.bottom + 24.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white,
                                child: Image.asset(
                                  'assets/farmer.jpg',
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Farmer Crate',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Welcome! Please login to continue',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 400),
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.97),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF388E3C),
                              ),
                            ),
                            SizedBox(height: 24),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTextField(
                                    controller: _usernameController,
                                    label: 'Username',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      if (value.length > 20) {
                                        return 'Username must be 8 or fewer characters';
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                                        return 'Only letters and numbers allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length > 8) {
                                        return 'Password must be 8 or fewer characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 24),
                                  _buildLoginButton(),
                                  SizedBox(height: 20),
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildCreateAccountLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFF8F9FA),
        labelStyle: TextStyle(color: Colors.grey[600]),
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Color(0xFF4CAF50).withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          'LOGIN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignUpPage()),
            );
          },
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 16,
              fontWeight: FontWeight.bold,

            ),
          ),
        ),
      ],
    );
  }
}