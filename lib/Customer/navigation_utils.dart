import 'package:flutter/material.dart';
import 'customerhomepage.dart';
import 'Categories.dart';
import 'Cart.dart';
import 'profile.dart';
import 'order history.dart';
import 'customer_order_tracking.dart';
import '../auth/Signin.dart';



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

  static PreferredSizeWidget buildGlassmorphicAppBar({
    required String title,
    bool showSearch = false,
    TextEditingController? searchController,
    VoidCallback? onSearchToggle,
    VoidCallback? onRefresh,
    VoidCallback? onCartTap,
    List<Widget>? additionalActions,
  }) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.green[50]!.withOpacity(0.9),
            ],
          ),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.menu, color: Colors.green[800], size: 18),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: showSearch && searchController != null
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: (value) {},
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search, color: Colors.green[600], size: 20),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                          onPressed: () {
                            searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                style: TextStyle(fontSize: 14),
              ),
            )
          : ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.green[800]!, Colors.green[600]!],
              ).createShader(bounds),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
      actions: [
        if (onSearchToggle != null)
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.search, color: Colors.green[800], size: 18),
            ),
            onPressed: onSearchToggle,
          ),
        if (onRefresh != null)
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.refresh, color: Colors.green[800], size: 18),
            ),
            onPressed: onRefresh,
          ),
        if (onCartTap != null)
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.shopping_cart, color: Colors.green[800], size: 18),
            ),
            onPressed: onCartTap,
          ),
        if (additionalActions != null) ...additionalActions,
      ],
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
            Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 35,
                              backgroundImage: (customerImageUrl != null && customerImageUrl!.isNotEmpty)
                                  ? NetworkImage(customerImageUrl!)
                                  : null,
                              child: isLoadingProfile
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                                      ),
                                    )
                                  : (customerImageUrl == null || customerImageUrl!.isEmpty)
                                      ? Icon(Icons.person, size: 40, color: Colors.green[700])
                                      : null,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            customerName != null && customerName!.isNotEmpty
                                ? customerName!
                                : 'Welcome!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Explore Farm Fresh Products',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildDrawerItem(
              icon: Icons.home_outlined,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  parentContext,
                  MaterialPageRoute(builder: (context) => CustomerHomePage(token: token)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Orders',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (context) => OrderHistoryPage(token: token)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.category_outlined,
              title: 'Categories',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (context) => CategoryPage(token: token)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (context) => CartPage(token: token)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (context) => CustomerProfilePage(token: token ?? '')),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(color: Colors.grey[300]),
            ),
            _buildDrawerItem(
              icon: Icons.logout_outlined,
              title: 'Logout',
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFF5722), Color(0xFFD32F2F)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.logout_outlined, color: Colors.white, size: 32),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Confirm Logout',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Are you sure you want to logout?',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      Navigator.pushAndRemoveUntil(
                                        parentContext,
                                        MaterialPageRoute(builder: (context) => LoginPage()),
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFF5722),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.green[600]!, Colors.green[400]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.green[600]!.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.green[600],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
