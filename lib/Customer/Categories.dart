import 'package:farmer_crate/Customer/profile.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Signin.dart';
import 'Cart.dart';
import 'customerhomepage.dart';

// Enhanced Data Models (API Ready)
class Farmer {
  final String id;
  final String name;
  final double rating;
  final String location;

  Farmer({
    required this.id,
    required this.name,
    required this.rating,
    required this.location,
  });

  // Factory method for API integration
  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id'],
      name: json['name'],
      rating: json['rating'].toDouble(),
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'location': location,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String quantity;
  final String farmerId;
  final String farmerName;
  final String category;
  final String subcategory;
  final List<String> variety;
  final double rating;
  final int discount;
  final bool inStock;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.farmerId,
    required this.farmerName,
    required this.category,
    required this.subcategory,
    required this.variety,
    required this.rating,
    required this.discount,
    required this.inStock,
    required this.description,
  });

  // Factory method for API integration
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      farmerId: json['farmerId'],
      farmerName: json['farmerName'],
      category: json['category'],
      subcategory: json['subcategory'],
      variety: List<String>.from(json['variety']),
      rating: json['rating'].toDouble(),
      discount: json['discount'],
      inStock: json['inStock'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'category': category,
      'subcategory': subcategory,
      'variety': variety,
      'rating': rating,
      'discount': discount,
      'inStock': inStock,
      'description': description,
    };
  }
}

// API Service Class (Ready for implementation)
class ApiService {
  static const String baseUrl = 'https://your-api-endpoint.com/api';

  // Get all farmers
  static Future<List<Farmer>> getFarmers() async {
    // Implementation will be added when API is ready
    // Example:
    // final response = await http.get(Uri.parse('$baseUrl/farmers'));
    // if (response.statusCode == 200) {
    //   List<dynamic> data = json.decode(response.body);
    //   return data.map((farmer) => Farmer.fromJson(farmer)).toList();
    // }
    throw UnimplementedError('API not implemented yet');
  }

  // Get all products
  static Future<List<Product>> getProducts() async {
    // Implementation will be added when API is ready
    // Example:
    // final response = await http.get(Uri.parse('$baseUrl/products'));
    // if (response.statusCode == 200) {
    //   List<dynamic> data = json.decode(response.body);
    //   return data.map((product) => Product.fromJson(product)).toList();
    // }
    throw UnimplementedError('API not implemented yet');
  }

  // Get products by farmer
  static Future<List<Product>> getProductsByFarmer(String farmerId) async {
    // Implementation will be added when API is ready
    // Example:
    // final response = await http.get(Uri.parse('$baseUrl/products?farmerId=$farmerId'));
    // if (response.statusCode == 200) {
    //   List<dynamic> data = json.decode(response.body);
    //   return data.map((product) => Product.fromJson(product)).toList();
    // }
    throw UnimplementedError('API not implemented yet');
  }

  // Search products
  static Future<List<Product>> searchProducts(String query) async {
    // Implementation will be added when API is ready
    // Example:
    // final response = await http.get(Uri.parse('$baseUrl/products/search?q=$query'));
    // if (response.statusCode == 200) {
    //   List<dynamic> data = json.decode(response.body);
    //   return data.map((product) => Product.fromJson(product)).toList();
    // }
    throw UnimplementedError('API not implemented yet');
  }

