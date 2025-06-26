import 'package:flutter/material.dart';

import 'Admin/requstaccept.dart';
import 'Signin.dart';
import 'signup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer Create',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const FarmCrateLandingApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FarmCrateLandingApp extends StatelessWidget {
  const FarmCrateLandingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Crate - Connecting Farmers & Customers',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.green,
      ),
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late AnimationController _slideUpController;
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<double> _gradientAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

// Initialize animation controllers
    _gradientController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _slideUpController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration:  const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

// Initialize animations
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    _slideUpAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideUpController, curve: Curves.easeOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.5).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

// Start slide up animation
    _slideUpController.forward();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    _slideUpController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  AdminFarmerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8E4FF),
                  Color(0xFFF5F3FF),
                  Colors.white,
                ],
                stops: [0.0, 0.3, 1.0],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 40.0),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

// Agriculture-themed illustration
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E4FF).withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
// Farmer image from assets
                          Center(
                            child: Image.asset(
                              'assets/getstart.png',
                              width: 280,
                              height: 280,
                              fit: BoxFit.cover,
                            ),
                          ),

// Soil-like decorative elements
                          _buildDecorativeElement(80, 120, Colors.brown, 6),
                          _buildDecorativeElement(180, 140, Colors.brown, 8),
                          _buildDecorativeElement(120, 60, Colors.brown, 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    const Text(
                      "Farmers Crate",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Lets Get Started On Your Journey\n to Freshness Begins Here",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(flex: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _showLoginPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Select Language'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('English'),
                            onTap: () {
                              Navigator.of(context).pop();
                              // Set language to English
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('தமிழ்'),
                            onTap: () {
                              Navigator.of(context).pop();
                              // Set language to Tamil
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('हिन्दी'),
                            onTap: () {
                              Navigator.of(context).pop();
                              // Set language to Hindi
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/OIP.jpg',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrop(double left, double top, int delay, Color color) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        double animationValue = (_bounceController.value + delay * 0.2) % 1.0;
        double yOffset = -8 * (0.5 - (animationValue - 0.5).abs()) * 2;

        return Positioned(
          left: left,
          top: top + yOffset,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.grass,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorativeElement(double left, double top, Color color, double size) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: _fadeAnimation.value * 0.6,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}