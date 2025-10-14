import 'package:flutter/material.dart';
import 'customerhomepage.dart';
import 'Categories.dart';
import 'Cart.dart';
import 'profile.dart';
import 'order history.dart';



class CustomerNavigationUtils {
  static Widget buildCustomerDrawer({
    required BuildContext parentContext,
    required String? token,
    String? customerImageUrl,
    String? customerName,
    bool isLoadingProfile = false,
  }) {
    return CustomerDrawer(
      parentContext: parentContext,
      token: token,
      customerImageUrl: customerImageUrl,
      customerName: customerName,
      isLoadingProfile: isLoadingProfile,
    );
  }

  static Widget buildCustomerBottomNav({
    required int currentIndex,
    required Function(int) onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.green[700],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          currentIndex: currentIndex,
          elevation: 0,
          onTap: onTap,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: currentIndex == 0 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 22,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: currentIndex == 1 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentIndex == 1 ? Icons.category : Icons.category_outlined,
                  size: 22,
                ),
              ),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: currentIndex == 2 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentIndex == 2 ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  size: 22,
                ),
              ),
              label: 'Cart',
            ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: currentIndex == 3 ? Colors.green[50] : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    currentIndex == 3 ? Icons.person : Icons.person_outline,
                    size: 22,
                  ),
                ),
                label: 'Profile',
              ),
          ],
        ),
      ),
    );
  }

  static void handleNavigation(int index, BuildContext context, String? token) {
    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = CustomerHomePage(token: token);
        break;
      case 1:
        targetPage = CategoryPage(token: token);
        break;
      case 2:
        targetPage = CartPage(token: token);
        break;
      case 3:
        targetPage = CustomerProfilePage(token: token);
        break;
      default:
        targetPage = CustomerHomePage(token: token);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  static Future<Map<String, dynamic>> getCustomerProfile(String? token) async {
    if (token == null || token.trim().isEmpty) {
      return {
        'customerImageUrl': null,
        'customerName': null,
        'isLoadingProfile': false,
      };
    }

    try {

      return {
        'customerImageUrl': null,
        'customerName': null,
        'isLoadingProfile': false,
      };
    } catch (e) {
      return {
        'customerImageUrl': null,
        'customerName': null,
        'isLoadingProfile': false,
      };
    }
  }
}

class CustomerDrawer extends StatelessWidget {
  final BuildContext parentContext;
  final String? token;
  final String? customerImageUrl;
  final String? customerName;
  final bool isLoadingProfile;

  const CustomerDrawer({
    Key? key,
    required this.parentContext,
    required this.token,
    this.customerImageUrl,
    this.customerName,
    this.isLoadingProfile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[400]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: customerImageUrl != null && customerImageUrl!.isNotEmpty
                        ? NetworkImage(customerImageUrl!)
                        : null,
                    child: customerImageUrl == null || customerImageUrl!.isEmpty
                        ? Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  SizedBox(height: 12),
                  Text(
                    customerName ?? 'Customer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Welcome to FarmerCrate',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.green[600]),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerHomePage(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag, color: Colors.green[600]),
              title: Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderHistoryPage(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.category, color: Colors.green[600]),
              title: Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryPage(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.green[600]),
              title: Text('Cart'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(token: token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.green[600]),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerProfilePage(token: token),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
