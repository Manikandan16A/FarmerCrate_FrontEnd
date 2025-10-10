import 'package:farmer_crate/Customer/profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Categories.dart';
import 'Cart.dart';

import 'FAQpage.dart';
import 'product_details_screen.dart';

class CustomerHomePage extends StatefulWidget {
  final String? token;

  const CustomerHomePage({Key? key, this.token}) : super(key: key);

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'All';
  bool _isLoading = true;
  List<Product> products = [];
  List<Product> topBuys = [];
  int _currentIndex = 0;



  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  String? customerImageUrl;
  String? customerName;
  bool _isLoadingProfile = true;

  final List<String> categories = [
    'All', 'Vegetables', 'Fruits', 'Herbs'
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchProducts();
    _fetchCustomerProfile();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/products'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null && widget.token!.isNotEmpty) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> productsData = responseData['data'];

        setState(() {
          // Convert JSON data to Product objects using fromJson factory
          products = productsData.map((data) => Product.fromJson(data)).toList();

          // Sort products by views and take top 3 for featured section
          final sortedProducts = List<Product>.from(products);
          sortedProducts.sort((a, b) => b.views.compareTo(a.views));
          topBuys = sortedProducts.take(3).toList();

          _isLoading = false;
        });
      } else {
        setState(() {
          products = [];
          topBuys = [];
          _isLoading = false;
        });

        // Show error message for failed API call
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to load products. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchProducts,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        products = [];
        topBuys = [];
        _isLoading = false;
      });

      // Show error message for network issues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Network error. Please check your connection.'),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _fetchProducts,
          ),
        ),
      );
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
        targetPage = CartPage(token: widget.token);
        break;
      case 3:
        targetPage = FAQPage(token: widget.token);
        break;

      case 4:
        targetPage = CustomerProfilePage(token: widget.token);
        break;
      default:
        targetPage = CustomerHomePage(token: widget.token);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );

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

  Future<void> _fetchCustomerProfile() async {
    if (widget.token == null) {
      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/customers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Profile API Response: $data');
        setState(() {
          customerImageUrl = data['data']?['image_url'] ?? data['data']?['imageUrl'] ?? data['data']?['profile_image'];
          customerName = data['data']?['customer_name'] ??
              data['data']?['name'] ??
              data['data']?['username'] ??
              data['data']?['full_name'] ??
              data['data']?['first_name'];
          print('Customer Image URL: $customerImageUrl');
          print('Customer Name: $customerName');
          _isLoadingProfile = false;
        });
      } else {
        print('Profile API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      // ignore error, fallback to default icon
      print('Error fetching customer profile: $e');
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<List<ProductReview>> _fetchProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/products/$productId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> reviewsData = jsonDecode(response.body)['data'] ?? [];
        return reviewsData.map((review) => ProductReview.fromJson(review)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  Future<void> _refreshProductReviews(Product product) async {
    final reviews = await _fetchProductReviews(product.id);
    setState(() {
      final productIndex = products.indexWhere((p) => p.id == product.id);
      if (productIndex != -1) {
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          quantity: product.quantity,
          images: product.images,
          category: product.category,
          status: product.status,
          farmerId: product.farmerId,
          views: product.views,
          farmer: product.farmer,
          rating: reviews.isNotEmpty ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length : 0.0,
          reviewCount: reviews.length,
          reviews: reviews,
        );
        products[productIndex] = updatedProduct;

        // Update topBuys if this product is in it
        final topBuyIndex = topBuys.indexWhere((p) => p.id == product.id);
        if (topBuyIndex != -1) {
          topBuys[topBuyIndex] = updatedProduct;
        }
      }
    });
  }

  Widget _buildRatingStars(double rating, {double size = 16.0}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber[600], size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: Colors.amber[600], size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[400], size: size);
        }
      }),
    );
  }

  Widget _buildReviewSection(Product product) {
    return GestureDetector(
      onTap: () => _showAllReviews(product),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildRatingStars(product.rating, size: 14),
                SizedBox(width: 6),
                Text(
                  '${product.rating.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '(${product.reviewCount})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: Colors.grey[400],
                ),
              ],
            ),
            if (product.reviews.isNotEmpty) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.green[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product.reviews.first.comment,
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactReviewSection(Product product) {
    return GestureDetector(
      onTap: () => _showAllReviews(product),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _buildRatingStars(product.rating, size: 12),
            SizedBox(width: 4),
            Text(
              '${product.rating.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(width: 2),
            Text(
              '(${product.reviewCount})',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 8,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReviewCard(ProductReview review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green[100],
                backgroundImage: review.customerImage != null && review.customerImage!.isNotEmpty
                    ? NetworkImage(review.customerImage!)
                    : null,
                child: review.customerImage == null || review.customerImage!.isEmpty
                    ? Icon(Icons.person, size: 16, color: Colors.green[600])
                    : null,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              _buildRatingStars(review.rating, size: 16),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else {
        return '${(difference.inDays / 30).floor()} months ago';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatProductDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showAllReviews(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        _buildRatingStars(product.rating, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${product.rating.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount} reviews)',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () async {
                            await _refreshProductReviews(product);
                            setModalState(() {});
                          },
                          icon: Icon(Icons.refresh, color: Colors.green[600]),
                          tooltip: 'Refresh reviews',
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: product.reviews.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.reviews, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to review this product!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Review form coming soon!'),
                              backgroundColor: Colors.green[600],
                            ),
                          );
                        },
                        icon: Icon(Icons.rate_review, size: 16),
                        label: Text('Write Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: product.reviews.length,
                  itemBuilder: (context, index) {
                    return _buildDetailedReviewCard(product.reviews[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please login to add items to cart'),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      print('Adding product ${product.id} to cart with token: ${widget.token!.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'productId': product.id,
          'quantity': 1,
        }),
      );

      print('Add to cart response status: ${response.statusCode}');
      print('Add to cart response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('${product.name} added to cart!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(token: widget.token),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to add to cart';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(errorMessage),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Network error. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FDF8),
      extendBodyBehindAppBar: true,
      appBar: _buildGlassmorphicAppBar(),
      drawer: CustomerDrawer(
        parentContext: context,
        token: widget.token,
        customerImageUrl: customerImageUrl,
        customerName: customerName,
        isLoadingProfile: _isLoadingProfile,
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchProducts,
            child: CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 100)),
                _buildWelcomeSection(),
                _buildSearchBar(),
                _buildCategories(),
                _buildTopBuysSection(),
                _buildSuggestedSection(),
                _buildSuggestedProductGrid(),
                SliverToBoxAdapter(child: SizedBox(height: 80)), // Reduced bottom padding
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildGlassmorphicBottomNav(),
    );
  }

  PreferredSizeWidget _buildGlassmorphicAppBar() {
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
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.menu, color: Colors.green[800], size: 20),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.green[800]!, Colors.green[600]!],
        ).createShader(bounds),
        child: Text(
          'FarmerCrate',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.refresh, color: Colors.green[800], size: 20),
            ),
            onPressed: _fetchProducts,
            tooltip: 'Refresh Products',
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.shopping_cart, color: Colors.green[800], size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage(token: widget.token)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.green[700]!, Colors.green[500]!],
              ).createShader(bounds),
              child: Text(
                'Loading fresh products...',
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
    );
  }

  Widget _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerName != null && customerName!.isNotEmpty
                    ? ' $customerName'
                    : 'Welcome!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.green[800]!, Colors.green[600]!],
                ).createShader(bounds),
                child: Text(
                  'Discover fresh, organic produce',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'from local farms near you',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search for fresh products...',
                  prefixIcon: Container(
                    margin: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            _buildProfileCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerProfilePage(token: widget.token ?? ''),
                ),
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
                          'Keep your information fresh & up-to-date',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap here to update your profile',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
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
                        : customerImageUrl != null && customerImageUrl!.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        customerImageUrl!,
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
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        margin: EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory == category;

            return GestureDetector(
              onTap: () => setState(() => selectedCategory = category),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [Colors.green[500]!, Colors.green[700]!],
                  )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.green[300]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.green.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: isSelected ? 15 : 10,
                      offset: Offset(0, isSelected ? 5 : 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.green[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 15,
                    ),
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
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.trending_up, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Top Buys This Week',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                Text(
                  '🔥',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          Container(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: topBuys.length,
              itemBuilder: (context, index) {
                return _buildPremiumHorizontalCard(topBuys[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHorizontalCard(Product product, int index) {
    final responsiveValues = _getResponsiveValues(context);
    final imageHeight = (responsiveValues['imageHeight'] as double) * 0.7; // Smaller for horizontal cards
    final padding = responsiveValues['padding'] as double;
    final titleFontSize = (responsiveValues['titleFontSize'] as double) * 0.9;
    final descriptionFontSize = (responsiveValues['descriptionFontSize'] as double) * 0.9;
    final priceFontSize = (responsiveValues['priceFontSize'] as double) * 0.9;

    return GestureDetector(
      onTap: () {
        // Convert Product object to Map for ProductDetailScreen
        final productMap = {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'quantity': product.quantity,
          'images': product.images,
          'category': product.category,
          'rating': product.rating,
          'reviewCount': product.reviewCount,
          'reviews': product.reviews.map((review) => {
            'id': review.id,
            'customer_name': review.customerName,
            'rating': review.rating,
            'comment': review.comment,
            'created_at': review.createdAt,
            'customer_image': review.customerImage,
          }).toList(),
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: product.id,
              token: widget.token ?? '',
              productData: productMap,
            ),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: imageHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green[100]!,
                        Colors.green[50]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Center(
                    child: _buildProductImage(
                      product.images,
                      70,
                      70,
                      _getProductIcon(product.name),
                      35,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.orange[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${index + 1}',
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
                  right: 8,
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding * 0.75, vertical: padding * 0.25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleFontSize,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 4),
                    if (product.harvestDate != null || product.expiryDate != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.harvestDate != null)
                            Text(
                              'Harvest: ${_formatProductDate(product.harvestDate)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (product.expiryDate != null)
                            Text(
                              'Expires: ${_formatProductDate(product.expiryDate)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.orange[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    SizedBox(height: 2),
                    _buildCompactReviewSection(product),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: priceFontSize,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildSuggestedSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.recommend, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Products',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Spacer(),
            Text(
              '✨',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedProductGrid() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: _getResponsiveGridDelegate(context),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final product = filteredProducts[index];
            return _buildPremiumProductCard(product);
          },
          childCount: filteredProducts.length,
        ),
      ),
    );
  }

  SliverGridDelegate _getResponsiveGridDelegate(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive values based on screen size
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (screenWidth < 320) {
      // Very small screens (old phones)
      crossAxisCount = 1;
      childAspectRatio = 1.2;
      crossAxisSpacing = 12;
      mainAxisSpacing = 12;
    } else if (screenWidth < 375) {
      // Small screens (iPhone SE, etc.)
      crossAxisCount = 1;
      childAspectRatio = 1.1;
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else if (screenWidth < 414) {
      // Medium screens (iPhone 12, etc.)
      crossAxisCount = 2;
      childAspectRatio = 0.8;
      crossAxisSpacing = 12;
      mainAxisSpacing = 12;
    } else if (screenWidth < 480) {
      // Large screens (iPhone 12 Pro Max, etc.)
      crossAxisCount = 2;
      childAspectRatio = 0.75;
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else {
      // Very large screens (tablets in portrait)
      crossAxisCount = 2;
      childAspectRatio = 0.7;
      crossAxisSpacing = 20;
      mainAxisSpacing = 20;
    }

    // Adjust aspect ratio based on screen height to prevent overflow
    if (screenHeight < 600) {
      childAspectRatio = childAspectRatio * 1.1; // Make cards taller on short screens
    } else if (screenHeight > 800) {
      childAspectRatio = childAspectRatio * 0.9; // Make cards shorter on tall screens
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  // Helper method to get responsive values
  Map<String, dynamic> _getResponsiveValues(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double titleFontSize;
    double descriptionFontSize;
    double priceFontSize;
    double padding;
    double imageHeight;

    if (screenWidth < 320) {
      // Very small screens
      titleFontSize = 14;
      descriptionFontSize = 10;
      priceFontSize = 16;
      padding = 6;
      imageHeight = 120;
    } else if (screenWidth < 375) {
      // Small screens
      titleFontSize = 15;
      descriptionFontSize = 11;
      priceFontSize = 17;
      padding = 8;
      imageHeight = 130;
    } else if (screenWidth < 414) {
      // Medium screens
      titleFontSize = 16;
      descriptionFontSize = 12;
      priceFontSize = 18;
      padding = 8;
      imageHeight = 140;
    } else {
      // Large screens
      titleFontSize = 16;
      descriptionFontSize = 12;
      priceFontSize = 18;
      padding = 8;
      imageHeight = 140;
    }

    // Adjust for very short screens
    if (screenHeight < 600) {
      titleFontSize *= 0.9;
      descriptionFontSize *= 0.9;
      priceFontSize *= 0.9;
      padding *= 0.8;
      imageHeight *= 0.9;
    }

    return {
      'titleFontSize': titleFontSize,
      'descriptionFontSize': descriptionFontSize,
      'priceFontSize': priceFontSize,
      'padding': padding,
      'imageHeight': imageHeight,
    };
  }

  Widget _buildPremiumProductCard(Product product) {
    final responsiveValues = _getResponsiveValues(context);
    final imageHeight = responsiveValues['imageHeight'] as double;
    final padding = responsiveValues['padding'] as double;
    final titleFontSize = responsiveValues['titleFontSize'] as double;
    final descriptionFontSize = responsiveValues['descriptionFontSize'] as double;
    final priceFontSize = responsiveValues['priceFontSize'] as double;

    return GestureDetector(
        onTap: () {
          // Convert Product object to Map for ProductDetailScreen
          final productMap = {
            'product_id': product.id,
            'name': product.name,
            'description': product.description,
            'current_price': product.price.toString(),
            'quantity': product.quantity,
            'images': product.images,
            'category': product.category,
            'status': product.status,
            'harvest_date': product.harvestDate?.toIso8601String(),
            'expiry_date': product.expiryDate?.toIso8601String(),
            'views': product.views,
            'farmer': {
              'farmer_id': product.farmer.id,
              'global_farmer_id': product.farmer.globalId,
              'name': product.farmer.name,
              'image_url': product.farmer.imageUrl,
              'is_verified_by_gov': product.farmer.isVerifiedByGov,
            },
            'rating': product.rating,
            'review_count': product.reviewCount,
            'reviews': product.reviews.map((review) => {
              'id': review.id,
              'customer_name': review.customerName,
              'rating': review.rating,
              'comment': review.comment,
              'created_at': review.createdAt,
              'customer_image': review.customerImage,
            }).toList(),
          };

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product.id,
                token: widget.token ?? '',
                productData: productMap,
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
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
              height: imageHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: _buildProductImage(
                  product.images,
                  double.infinity,
                  imageHeight,
                  _getProductIcon(product.name),
                  55,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: descriptionFontSize,
                      color: Colors.grey[500],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      if (product.harvestDate != null)
                  Container(
              margin: EdgeInsets.only(bottom: 4),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Harvest: ${_formatProductDate(product.harvestDate)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (product.expiryDate != null)
        Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
    color: Colors.orange[50],
    borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
    'Expires: ${_formatProductDate(product.expiryDate)}',
    style: TextStyle(
    fontSize: 10,
    color: Colors.orange[600],
    fontWeight: FontWeight.w600,
    ),
    ),
        ),
                      ],
                  ),
                      SizedBox(height: 6),
                      _buildReviewSection(product),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: priceFontSize,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _addToCart(product),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
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
        ),
    );
  }

  Widget _buildGlassmorphicBottomNav() {
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
                  _currentIndex == 1 ? Icons.category : Icons.category_outlined,
                  size: 22,
                ),
              ),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 2 ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  size: 22,
                ),
              ),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 3 ? Icons.help : Icons.help_outline,
                  size: 22,
                ),
              ),
              label: 'FAQ',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentIndex == 4 ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 4 ? Icons.person : Icons.person_outline,
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

  IconData _getProductIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('tomato')) return Icons.local_florist;
    if (name.contains('apple')) return Icons.apple;
    if (name.contains('carrot')) return Icons.eco;
    if (name.contains('banana')) return Icons.eco;
    if (name.contains('pepper')) return Icons.local_florist;
    if (name.contains('strawberry')) return Icons.eco;
    if (name.contains('lettuce')) return Icons.grass;
    if (name.contains('spinach')) return Icons.grass;
    if (name.contains('basil')) return Icons.grass;
    if (name.contains('corn')) return Icons.eco;
    return Icons.eco;
  }



  Widget _buildProductImage(String? imageUrl, double width, double height, IconData fallbackIcon, double iconSize) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == 'null') {
      return _buildFallbackImage(width, height, fallbackIcon, iconSize);
    }

    String cleanUrl = imageUrl.trim();
    if (cleanUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          cleanUrl,
          width: width == double.infinity ? null : width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage(width, height, fallbackIcon, iconSize);
          },
        ),
      );
    }
    return _buildFallbackImage(width, height, fallbackIcon, iconSize);
  }

  Widget _buildFallbackImage(double width, double height, IconData fallbackIcon, double iconSize) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(fallbackIcon, size: iconSize, color: Colors.green[600]),
    );
  }
}

