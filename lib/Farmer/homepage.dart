import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../auth/Signin.dart';
import 'Addproduct.dart';
import 'contact_admin.dart';
import 'farmerprofile.dart';
import 'ProductEdit.dart';
import 'orders_page.dart';
import 'farmer_product_detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/cloudinary_upload.dart';
import '../utils/notification_helper.dart';

class FarmersHomePage extends StatefulWidget {
  final String? token; // Add token parameter

  const FarmersHomePage({super.key, this.token});

  @override
  State<FarmersHomePage> createState() => _FarmersHomePageState();
}

class _FarmersHomePageState extends State<FarmersHomePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  List<Product> products = [];
  bool isLoading = false;
  String? errorMessage;
  late ScrollController _scrollController;
  bool _showSearchBar = true;
  bool _isSearching = false;
  String farmerName = 'Farmer';
  String? farmerImageUrl;
  bool _isLoadingProfile = true;
  String _statusFilter = 'All';
  int _pendingOrdersCount = 0;
  static bool _hasShownWelcome = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchProducts();
    fetchFarmerProfile();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> fetchFarmerProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      print('Fetching farmer profile...');
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/farmers/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Profile data: $data');
        final name = data['data']['name'] ?? 'Farmer';
        final imageUrl = data['data']['image_url'] ?? data['data']['imageUrl'] ?? data['data']['profile_image'] ?? data['data']['image'];
        print('Farmer name: $name');
        print('Farmer image URL: $imageUrl');
        setState(() {
          farmerName = name;
          farmerImageUrl = imageUrl;
          _isLoadingProfile = false;
        });
        if (mounted && !_hasShownWelcome) {
          _hasShownWelcome = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              NotificationHelper.showInfo(context, 'Welcome $name, to FarmerCrate');
            }
          });
        }
      } else {
        print('Failed to fetch profile: ${response.statusCode}');
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }



  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = FarmersHomePage(token: widget.token);
        break;
      case 1:
        targetPage = OrdersPage(token: widget.token);
        break;
      case 2:
        targetPage = FarmerProductsPage(token: widget.token);
        break;
      case 3:
        targetPage = FarmerProfilePage(token: widget.token);
        break;
      default:
        targetPage = const FarmersHomePage();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
          (route) => false,
    );
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse('https://farmercrate.onrender.com/api/products/farmer/me');
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (widget.token != null && widget.token!.isNotEmpty)
          'Authorization': 'Bearer ${widget.token}',
      };


      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> productsData = [];

        // Handle different response structures
        if (responseData is Map && responseData.containsKey('data')) {
          productsData = responseData['data'] ?? [];
        } else if (responseData is List) {
          productsData = responseData;
        } else {
          productsData = [responseData]; // Single product case
        }


        if (productsData.isNotEmpty) {
          setState(() {
            products = productsData.map<Product>((json) {
              return Product.fromJson(json);
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            products = [];
            isLoading = false;
            errorMessage = 'No products found. Add your first product!';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Authentication failed. Please login again.';
          isLoading = false;
        });
        if (mounted) NotificationHelper.showError(context, 'Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        setState(() {
          products = [];
          isLoading = false;
          errorMessage = 'No products found. Add your first product!';
        });
        if (mounted) NotificationHelper.showInfo(context, 'No products found. Add your first product!');
      } else {
        setState(() {
          errorMessage = 'Failed to fetch products. Status: ${response.statusCode}';
          isLoading = false;
        });
        if (mounted) NotificationHelper.showError(context, 'Failed to fetch products. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
      if (mounted) NotificationHelper.showError(context, 'Network error: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_showSearchBar) setState(() => _showSearchBar = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_showSearchBar) setState(() => _showSearchBar = true);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFD32F2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_outlined, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(
                'FarmerCrate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchProducts,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[600],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FarmerCrate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Welcome, Farmer!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
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
                _onNavItemTapped(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag, color: Colors.green[600]),
              title: Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                _onNavItemTapped(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.green[600]),
              title: Text('Edit Products'),
              onTap: () {
                Navigator.pop(context);
                _onNavItemTapped(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_mail, color: Colors.green[600]),
              title: Text('Contact Admin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactAdminPage(token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.green[600]),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _onNavItemTapped(3);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[600]),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Products...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
        onRefresh: fetchProducts,
        child: CustomScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: EdgeInsets.fromLTRB(20, 8, 20, 8),
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[50]!, Colors.white],
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0,4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome $farmerName',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 14),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => FarmerProfilePage(token: widget.token)),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.green[400]!,
                                      Colors.green[600]!,
                                      Colors.green[700]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              '✨ Update Profile',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Keep your profile fresh & up to date',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Tap here to update your profile',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.95),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                      ),
                                      child: _isLoadingProfile
                                          ? Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      )
                                          : farmerImageUrl != null && farmerImageUrl!.isNotEmpty
                                          ? ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.network(
                                          farmerImageUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                          : Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Active Listings', '${products.length}', Icons.inventory_2),
                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                  _buildStatCard('Available', '${products.where((p) => _getProductStatus(p) == 'Available').length}', Icons.check_circle),
                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                  _buildStatCard('Out of Stock', '${products.where((p) => _getProductStatus(p) == 'Out of Stock').length}', Icons.warning),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip('All'),
                    SizedBox(width: 8),
                    _buildStatusChip('Available'),
                    SizedBox(width: 8),
                    _buildStatusChip('Low Stock'),
                    SizedBox(width: 8),
                    _buildStatusChip('Out of Stock'),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Your Products',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = _getFilteredProducts()[index];
                  return _buildProductCard(
                    context,
                    product.name,
                    '₹${product.price.toStringAsFixed(2)}',
                    product.description,
                    product.images,
                  );
                },
                childCount: _getFilteredProducts().length,
              ),
            ),
          ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage(token: widget.token)),
          );
        },
        backgroundColor: Colors.green.shade600,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 6,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.blueGrey,
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          currentIndex: _currentIndex,
          elevation: 0,
          onTap: _onNavItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 22,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 1 ? Icons.shopping_bag : Icons.shopping_bag_outlined,
                  size: 22,
                ),
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 2 ? Icons.edit : Icons.edit_outlined,
                  size: 22,
                ),
              ),
              label: 'Edit Product',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 3 ? Icons.person : Icons.person_outline,
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

  String _getProductStatus(Product product) {
    if (product.quantity == 0) return 'Out of Stock';
    if (product.quantity < 10) return 'Low Stock';
    return 'Available';
  }

  List<Product> _getFilteredProducts() {
    if (_statusFilter == 'All') return products;
    return products.where((p) => _getProductStatus(p) == _statusFilter).toList();
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    bool isSelected = _statusFilter == status;
    Color chipColor;
    IconData chipIcon;
    
    switch (status) {
      case 'Available':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'Low Stock':
        chipColor = Colors.orange;
        chipIcon = Icons.warning;
        break;
      case 'Out of Stock':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.all_inclusive;
    }

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 16, color: isSelected ? Colors.white : chipColor),
          SizedBox(width: 4),
          Text(status),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _statusFilter = status;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: chipColor, width: 1.5),
      elevation: isSelected ? 4 : 0,
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    // Handle different image URL formats
    String? processedUrl;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        processedUrl = imageUrl;
      } else if (imageUrl.startsWith('/')) {
        // Handle relative URLs
        processedUrl = 'https://farmercrate.onrender.com$imageUrl';
      } else {
        // Handle other formats
        processedUrl = imageUrl.contains('://') ? imageUrl : 'https://farmercrate.onrender.com/uploads/$imageUrl';
      }
    }

    if (processedUrl != null) {
      return Image.network(
        CloudinaryUploader.optimizeImageUrl(processedUrl, width: 300, height: 150, quality: 'auto', format: 'auto'),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.green[50],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Image load error for URL: $processedUrl - Error: $error');
          return _buildPlaceholderImage();
        },
      );
    }
    
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.green[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 40, color: Colors.green[300]),
          SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.green[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context,
      String name,
      String price,
      String description,
      String? imageUrl,
      ) {
    final product = products.firstWhere((p) => p.name == name);
    
    String? firstImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.contains('|||')) {
        firstImageUrl = imageUrl.split('|||').first.trim();
      } else if (imageUrl.contains(',https://') || imageUrl.contains(',http://')) {
        firstImageUrl = imageUrl.split(RegExp(r',(?=https?://)')).first.trim();
      } else {
        firstImageUrl = imageUrl.trim();
      }
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FarmerProductDetailPage(
              productId: product.id.toString(),
              name: name,
              price: price,
              description: description,
              imageUrl: imageUrl,
              quantity: product.quantity,
              token: widget.token,
              category: product.category,
              harvestDate: product.harvestDate,
              expiryDate: product.expiryDate,
              grade: product.grade,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildProductImage(firstImageUrl),
              ),
            ),
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.grey[50],
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          product.category ?? 'Category',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.harvestDate != null) ...<Widget>[
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.green[600]),
                              SizedBox(width: 4),
                              Text(
                                '${product.harvestDate!.day}/${product.harvestDate!.month}/${product.harvestDate!.year}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                        if (product.expiryDate != null) ...<Widget>[
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.event_busy, size: 14, color: Colors.orange[600]),
                              SizedBox(width: 4),
                              Text(
                                '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

