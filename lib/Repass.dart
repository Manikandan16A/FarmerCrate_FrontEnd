import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Signin.dart';

class PasswordResetPage extends StatefulWidget {
  final String email;

  const PasswordResetPage({Key? key, required this.email}) : super(key: key);

  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _passwordsMatch = false;

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

    // Add listener for password match validation
    _confirmPasswordController.addListener(_validatePasswordMatch);
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call for password update
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      // Navigate to LoginPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!_passwordsMatch) {
      return 'Passwords do not match';
    }
    return null;
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
              Color(0xFF2E7D32), // Dark Green
              Color(0xFF4CAF50), // Medium Green
              Color(0xFF81C784), // Light Green
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
                      // Back Button
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

                      // Logo and Title Section
                      _buildLogoSection(),
                      SizedBox(height: 40),

                      // Password Reset Card
                      _buildPasswordResetCard(),

                      SizedBox(height: 20),
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
        // Lock Icon
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
            Icons.lock_outline,
            size: 60,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 20),

        // Title
        Text(
          'Create New Password',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Enter your new password below',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPasswordResetCard() {
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter and confirm your new password.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 32),

              // New Password Field
              _buildNewPasswordField(),
              SizedBox(height: 24),

              // Confirm Password Field
              _buildConfirmPasswordField(),
              SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_isNewPasswordVisible,
          validator: _validateNewPassword,
          decoration: InputDecoration(
            hintText: 'Enter your new password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Color(0xFF4CAF50),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Color(0xFF4CAF50),
              ),
              onPressed: () {
                setState(() {
                  _isNewPasswordVisible = !_isNewPasswordVisible;
                });
              },
            ),
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
            hintStyle: TextStyle(color: Colors.grey[500]),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          validator: _validateConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Re-enter your new password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Color(0xFF4CAF50),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Color(0xFF4CAF50),
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
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
            hintStyle: TextStyle(color: Colors.grey[500]),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    bool isFormValid = _passwordsMatch;

    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || !isFormValid) ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormValid ? Color(0xFF4CAF50) : Colors.grey[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isFormValid ? 8 : 2,
          shadowColor: isFormValid ? Color(0xFF4CAF50).withOpacity(0.3) : Colors.grey.withOpacity(0.2),
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
              Icons.check_circle,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Update Password',
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
}