  static Future<List<String>> fetchProductImages() async {
    final response = await http.get(Uri.parse('https://farmercrate.onrender.com/api/products'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List products = data['data'];
      // Extract only the image URLs
      return products.map<String>((product) => product['images'] as String).toList();
    } else {
      throw Exception('Failed to load product images');
    }
  }
}

// --- Drawer and BottomNavBar Widgets copied from customerhomepage.dart ---

class CustomerDrawer extends StatelessWidget {
  final BuildContext parentContext;
  final String? token;
  final String? customerImageUrl;
  final String? customerName;
  const CustomerDrawer({
    required this.parentContext,
    this.token,
    this.customerImageUrl,
    this.customerName,
    Key? key,
  }) : super(key: key);

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  backgroundImage: (customerImageUrl != null && customerImageUrl!.isNotEmpty)
                      ? NetworkImage(customerImageUrl!)
                      : null,
                  child: (customerImageUrl == null || customerImageUrl!.isEmpty)
                      ? Icon(Icons.person, size: 40, color: Colors.green[700])
                      : null,
                ),
                SizedBox(height: 10),
                Text(
                  customerName != null && customerName!.isNotEmpty
                      ? customerName!
                      : 'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Explore Farm Fresh Products',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
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
            icon: Icons.category,
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
            icon: Icons.shopping_cart,
            title: 'Cart',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => CartPage(customerId: 1)),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.favorite,
            title: 'Wishlist',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => WishlistPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.payment,
            title: 'Orders',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => OrdersPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => ProfilePage(token: token ?? '')),
              );
            },
          ),
          Divider(),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => HelpPage()),
              );
            },
          ),
          Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pushAndRemoveUntil(
                parentContext,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class CustomerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const CustomerBottomNavBar({required this.currentIndex, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
        currentIndex: currentIndex,
        elevation: 0,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category, size: 24),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, size: 24),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --- End Drawer and BottomNavBar Widgets ---

class CategoryPage extends StatefulWidget {
  final String? token;
  const CategoryPage({Key? key, this.token}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  Map<String, bool> _vegetableFilters = {};
  Map<String, bool> _fruitFilters = {};
  Map<String, bool> _varietyFilters = {};

  // Selected farmer
  String? _selectedFarmer;

  // View mode
  bool _isGridView = true;

  // Sort options
  String _sortBy = 'name'; // name, price, farmer
  bool _sortAscending = true;

  // Available categories
  final List<String> _vegetables = [
    'Tomatoes', 'Carrots', 'Spinach', 'Bell Peppers', 'Broccoli',
    'Cauliflower', 'Lettuce', 'Cucumber', 'Onions', 'Potatoes',
    'Cabbage', 'Radish', 'Peas', 'Beans', 'Corn'
  ];

  final List<String> _fruits = [
    'Apples', 'Bananas', 'Oranges', 'Strawberries', 'Grapes',
    'Mangoes', 'Pineapple', 'Watermelon', 'Kiwi', 'Peaches',
    'Pears', 'Cherries', 'Blueberries', 'Pomegranate', 'Papaya'
  ];

  final List<String> _varieties = [
    'Organic', 'Seasonal', 'Hydroponic', 'Pesticide-Free', 'Heirloom'
  ];

  // API farmers
  List<Farmer> _apiFarmers = [];
  bool _isLoadingFarmers = true;

  List<Product> _allProducts = [];
  bool _isLoadingImages = true;
  Product? _selectedProduct;
  // New: Store API products
  List<dynamic> _apiProducts = [];

  // Farmer names for filter
  List<Map<String, dynamic>> _farmerNames = [];

  int _currentIndex = 1; // Categories tab
  String? customerImageUrl;
  String? customerName;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize filters
    for (String veg in _vegetables) {
      _vegetableFilters[veg] = false;
    }
    for (String fruit in _fruits) {
      _fruitFilters[fruit] = false;
    }
    for (String variety in _varieties) {
      _varietyFilters[variety] = false;
    }
    _fetchImages();
    _fetchFarmerNames();
    _fetchCustomerProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    List<Product> filtered = List.from(_allProducts);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) =>
      product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.farmerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // Farmer filter
    if (_selectedFarmer != null) {
      filtered = filtered.where((product) => product.farmerId == _selectedFarmer).toList();
    }

    // Vegetable subcategory filter
    List<String> selectedVegetables = _vegetableFilters.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Fruit subcategory filter
    List<String> selectedFruits = _fruitFilters.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Variety filter
    List<String> selectedVarieties = _varietyFilters.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Apply category filters
    if (selectedVegetables.isNotEmpty || selectedFruits.isNotEmpty) {
      filtered = filtered.where((product) {
        if (selectedVegetables.isNotEmpty && product.category == 'Vegetables') {
          return selectedVegetables.contains(product.subcategory);
        }
        if (selectedFruits.isNotEmpty && product.category == 'Fruits') {
          return selectedFruits.contains(product.subcategory);
        }
        return selectedVegetables.isEmpty && selectedFruits.isEmpty;
      }).toList();
    }

    // Apply variety filters
    if (selectedVarieties.isNotEmpty) {
      filtered = filtered.where((product) {
        return selectedVarieties.any((variety) => product.variety.contains(variety));
      }).toList();
    }

    // Sort products
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'farmer':
          comparison = a.farmerName.compareTo(b.farmerName);
          break;
        case 'rating':
          comparison = a.rating.compareTo(b.rating);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _vegetableFilters.updateAll((key, value) => false);
      _fruitFilters.updateAll((key, value) => false);
      _varietyFilters.updateAll((key, value) => false);
      _selectedFarmer = null;
      _searchController.clear();
      _selectedProduct = null;
    });
  }

  void _fetchImages() async {
    try {
      final response = await http.get(Uri.parse('https://farmercrate.onrender.com/api/products'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List products = data['data'];
        setState(() {
          _allProducts = products.map<Product>((product) {
            // Farmer info may be nested under 'farmer'
            final farmer = product['farmer'];
            return Product(
              id: product['id'].toString(),
              name: product['name'] ?? '',
              imageUrl: product['images'] ?? '',
              price: double.tryParse(product['price'].toString()) ?? 0.0,
              quantity: product['quantity'].toString(),
              farmerId: farmer != null ? farmer['id'].toString() : (product['farmer_id']?.toString() ?? ''),
              farmerName: farmer != null ? farmer['name'] ?? '' : '',
              category: product['category'] ?? '',
              subcategory: '', // Not available in API
              variety: [], // Not available in API
              rating: 0.0, // Not available in API
              discount: 0, // Not available in API
              inStock: product['status'] == 'available',
              description: product['description'] ?? '',
            );
          }).toList();
          _apiProducts = products;
          _isLoadingImages = false;
        });
      } else {
        setState(() {
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  // Fetch farmers from API
  void _fetchFarmers() async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (widget.token != null) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      }
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/products/farmer'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List farmers = data['data'];
        setState(() {
          _apiFarmers = farmers.map<Farmer>((f) => Farmer(
            id: f['id'].toString(),
            name: f['name'],
            rating: f['rating'] != null ? double.tryParse(f['rating'].toString()) ?? 0.0 : 0.0,
            location: f['location'] ?? '',
          )).toList();
          _isLoadingFarmers = false;
        });
      } else {
        setState(() {
          _isLoadingFarmers = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFarmers = false;
      });
    }
  }

  // Fetch farmer names for filter
  void _fetchFarmerNames() async {
    try {
      final response = await http.get(Uri.parse('https://farmercrate.onrender.com/api/farmer/names'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _farmerNames = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      // ignore error
    }
  }

  // Helper to get API price by product name (or id if available)
  String? _getApiPrice(Product product) {
    final apiProduct = _apiProducts.firstWhere(
          (p) => (p['name'] == product.name),
      orElse: () => null,
    );
    if (apiProduct != null && apiProduct['price'] != null) {
      return apiProduct['price'].toString();
    }
    return null;
  }
  // New: Helper to get API product by id
  Map<String, dynamic>? _getApiProductById(String id) {
    return _apiProducts.firstWhere(
          (p) => p['id'].toString() == id,
      orElse: () => null,
    );
  }

  // Helper to get API farmer name by farmerId
  String _getApiFarmerName(String farmerId) {
    final farmer = _apiFarmers.firstWhere(
          (f) => f.id == farmerId,
      orElse: () => Farmer(id: '', name: '', rating: 0.0, location: ''),
    );
    return farmer.name;
  }

  // Fetch customer profile image using token
  Future<void> _fetchCustomerProfile() async {
    if (widget.token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/customers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          customerImageUrl = data['data']?['image_url'];
          customerName = data['data']?['name'];
        });
      }
    } catch (e) {
      // ignore error
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = CustomerHomePage(token: widget.token);
        break;
      case 1:
        targetPage = CategoryPage(token: widget.token);
        break;
      case 2:
        targetPage = CartPage(customerId: 1);
        break;
      case 3:
        targetPage = ProfilePage(token: widget.token ?? '');
        break;
      default:
        targetPage = CustomerHomePage(token: widget.token);
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomerDrawer(
        parentContext: context,
        token: widget.token,
        customerImageUrl: customerImageUrl,
        customerName: customerName,
      ),
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF66BB6A),
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStaticImageContainer(),
              _buildSearchAndSort(),
              _buildFiltersSection(),
              _buildProductsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Removed the back button, replaced with a menu icon to open the drawer
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF2E7D32)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const Expanded(
              child: Text(
                'Farm Fresh Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                color: const Color(0xFF2E7D32),
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticImageContainer() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _selectedProduct != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _selectedProduct!.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 80),
        ),
      )
          : Center(
        child: Icon(Icons.image, size: 80, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products, farmers...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF4CAF50)),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sort and Farmer Selection Row
          Row(
            children: [
              // Sort Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.sort, color: Color(0xFF4CAF50)),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                        DropdownMenuItem(value: 'price', child: Text('Sort by Price')),
                        DropdownMenuItem(value: 'farmer', child: Text('Sort by Farmer')),
                        DropdownMenuItem(value: 'rating', child: Text('Sort by Rating')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort Order Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF4CAF50),
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                ),
              ),
              const SizedBox(width: 7),

              // Farmer Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFarmer,
                      hint: const Text('All Farmers', style: TextStyle(fontSize: 12)),
                      icon: const Icon(Icons.person, color: Color(0xFF4CAF50)),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Farmers'),
                        ),
                        ..._farmerNames.map((farmer) => DropdownMenuItem<String>(
                          value: farmer['id'].toString(),
                          child: Text(
                            farmer['name'],
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFarmer = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        title: const Text(
          'Advanced Filters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.filter_list, color: Colors.white),
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Vegetables Section
                  _buildFilterSection('Vegetables', _vegetables, _vegetableFilters),
                  const SizedBox(height: 16),

                  // Fruits Section
                  _buildFilterSection('Fruits', _fruits, _fruitFilters),
                  const SizedBox(height: 16),

                  // Varieties Section
                  _buildFilterSection('Varieties', _varieties, _varietyFilters),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> items, Map<String, bool> filterMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return _buildCheckboxChip(item, filterMap[item] ?? false, (value) {
                setState(() {
                  filterMap[item] = value;
                });
              });
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxChip(String label, bool isSelected, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: _filteredProducts.isEmpty
            ? _buildEmptyState()
            : _isGridView
            ? _buildProductsGrid()
            : _buildProductsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedProduct = _filteredProducts[index];
            });
          },
          child: _buildProductCard(_filteredProducts[index]),
        );
      },
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedProduct = _filteredProducts[index];
            });
          },
          child: _buildProductListItem(_filteredProducts[index]),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    int productIndex = _filteredProducts.indexOf(product);
    // Get API product by id
    final apiProduct = _getApiProductById(product.id);
    final displayName = apiProduct != null && apiProduct['name'] != null ? apiProduct['name'] : product.name;
    final displayDescription = apiProduct != null && apiProduct['description'] != null ? apiProduct['description'] : product.description;
    final displayImage = apiProduct != null && apiProduct['images'] != null && apiProduct['images'].toString().isNotEmpty ? apiProduct['images'] : product.imageUrl;
    final displayPrice = apiProduct != null && apiProduct['price'] != null ? apiProduct['price'].toString() : product.price.toString();
    // Get farmer name from API if available
    final displayFarmerName = _getApiFarmerName(product.farmerId).isNotEmpty ? _getApiFarmerName(product.farmerId) : product.farmerName;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with badges
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Color(0xFFF5F5F5),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: displayImage != null && displayImage.toString().isNotEmpty
                        ? Image.network(
                      displayImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                    )
                        : Center(
                      child: Icon(Icons.image, size: 60, color: Colors.grey[400]),
                    ),
                  ),

                  // Discount Badge
                  if (product.discount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Stock Status
                  if (!product.inStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Out of Stock',
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
            ),
          ),

          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayFarmerName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 10,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product.farmerName,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (product.discount > 0) ...[
                                Text(
                                  '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                '₹$displayPrice',
                                style: const TextStyle(
                                  fontSize: 20, // Increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            product.quantity,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),

                      GestureDetector(
                        onTap: product.inStock ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart!'),
                              backgroundColor: const Color(0xFF4CAF50),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } : null,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: product.inStock ? const Color(0xFF4CAF50) : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            product.inStock ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
                            color: Colors.white,
                            size: 16,
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

  Widget _buildProductListItem(Product product) {
    int productIndex = _filteredProducts.indexOf(product);
    // Get API product by id
    final apiProduct = _getApiProductById(product.id);
    final displayName = apiProduct != null && apiProduct['name'] != null ? apiProduct['name'] : product.name;
    final displayDescription = apiProduct != null && apiProduct['description'] != null ? apiProduct['description'] : product.description;
    final displayImage = apiProduct != null && apiProduct['images'] != null && apiProduct['images'].toString().isNotEmpty ? apiProduct['images'] : product.imageUrl;
    final displayPrice = apiProduct != null && apiProduct['price'] != null ? apiProduct['price'].toString() : product.price.toString();
    // Get farmer name from API if available
    final displayFarmerName = _getApiFarmerName(product.farmerId).isNotEmpty ? _getApiFarmerName(product.farmerId) : product.farmerName;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: displayImage != null && displayImage.toString().isNotEmpty
                        ? Image.network(
                      displayImage,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                    )
                        : Icon(Icons.image, size: 60, color: Colors.grey[400]),
                  ),
                  if (product.discount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayFarmerName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.farmerName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        product.quantity,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayDescription,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: product.variety.map((variety) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          variety,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Price and Add Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (product.discount > 0) ...[
                  Text(
                    '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '₹$displayPrice',
                  style: const TextStyle(
                    fontSize: 22, // Increased font size
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: product.inStock ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart!'),
                        backgroundColor: const Color(0xFF4CAF50),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: product.inStock ? const Color(0xFF4CAF50) : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      product.inStock ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                if (!product.inStock) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Out of Stock',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}