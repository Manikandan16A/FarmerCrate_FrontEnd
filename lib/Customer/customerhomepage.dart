import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class CustomerHomePage extends StatefulWidget {
  final String? token;
  
  CustomerHomePage({this.token});
  
  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'All';
  bool _isLoading = true;
  List<Product> products = [];
  List<Product> topBuys = [];

  final List<String> categories = [
    'All', 'Vegetables', 'Fruits', 'Herbs', 'Organic', 'Seasonal'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/products'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsData = jsonDecode(response.body);
        setState(() {
          products = productsData.map((data) => Product(
            data['name'] ?? 'Unknown Product',
            data['image'] ?? 'assets/farmer.jpg',
            (data['price'] ?? 0.0).toDouble(),
            data['category'] ?? 'General',
            (data['rating'] ?? 4.0).toDouble(),
            data['isOrganic'] ?? false,
          )).toList();
          
          // Set top buys as first 3 products
          topBuys = products.take(3).toList();
          _isLoading = false;
        });
      } else {
        // If API fails, use fallback data
        _loadFallbackData();
      }
    } catch (e) {
      // If API fails, use fallback data
      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    setState(() {
      products = [
        Product('Fresh Tomatoes', 'assets/farmer.jpg', 4.99, 'Vegetables', 4.5, true),
        Product('Organic Spinach', 'assets/farmer.jpg', 3.49, 'Vegetables', 4.8, true),
        Product('Sweet Apples', 'assets/farmer.jpg', 5.99, 'Fruits', 4.6, false),
        Product('Fresh Carrots', 'assets/farmer.jpg', 2.99, 'Vegetables', 4.7, true),
        Product('Ripe Bananas', 'assets/farmer.jpg', 1.99, 'Fruits', 4.4, false),
        Product('Bell Peppers', 'assets/farmer.jpg', 6.49, 'Vegetables', 4.5, true),
        Product('Fresh Strawberries', 'assets/farmer.jpg', 7.99, 'Fruits', 4.9, false),
        Product('Green Lettuce', 'assets/farmer.jpg', 2.49, 'Vegetables', 4.3, true),
        Product('Organic Basil', 'assets/farmer.jpg', 4.99, 'Herbs', 4.7, true),
        Product('Sweet Corn', 'assets/farmer.jpg', 3.99, 'Vegetables', 4.6, false),
      ];
      
      topBuys = [
        Product('Fresh Tomatoes', 'assets/farmer.jpg', 4.99, 'Vegetables', 4.5, true),
        Product('Sweet Apples', 'assets/farmer.jpg', 5.99, 'Fruits', 4.6, false),
        Product('Fresh Strawberries', 'assets/farmer.jpg', 7.99, 'Fruits', 4.9, false),
      ];
      _isLoading = false;
    });
  }

  List<Product> get filteredProducts {
    List<Product> filtered = selectedCategory == 'All'
        ? products
        : products.where((p) => p.category == selectedCategory).toList();

    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFF0F8F0),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading fresh products...',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    _buildSearchBar(),
                    _buildCategories(),
                    _buildTopBuysSection(),
                    _buildSuggestedSection(),
                    _buildProductGrid(),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Farm Fresh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Organic • Local • Fresh',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _fetchProducts();
          },
        ),
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.favorite_border, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search fresh produce...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.green[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[500]),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
                  : Icon(Icons.mic, color: Colors.green[600]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: Container(
        height: 56,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory == category;

            return GestureDetector(
              onTap: () => setState(() => selectedCategory = category),
              child: Container(
                margin: EdgeInsets.only(right: 12, top: 8, bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)])
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.green[300]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.green[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBuysSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[600], size: 24),
                SizedBox(width: 8),
                Text(
                  'Top Buys This Week',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: topBuys.length,
              itemBuilder: (context, index) {
                final product = topBuys[index];
                return _buildHorizontalProductCard(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            Icon(Icons.recommend, color: Colors.green[600], size: 24),
            SizedBox(width: 8),
            Text(
              'Suggested for You',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final product = filteredProducts[index];
            return _buildProductCard(product);
          },
          childCount: filteredProducts.length,
        ),
      ),
    );
  }

  Widget _buildHorizontalProductCard(Product product) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[100]!, Colors.green[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    _getProductIcon(product.name),
                    size: 50,
                    color: Colors.green[600],
                  ),
                ),
              ),
              if (product.isOrganic)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ORGANIC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      SizedBox(width: 2),
                      Text(
                        '${product.rating}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[100]!, Colors.green[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    _getProductIcon(product.name),
                    size: 60,
                    color: Colors.green[600],
                  ),
                ),
              ),
              if (product.isOrganic)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ORGANIC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () {},
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green[700],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.green[600],
        unselectedItemColor: Colors.grey[500],
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  IconData _getProductIcon(String productName) {
    if (productName.toLowerCase().contains('tomato')) return Icons.local_florist;
    if (productName.toLowerCase().contains('apple')) return Icons.apple;
    if (productName.toLowerCase().contains('carrot')) return Icons.eco;
    if (productName.toLowerCase().contains('banana')) return Icons.eco;
    if (productName.toLowerCase().contains('pepper')) return Icons.local_florist;
    if (productName.toLowerCase().contains('strawberry')) return Icons.eco;
    if (productName.toLowerCase().contains('lettuce')) return Icons.grass;
    if (productName.toLowerCase().contains('spinach')) return Icons.grass;
    if (productName.toLowerCase().contains('basil')) return Icons.grass;
    if (productName.toLowerCase().contains('corn')) return Icons.eco;
    return Icons.eco;
  }
}

class Product {
  final String name;
  final String imagePath;
  final double price;
  final String category;
  final double rating;
  final bool isOrganic;

  Product(this.name, this.imagePath, this.price, this.category, this.rating, this.isOrganic);
}