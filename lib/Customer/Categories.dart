import 'package:farmer_crate/Customer/profile.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/Signin.dart';
import 'Cart.dart';
import 'customerhomepage.dart';
import 'order history.dart';
import 'product_details_screen.dart';
import 'navigation_utils.dart';

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


  static Future<List<Product>> searchProducts(String query) async {

    throw UnimplementedError('API not implemented yet');
  }

  static Future<List<String>> fetchProductImages() async {
    final response = await http.get(Uri.parse('https://farmercrate.onrender.com/api/products'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List products = data['data'] ?? [];
      return products.map<String>((product) {
        final images = product['images'];
        if (images is List && images.isNotEmpty) {
          // Prefer primary image, else first
          final primary = images.firstWhere(
                (img) => (img is Map) && (img['is_primary'] == true),
            orElse: () => images.first,
          );
          if (primary is Map && primary['image_url'] != null) {
            return primary['image_url'].toString();
          }
        }
        return '';
      }).toList();
    } else {
      throw Exception('Failed to load product images');
    }
  }
}





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
  bool _isSearchVisible = false;

  // Filter states
  Map<String, bool> _vegetableFilters = {};
  Map<String, bool> _fruitFilters = {};
  Map<String, bool> _varietyFilters = {};

  // Category filter (All, Vegetables, Fruits)
  String? _selectedCategory; // null => All

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

    // Category filter (simple top-level from API)
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
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
        final List products = data['data'] ?? [];
        setState(() {
          _allProducts = products.map<Product>((product) {
            // Normalize image URL from images array if present
            String imageUrl = '';
            final images = product['images'];
            if (images is List && images.isNotEmpty) {
              final primary = images.firstWhere(
                    (img) => (img is Map) && (img['is_primary'] == true),
                orElse: () => images.first,
              );
              if (primary is Map && primary['image_url'] != null) {
                imageUrl = primary['image_url'].toString();
              }
            } else if (images is String) {
              imageUrl = images; // fallback if backend sends string
            }

            // Farmer info nested under 'farmer' with keys 'farmer_id', 'name'
            final farmer = product['farmer'];
            final String farmerId = farmer != null
                ? (farmer['farmer_id']?.toString() ?? '')
                : (product['farmer_id']?.toString() ?? '');
            final String farmerName = farmer != null ? (farmer['name']?.toString() ?? '') : '';

            // Determine stock based on status and quantity (if available)
            final String status = (product['status']?.toString() ?? '').toLowerCase();
            final int quantityVal = int.tryParse(product['quantity']?.toString() ?? '') ?? 0;
            final bool inStock = status == 'available' && quantityVal > 0;

            return Product(
              id: product['product_id']?.toString() ?? product['id']?.toString() ?? '',
              name: product['name']?.toString() ?? '',
              imageUrl: imageUrl,
              price: double.tryParse(product['current_price']?.toString() ?? product['price']?.toString() ?? '0') ?? 0.0,
              quantity: product['quantity']?.toString() ?? '0',
              farmerId: farmerId,
              farmerName: farmerName,
              category: product['category']?.toString() ?? '',
              subcategory: '', // Not available in API
              variety: const [], // Not available in API
              rating: 0.0, // Not available in API
              discount: 0, // Not available in API
              inStock: inStock,
              description: product['description']?.toString() ?? '',
            );
          }).toList();

          // Keep a normalized copy of API products with a computed primary image URL
          _apiProducts = products.map((p) {
            String primaryImage = '';
            final imgs = p['images'];
            if (imgs is List && imgs.isNotEmpty) {
              final primary = imgs.firstWhere(
                    (img) => (img is Map) && (img['is_primary'] == true),
                orElse: () => imgs.first,
              );
              if (primary is Map && primary['image_url'] != null) {
                primaryImage = primary['image_url'].toString();
              }
            } else if (imgs is String) {
              primaryImage = imgs;
            }
            return {
              ...p,
              'primary_image_url': primaryImage,
            };
          }).toList();
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
    for (final p in _apiProducts) {
      try {
        if (p is Map && p['name'] == product.name) {
          final price = p['current_price'] ?? p['price'];
          if (price != null) return price.toString();
          break;
        }
      } catch (_) {
        // ignore malformed entries
      }
    }
    return null;
  }
  // New: Helper to get API product by id
  Map<String, dynamic>? _getApiProductById(String id) {
    for (final p in _apiProducts) {
      try {
        if (p is Map) {
          final pid = (p['product_id']?.toString() ?? p['id']?.toString() ?? '');
          if (pid == id) return p as Map<String, dynamic>;
        }
      } catch (_) {
        // ignore malformed entries
      }
    }
    return null;
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
    if (index != _currentIndex) {
      Widget targetPage;
      switch (index) {
        case 0:
          targetPage = CustomerHomePage(token: widget.token);
          break;
        case 1:
          targetPage = CategoryPage(token: widget.token);
          break;
        case 2:
          targetPage = CartPage(token: widget.token);
          break;
        case 3:
          targetPage = CustomerProfilePage(token: widget.token ?? '');
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
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const Text('Sort & Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Sort options
                    const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Name'),
                          selected: _sortBy == 'name',
                          onSelected: (_) { setState(() => _sortBy = 'name'); },
                        ),
                        ChoiceChip(
                          label: const Text('Price'),
                          selected: _sortBy == 'price',
                          onSelected: (_) { setState(() => _sortBy = 'price'); },
                        ),
                        ChoiceChip(
                          label: const Text('Farmer'),
                          selected: _sortBy == 'farmer',
                          onSelected: (_) { setState(() => _sortBy = 'farmer'); },
                        ),
                        ChoiceChip(
                          label: const Text('Rating'),
                          selected: _sortBy == 'rating',
                          onSelected: (_) { setState(() => _sortBy = 'rating'); },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sort order
                    Row(
                      children: [
                        const Text('Order', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                          onPressed: () { setState(() => _sortAscending = !_sortAscending); },
                        ),
                      ],
                    ),

                    const Divider(),

                    // Farmer selector
                    const SizedBox(height: 8),
                    const Text('Farmer', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedFarmer,
                      isExpanded: true,
                      hint: const Text('All Farmers'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Farmers')),
                        ..._farmerNames.map((farmer) => DropdownMenuItem<String>(
                          value: farmer['id'].toString(),
                          child: Text(farmer['name']),
                        )).toList(),
                      ],
                      onChanged: (val) { setState(() => _selectedFarmer = val); },
                    ),

                    const Divider(),

                    // Advanced filter checkboxes
                    const SizedBox(height: 8),
                    const Text('Vegetables', style: TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 8,
                      children: _vegetables.map((v) => FilterChip(
                        label: Text(v, style: const TextStyle(fontSize: 12)),
                        selected: _vegetableFilters[v] ?? false,
                        onSelected: (sel) => setState(() => _vegetableFilters[v] = sel),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Fruits', style: TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 8,
                      children: _fruits.map((v) => FilterChip(
                        label: Text(v, style: const TextStyle(fontSize: 12)),
                        selected: _fruitFilters[v] ?? false,
                        onSelected: (sel) => setState(() => _fruitFilters[v] = sel),
                      )).toList(),
                    ),

                    const SizedBox(height: 12),
                    const Text('Varieties', style: TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 8,
                      children: _varieties.map((v) => FilterChip(
                        label: Text(v, style: const TextStyle(fontSize: 12)),
                        selected: _varietyFilters[v] ?? false,
                        onSelected: (sel) => setState(() => _varietyFilters[v] = sel),
                      )).toList(),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            _clearFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear All'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Apply'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerHomePage(token: widget.token),
          ),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: CustomerNavigationUtils.buildGlassmorphicAppBar(
          title: 'Categories',
          showSearch: _isSearchVisible,
          searchController: _searchController,
          onSearchToggle: () {
            setState(() {
              _isSearchVisible = !_isSearchVisible;
              if (!_isSearchVisible) {
                _searchController.clear();
              }
            });
          },
          onRefresh: () {
            _fetchImages();
            _fetchFarmerNames();
          },
          onCartTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartPage(token: widget.token)),
            );
          },
        ),
        drawer: CustomerNavigationUtils.buildCustomerDrawer(
          parentContext: context,
          token: widget.token,
          customerImageUrl: customerImageUrl,
          customerName: customerName,
          isLoadingProfile: false,
        ),
        bottomNavigationBar: CustomerNavigationUtils.buildCustomerBottomNav(
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
                _buildSearchAndSort(),
                _buildCategoryChips(),
                const SizedBox(height: 8),
                _buildActiveChips(),
                _buildProductsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }




  Widget _buildSearchAndSort() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: TextButton.icon(
                icon: const Icon(Icons.tune, color: Color(0xFF4CAF50)),
                label: const Text('Filters', style: TextStyle(color: Colors.black87)),
                onPressed: () => _openFilterSheet(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Active filter chips row
  Widget _buildActiveChips() {
    final chips = <Widget>[];

    if (_selectedFarmer != null && _selectedFarmer!.isNotEmpty) {
      final farmerName = _farmerNames.firstWhere(
            (f) => f['id'].toString() == _selectedFarmer,
        orElse: () => {'name': 'Farmer'},
      )['name'];
      chips.add(_filterChip('${farmerName ?? 'Farmer'}', () {
        setState(() => _selectedFarmer = null);
      }));
    }

    // Note: sort chip removed per request — sorting control is in the header controls

    _vegetableFilters.forEach((k, v) {
      if (v) chips.add(_filterChip(k, () { setState(() => _vegetableFilters[k] = false); }));
    });
    _fruitFilters.forEach((k, v) {
      if (v) chips.add(_filterChip(k, () { setState(() => _fruitFilters[k] = false); }));
    });
    _varietyFilters.forEach((k, v) {
      if (v) chips.add(_filterChip(k, () { setState(() => _varietyFilters[k] = false); }));
    });

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      chips.add(_filterChip(_selectedCategory!, () { setState(() => _selectedCategory = null); }));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()),
      ),
    );
  }

  // Simple category selector chips
  Widget _buildCategoryChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (_) { setState(() => _selectedCategory = null); },
          ),
          ChoiceChip(
            label: const Text('Vegetables'),
            selected: _selectedCategory == 'Vegetables',
            onSelected: (_) { setState(() => _selectedCategory = 'Vegetables'); },
          ),
          ChoiceChip(
            label: const Text('Fruits'),
            selected: _selectedCategory == 'Fruits',
            onSelected: (_) { setState(() => _selectedCategory = 'Fruits'); },
          ),
          ChoiceChip(
            label: const Text('Grains'),
            selected: _selectedCategory == 'Grains',
            onSelected: (_) { setState(() => _selectedCategory = 'Grains'); },
          ),
          ChoiceChip(
            label: const Text('Pulses'),
            selected: _selectedCategory == 'Pulses',
            onSelected: (_) { setState(() => _selectedCategory = 'Pulses'); },
          ),
          ChoiceChip(
            label: const Text('Dairy'),
            selected: _selectedCategory == 'Dairy',
            onSelected: (_) { setState(() => _selectedCategory = 'Dairy'); },
          ),
          ChoiceChip(
            label: const Text('Eggs'),
            selected: _selectedCategory == 'Eggs',
            onSelected: (_) { setState(() => _selectedCategory = 'Eggs'); },
          ),
          ChoiceChip(
            label: const Text('Meat'),
            selected: _selectedCategory == 'Meat',
            onSelected: (_) { setState(() => _selectedCategory = 'Meat'); },
          ),
          ChoiceChip(
            label: const Text('Herbs'),
            selected: _selectedCategory == 'Herbs',
            onSelected: (_) { setState(() => _selectedCategory = 'Herbs'); },
          ),
          ChoiceChip(
            label: const Text('Spices'),
            selected: _selectedCategory == 'Spices',
            onSelected: (_) { setState(() => _selectedCategory = 'Spices'); },
          ),
          ChoiceChip(
            label: const Text('Beverages'),
            selected: _selectedCategory == 'Beverages',
            onSelected: (_) { setState(() => _selectedCategory = 'Beverages'); },
          ),
          ChoiceChip(
            label: const Text('Flowers'),
            selected: _selectedCategory == 'Flowers',
            onSelected: (_) { setState(() => _selectedCategory = 'Flowers'); },
          ),
          ChoiceChip(
            label: const Text('Others'),
            selected: _selectedCategory == 'Others',
            onSelected: (_) { setState(() => _selectedCategory = 'Others'); },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: const Color(0xFF4CAF50))),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }

  Widget _buildFiltersSection() {
    // Advanced filter moved to combined Filters bottom sheet.
    // Keep this method as a no-op to avoid showing the old ExpansionTile.
    return const SizedBox.shrink();
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
    if (_isLoadingImages) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[50]!,
                Colors.white,
                Colors.green[50]!,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                  ).createShader(bounds),
                  child: Text(
                    'Loading products...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
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
            final product = _filteredProducts[index];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  productId: int.tryParse(product.id) ?? 0,
                  token: widget.token ?? '',
                ),
              ),
            );
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
            final product = _filteredProducts[index];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  productId: int.tryParse(product.id) ?? 0,
                  token: widget.token ?? '',
                ),
              ),
            );
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
    final displayImage = () {
      if (apiProduct == null) return product.imageUrl;
      // Prefer normalized primary image URL
      final primary = apiProduct['primary_image_url'];
      if (primary != null && primary.toString().isNotEmpty) return primary.toString();
      // Fallback to images list/string
      final imgs = apiProduct['images'];
      if (imgs is List && imgs.isNotEmpty) {
        final first = imgs.first;
        if (first is Map && first['image_url'] != null) return first['image_url'].toString();
      } else if (imgs is String && imgs.isNotEmpty) {
        return imgs;
      }
      return product.imageUrl;
    }();
    final displayPrice = apiProduct != null && (apiProduct['current_price'] != null || apiProduct['price'] != null)
        ? (apiProduct['current_price'] ?? apiProduct['price']).toString()
        : product.price.toString();
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayFarmerName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Farmer rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  product.rating > 0 ? product.rating.toStringAsFixed(1) : '—',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
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
    final displayImage = () {
      if (apiProduct == null) return product.imageUrl;
      final primary = apiProduct['primary_image_url'];
      if (primary != null && primary.toString().isNotEmpty) return primary.toString();
      final imgs = apiProduct['images'];
      if (imgs is List && imgs.isNotEmpty) {
        final first = imgs.first;
        if (first is Map && first['image_url'] != null) return first['image_url'].toString();
      } else if (imgs is String && imgs.isNotEmpty) {
        return imgs;
      }
      return product.imageUrl;
    }();
    final displayPrice = apiProduct != null && (apiProduct['current_price'] != null || apiProduct['price'] != null)
        ? (apiProduct['current_price'] ?? apiProduct['price']).toString()
        : product.price.toString();
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayFarmerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              product.rating > 0 ? product.rating.toStringAsFixed(1) : '—',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
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