class Farmer {
  final int id;
  final String globalId;
  final String name;
  final String mobileNumber;
  final String email;
  final String address;
  final String zone;
  final String state;
  final String district;
  final String? imageUrl;
  final bool isVerifiedByGov;

  Farmer({
    required this.id,
    required this.globalId,
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.zone,
    required this.state,
    required this.district,
    this.imageUrl,
    required this.isVerifiedByGov,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['farmer_id'],
      globalId: json['global_farmer_id'],
      name: json['name'],
      mobileNumber: json['mobile_number'],
      email: json['email'],
      address: json['address'],
      zone: json['zone'],
      state: json['state'],
      district: json['district'],
      imageUrl: json['image_url'],
      isVerifiedByGov: json['is_verified_by_gov'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String? images;
  final String category;
  final String status;
  final DateTime? harvestDate;
  final DateTime? expiryDate;
  final int farmerId;
  final int views;
  final double rating;
  final int reviewCount;
  final List<ProductReview> reviews;
  final Farmer farmer;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.images,
    required this.category,
    required this.status,
    this.harvestDate,
    this.expiryDate,
    required this.farmerId,
    required this.views,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.reviews = const [],
    required this.farmer,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['current_price'] ?? '0.0') ?? 0.0,
      quantity: json['quantity'] ?? 0,
      images: json['images'],
      category: json['category'] ?? 'Uncategorized',
      status: json['status'] ?? 'available',
      harvestDate: json['harvest_date'] != null ? DateTime.parse(json['harvest_date']) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      farmerId: json['farmer_id'] ?? 0,
      views: json['views'] ?? 0,
      rating: 0.0, // Initialize with default value as ratings are managed separately
      reviewCount: 0, // Initialize with default value as reviews are managed separately
      reviews: [], // Initialize empty as reviews are fetched separately
      farmer: json['farmer'] != null ? Farmer.fromJson(json['farmer']) : Farmer(
        id: 0,
        globalId: '',
        name: '',
        mobileNumber: '',
        email: '',
        address: '',
        zone: '',
        state: '',
        district: '',
        isVerifiedByGov: false,
      ),
    );
  }
}

class ProductReview {
  final int id;
  final String customerName;
  final double rating;
  final String comment;
  final String createdAt;
  final String? customerImage;

  ProductReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.customerImage,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] ?? json['review_id'] ?? 0,
      customerName: json['customer_name'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      customerImage: json['customer_image'],
    );
  }
}

// Placeholder pages - you'll need to create these separately


class OrdersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Orders Yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Settings Page',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Help & Support',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}