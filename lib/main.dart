import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/main.dart';
import 'auth/Signin.dart';
import 'Admin/admin_homepage.dart';
import 'Customer/customerhomepage.dart';
import 'Farmer/homepage.dart';
import 'Transpoter/transporter_dashboard.dart';
import 'delivery/delivery_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer Crate',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const AuthChecker(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('jwt_token');
      final role = prefs.getString('role');
      final userId = prefs.getInt('user_id');

      if (token != null && token.isNotEmpty && role != null) {
        // User is logged in, navigate to appropriate page
        Widget targetPage;
        
        switch (role) {
          case 'farmer':
            targetPage = FarmersHomePage(token: token);
            break;
          case 'customer':
            targetPage = CustomerHomePage(token: token);
            break;
          case 'transporter':
            targetPage = TransporterDashboard(token: token);
            break;
          case 'admin':
            final user = {'id': userId, 'role': role};
            targetPage = AdminManagementPage(user: user, token: token);
            break;
          case 'delivery':
            final user = {'id': userId, 'role': role};
            targetPage = DeliveryDashboard(user: user, token: token);
            break;
          default:
            targetPage = const FarmCrateLandingApp();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      } else {
        // No valid token, show landing page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FarmCrateLandingApp()),
        );
      }
    } catch (e) {
      // Error checking auth, show landing page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FarmCrateLandingApp()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      ),
    );
  }
}