import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import '../Admin/admin_homepage.dart';
import '../Customer/customerhomepage.dart';
import '../Farmer/homepage.dart';
import '../Transpoter/transporter_dashboard.dart';
import '../delivery/delivery_dashboard.dart';
import '../utils/snackbar_utils.dart';
import 'Forget.dart';
import 'Signup.dart';
import 'customerFTL.dart';
import 'Repass.dart';
import 'google_profile_completion.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '850075546970-5v0jdspjmtm4ciu5sqrukvlhmohhqon9.apps.googleusercontent.com',
  );

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

  Future<void> _updateAvailability(bool isAvailable, String token) async {
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/delivery-persons/availability'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_available': isAvailable}),
      );
      print('Availability update response: ${response.statusCode}');
    } catch (e) {
      print('Error updating availability: $e');
    }
  }

  void _showDeliveryAvailabilityDialog(Map<String, dynamic> user, String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[50]!, Colors.white],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delivery_dining, size: 48, color: Colors.green[700]),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Are you available?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Set your availability status to start receiving delivery orders',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _updateAvailability(false, token);
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeliveryDashboard(user: user, token: token),
                              ),
                            );
                            SnackBarUtils.showWarning(context, 'You are offline. No orders will be assigned.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.grey[800],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.cancel_outlined, size: 28),
                              SizedBox(height: 4),
                              Text(
                                'Not Available',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _updateAvailability(true, token);
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeliveryDashboard(user: user, token: token),
                              ),
                            );
                            SnackBarUtils.showInfo(context, 'You are now available for deliveries');
                            print('✓ Navigation to DeliveryDashboard successful');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle, size: 28),
                              SizedBox(height: 4),
                              Text(
                                'Available',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      print('\n========== LOGIN ATTEMPT ==========');
      print('Username: ${_usernameController.text.trim()}');
      print('Timestamp: ${DateTime.now()}');
      
      setState(() {
        _isLoading = true;
      });

      try {
        print('Sending login request to API...');
        final response = await http.post(
          Uri.parse('https://farmercrate.onrender.com/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text.trim(),
            'password': _passwordController.text,
          }),
        );

        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('✓ Login API Success');
          print('Response Data Keys: ${responseData.keys.toList()}');

          // Check if temp token is received (first-time delivery person login)
          if (responseData['requiresPasswordChange'] == true && responseData['tempToken'] != null) {
            print('--- DELIVERY PERSON FIRST-TIME LOGIN DETECTED ---');
            print('Temp Token: ${responseData['tempToken']}');
            print('Message: ${responseData['message']}');
            
            // Decode temp token to get user ID
            try {
              final token = responseData['tempToken'] as String;
              final parts = token.split('.');
              if (parts.length == 3) {
                // Decode JWT payload
                String payload = parts[1];
                // Add padding if needed
                while (payload.length % 4 != 0) {
                  payload += '=';
                }
                final decoded = utf8.decode(base64.decode(payload));
                final payloadMap = jsonDecode(decoded);
                final userId = payloadMap['delivery_person_id'];
                print('Decoded User ID from token: $userId');
                print('Token payload: $payloadMap');
                print('Redirecting to password reset page...');
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryPasswordResetPage(
                      tempToken: token,
                      userId: userId,
                    ),
                  ),
                );
                print('✓ Navigation to DeliveryPasswordResetPage successful');
              } else {
                throw Exception('Invalid token format');
              }
            } catch (e, stackTrace) {
              print('❌ Error decoding token: $e');
              print('Stack trace: $stackTrace');
              SnackBarUtils.show(context, 'Error processing login. Please try again.');
            }
          }
          // Check if OTP verification is required for first-time customer login
          else if (responseData['requiresOTP'] == true) {
            print('--- CUSTOMER FIRST-TIME LOGIN DETECTED ---');
            print('Email: ${responseData['email']}');
            print('Temp Token: ${responseData['tempToken']}');
            print('Redirecting to OTP verification page...');
            
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
            print('✓ Navigation to OTPVerificationPage successful');
          } else {
            // Normal login success - existing logic
            print('--- NORMAL LOGIN FLOW ---');
            final token = responseData['token'];
            final user = responseData['user'];

            print('User Role: ${user['role']}');
            print('User ID: ${user['id']}');
            print('User Name: ${user['name']}');
            print('Token: ${token?.substring(0, 20)}...');
            print('Full User Data: $user');

            // Save token and user data to SharedPreferences for session persistence
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('jwt_token', token);
            await prefs.setString('auth_token', token);
            await prefs.setString('role', user['role']);
            await prefs.setInt('user_id', user['id']);
            if (user['name'] != null) await prefs.setString('username', user['name']);
            await prefs.setBool('is_logged_in', true);
            final expiryTime = DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch;
            await prefs.setInt('token_expiry', expiryTime);
            print('✓ Token and user data saved to SharedPreferences');
            print('✓ Token expiry set to: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');

            if (user['role'] == 'farmer') {
              print('Navigating to FarmersHomePage...');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmersHomePage(token: token),
                ),
              );
              print('✓ Navigation to FarmersHomePage successful');
            } else if (user['role'] == 'customer') {
              print('Navigating to CustomerHomePage...');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerHomePage(token: token),
                ),
              );
              print('✓ Navigation to CustomerHomePage successful');
            } else if (user['role'] == 'transporter') {
              print('Navigating to TransporterDashboard...');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterDashboard(token: token),
                ),
              );
              print('✓ Navigation to TransporterDashboard successful');
            } else if (user['role'] == 'admin') {
              print('Navigating to AdminManagementPage...');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminManagementPage(user: user, token: token),
                ),
              );
              print('✓ Navigation to AdminManagementPage successful');
            } else if (user['role'] == 'delivery') {
              print('Showing availability dialog for delivery person...');
              _showDeliveryAvailabilityDialog(user, token);
            } else {
              print('❌ ERROR: Unknown user role');
              print('Role received: ${user['role']}');
              print('Available roles: farmer, customer, transporter, admin, delivery');
              
              SnackBarUtils.show(context, 'Unknown user role: ${user['role']}. Please contact support.');
            }
          }
          print('===================================\n');
        } else {
          print('❌ LOGIN FAILED');
          print('Status Code: ${response.statusCode}');
          print('Response Body: ${response.body}');
          
          String errorMessage = 'Invalid credentials';
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorData['error'] ?? 'Invalid credentials';
            print('Error Message: $errorMessage');
            print('Error Data: $errorData');
          } catch (e) {
            print('❌ Failed to parse error response: $e');
            errorMessage = 'Login failed. Please try again.';
          }

          SnackBarUtils.show(context, errorMessage);
          print('===================================\n');
        }
      } catch (e, stackTrace) {
        print('❌ EXCEPTION DURING LOGIN');
        print('Error: $e');
        print('Stack Trace: $stackTrace');
        print('Error Type: ${e.runtimeType}');
        
        setState(() {
          _isLoading = false;
        });
        
        SnackBarUtils.show(context, 'Error: $e');
        print('===================================\n');
      }
    } else {
      print('❌ Form validation failed');
      print('Username: ${_usernameController.text}');
      print('Password length: ${_passwordController.text.length}');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Show role selection dialog
    final String? selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Your Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.shopping_cart, color: Color(0xFF4CAF50)),
              title: Text('Customer'),
              onTap: () => Navigator.pop(context, 'customer'),
            ),
            ListTile(
              leading: Icon(Icons.agriculture, color: Color(0xFF4CAF50)),
              title: Text('Farmer'),
              onTap: () => Navigator.pop(context, 'farmer'),
            ),
          ],
        ),
      ),
    );

    if (selectedRole == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Google user signed in: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Access token: ${googleAuth.accessToken?.substring(0, 20)}...');
      print('ID token: ${googleAuth.idToken?.substring(0, 20) ?? "NULL"}...');
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        print('ERROR: ID token is null');
        print('Server auth code: ${googleAuth.serverAuthCode}');
        throw Exception('Failed to get ID token');
      }

      print('Sending request to backend...');
      final response = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/auth/google-signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'role': selectedRole,
        }),
      );

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if token exists (existing user) or if it's a new user
        if (data['token'] != null) {
          final token = data['token'];
          final user = data['user'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('auth_token', token);
          await prefs.setString('role', selectedRole);
          await prefs.setInt('user_id', user['id']);
          await prefs.setString('username', user['name']);
          await prefs.setString('email', user['email']);
          await prefs.setBool('is_logged_in', true);

          if (selectedRole == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CustomerHomePage(token: token)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FarmersHomePage(token: token)),
            );
          }
        } else {
          // New user created but needs profile completion
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GoogleProfileCompletionPage(
                email: googleUser.email,
                name: googleUser.displayName ?? 'User',
                googleId: googleUser.id,
                role: selectedRole,
              ),
            ),
          );
        }
      } else if (response.statusCode == 404) {
        // New user - show profile completion page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleProfileCompletionPage(
              email: googleUser.email,
              name: googleUser.displayName ?? 'User',
              googleId: googleUser.id,
              role: selectedRole,
            ),
          ),
        );
      } else if (response.statusCode == 403) {
        // Account pending verification
        final data = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.pending, color: Colors.orange),
                SizedBox(width: 8),
                Text('Verification Pending'),
              ],
            ),
            content: Text(data['message'] ?? 'Your account is pending admin verification. Please wait for approval.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else if (response.statusCode == 409) {
        // Handle email uniqueness conflict
        final data = jsonDecode(response.body);
        final existingRole = data['existingRole'];
        final requestedRole = data['requestedRole'];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Email Conflict'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This email is registered as a $existingRole.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'You cannot sign in as a $requestedRole with this email. Please select the correct role or use a different email.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        SnackBarUtils.show(context, 'Google Sign-In failed. Please try again.');
      }
    } on PlatformException catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Google Sign-In PlatformException: ${e.code}');
      print('Error message: ${e.message}');
      if (e.code == 'sign_in_failed' || e.code == 'network_error') {
        SnackBarUtils.show(context, 'Google Sign-In not available. Please use regular login.');
      } else {
        SnackBarUtils.show(context, 'Error: ${e.message}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Google Sign-In Error: $e');
      SnackBarUtils.show(context, 'Error: $e');
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
                                      if (value.length < 4) {
                                        return 'Password must be at least 4 characters';
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
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.grey[400])),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text('OR', style: TextStyle(color: Colors.grey[600])),
                                      ),
                                      Expanded(child: Divider(color: Colors.grey[400])),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black87,
                                        elevation: 2,
                                        shadowColor: Colors.black26,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28),
                                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/icons8-google-logo-50.png',
                                            width: 20,
                                            height: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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