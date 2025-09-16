import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../Signin.dart';
import '../Customer/Cart.dart';
import 'Addproduct.dart';
import 'contact_admin.dart';
import 'farmerprofile.dart';
import 'ProductEdit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/gestures.dart';

class FarmersHomePage extends StatefulWidget {
  final String? token; // Add token parameter
  
  const FarmersHomePage({Key? key, this.token}) : super(key: key);

  @override
  _FarmersHomePageState createState() => _FarmersHomePageState();
}

class _FarmersHomePageState extends State<FarmersHomePage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  List<Product> products = [];
  bool isLoading = false;
  String? errorMessage;
  late ScrollController _scrollController;
  bool _showSearchBar = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // _filteredProducts = _allProducts.where((product) {
      //   final matchesSearch = product['title']
      //       .toLowerCase()
      //       .contains(_searchController.text.toLowerCase());
      //   final matchesCategory = _selectedCategory == null ||
      //       product['category'] == _selectedCategory;
      //   return matchesSearch && matchesCategory;
      // }).toList();
    });
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
        targetPage = AddProductPage(token: widget.token);
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
        final productsData = responseData['data'] ?? [];
        setState(() {
          products = productsData.map<Product>((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch products. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_showSearchBar) setState(() => _showSearchBar = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_showSearchBar) setState(() => _showSearchBar = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.green[800]),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'FarmerCrate',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: Colors.green[800]),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => FarmerProductsPage(token: widget.token)),
                (route) => false,
              );
            },
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
                Navigator.pop(context); // Close drawer
                _onNavItemTapped(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.add, color: Colors.green[600]),
              title: Text('Add Product'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductPage(token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.green[600]),
              title: Text('Edit Products'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _onNavItemTapped(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_mail, color: Colors.green[600]),
              title: Text('Contact Admin'),
              onTap: () {
                Navigator.pop(context); // Close drawer
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
                Navigator.pop(context); // Close drawer
                _onNavItemTapped(3);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[600]),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedSlide(
              offset: _showSearchBar ? Offset(0, 0) : Offset(0, -1),
              duration: Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.tune, color: Colors.green[700]),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmerProfilePage(token: widget.token),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                              color: Colors.green[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'update profile?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'To reflect your latest information, tap to Update Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    Container(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        'assets/farmer.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Your Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return _buildProductCard(
                    context,
                    product.name,
                    '₹${product.price.toStringAsFixed(2)}',
                    product.description,
                    product.images,
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
        ],
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
              icon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add, size: 24),
              label: 'Add Product',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit, size: 24),
              label: 'Edit Product',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24),
              label: 'Profile',
            ),
          ],
        ),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              title: name,
              price: price,
              rating: '4.5',
              bgColor: Colors.green[50]!,
              emoji: '🌾',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: imageUrl != null && imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: Colors.green[50],
                        child: Icon(Icons.broken_image, size: 40, color: Colors.green[300]),
                      ),
                    )
                  : Container(
                      height: 120,
                      color: Colors.green[50],
                      child: Icon(Icons.image, size: 40, color: Colors.green[300]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final String title;
  final String price;
  final String rating;
  final Color bgColor;
  final String emoji;
  final String? imageUrl;
  final String? description;

  const ProductDetailPage({
    Key? key,
    required this.title,
    required this.price,
    required this.rating,
    required this.bgColor,
    required this.emoji,
    this.imageUrl,
    this.description,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(Icons.favorite_border, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: TextStyle(fontSize: 120),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.price,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.green, size: 25),
                        SizedBox(width: 4),
                        Text(
                          widget.rating,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Add more items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Invoice Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInvoiceRow('Original Price', widget.price),
                    _buildInvoiceRow('Delivery', '₹15'),
                    _buildInvoiceRow('GST', '₹18'),
                    _buildInvoiceRow('Discount', '-₹20', color: Colors.green[600]),
                    Divider(thickness: 1, color: Colors.grey[300]),
                    _buildInvoiceRow('Total', '₹1386', fontWeight: FontWeight.bold),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartPage(token: null), // No token for farmer view
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[600]!],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Proceed to Checkout',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String title, String amount, {Color? color, FontWeight? fontWeight}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontWeight == FontWeight.bold ? 16 : 14,
              fontWeight: fontWeight ?? FontWeight.normal,
              color: color ?? Colors.grey[700],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: fontWeight == FontWeight.bold ? 16 : 14,
              fontWeight: fontWeight ?? FontWeight.normal,
              color: color ?? Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}