import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customerhomepage.dart';
import 'Categories.dart';
import 'Cart.dart';
import 'profile.dart';
import 'wishlist.dart';
import 'FAQpage.dart';
import '../Signin.dart';

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
                  currentIndex == 3 ? Icons.help : Icons.help_outline,
                  size: 22,
                ),
              ),
              label: 'FAQ',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: currentIndex == 4 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentIndex == 4 ? Icons.person : Icons.person_outline,
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
        targetPage = FAQPage(token: token);
        break;
      case 4:
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
      // This would typically make an API call to get customer profile
      // For now, we'll return default values
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
