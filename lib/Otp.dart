import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Repass.dart';

class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({Key? key, required this.email}) : super(key: key);

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp(String otp) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('https://farmercrate.onrender.com/api/auth/verify-otp'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'email': widget.email,
        'otp': otp,
      });

      final streamedResponse = await request.send().timeout(Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => PasswordResetPage(email: widget.email)),
                  (route) => false,
            );

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('OTP verified successfully! Set your new password.'),
                    backgroundColor: Color(0xFF4CAF50),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        } else {
          throw Exception(responseData['message'] ?? 'Invalid OTP. Please try again.');
        }
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection and try again.');
    } catch (e) {
      throw Exception('Error verifying OTP: ${e.toString()}');
    }
  }

  void _handleOTPSubmit() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showErrorDialog('Please enter a complete 6-digit OTP');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showErrorDialog('OTP must contain only digits');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _verifyOtp(otp);
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleOtpChange(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
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
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
              Color(0xFF81C784),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildLogoSection(),
                      SizedBox(height: 40),
                      _buildOTPCard(),
                      SizedBox(height: 20),
                      _buildResendOTPLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.shield_outlined,
            size: 60,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to\n${widget.email}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildOTPCard() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We\'ve sent a 6-digit verification code to your email address.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            SizedBox(height: 32),
            _buildOTPFields(),
            SizedBox(height: 32),
            _buildSubmitButton(),
            SizedBox(height: 20),
            _buildHelpText(),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) => Container(
        width: 45,
        height: 60,
        child: TextFormField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          obscureText: true,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) => _handleOtpChange(value, index),
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.all(0),
          ),
        ),
      )),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleOTPSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
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
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Verify OTP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'The verification code expires in 10 minutes. Please enter it before it expires.',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendOTPLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
            setState(() {
              _isLoading = true;
            });
            try {
              final request = http.Request(
                'POST',
                Uri.parse('https://farmercrate.onrender.com/api/auth/forgot-password'),
              );
              request.headers['Content-Type'] = 'application/json';
              request.body = jsonEncode({
                'email': widget.email,
              });
              final streamedResponse = await request.send().timeout(Duration(seconds: 10));
              final response = await http.Response.fromStream(streamedResponse);
              setState(() {
                _isLoading = false;
              });
              if (response.statusCode == 200) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('New OTP sent to ${widget.email}'),
                      backgroundColor: Color(0xFF4CAF50),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } else {
                final responseData = jsonDecode(response.body);
                String errorMessage = responseData['message'] ?? 'Error resending OTP';
                if (mounted) {
                  _showErrorDialog(errorMessage);
                }
              }
            } on TimeoutException {
              if (mounted) {
                _showErrorDialog('Request timed out. Please check your connection and try again.');
              }
            } catch (error) {
              if (mounted) {
                _showErrorDialog('Error resending OTP: $error');
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
          child: Text(
            'Resend OTP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}