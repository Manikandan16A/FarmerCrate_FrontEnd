import 'package:flutter/material.dart';
import 'homepage.dart';
import '../Signin.dart';
import 'ProductEdit.dart';
import 'farmerprofile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../utils/cloudinary_upload.dart';


class AddProductPage extends StatefulWidget {
  final String? token;

  const AddProductPage({Key? key, this.token}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedCategory = 'Fruits';
  int _quantity = 0;
  int _currentIndex = 1;
  bool _showResetMessage = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSuccessMessage = false;

  final List<String> _categories = [
    'Fruits',
    'Vegetables',
    'Grains',
    'Dairy',
    'Herbs',
    'Poultry',
    'Fish',
    'Nuts',
    'Spices',
    'Other'
  ];

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
        targetPage = FarmersHomePage(token: widget.token);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  Future<void> addProduct() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Product name is required');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Product description is required');
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      _showErrorSnackBar('Product price is required');
      return;
    }

    double? price;
    try {
      price = double.parse(_priceController.text.trim());
      if (price <= 0) {
        _showErrorSnackBar('Price must be greater than 0');
        return;
      }
    } catch (e) {
      _showErrorSnackBar('Please enter a valid price');
      return;
    }

    if (_selectedCategory.isEmpty) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    if (_quantity <= 0) {
      _showErrorSnackBar('Quantity must be greater than 0');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSuccessMessage = false;
    });

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await CloudinaryUploader.uploadImage(_selectedImage!);
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to upload image. Please try again.';
        });
        return;
      }
    }

    final uri = Uri.parse('https://farmercrate.onrender.com/api/products');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (widget.token != null && widget.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': price,
          'quantity': _quantity,
          'category': _selectedCategory,
          'images': imageUrl,
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Request timed out. Please try again.';
          });
          return http.Response('Timeout', 408);
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetForm();
        setState(() {
          _showSuccessMessage = true;
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showSuccessMessage = false;
            });
          }
        });
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to add product. Please try again.';
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error. Please check your connection and try again.';
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _saveProduct() {
    _animationController.forward().then((_) {
      _animationController.reverse();
      addProduct();
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _quantity = 0;
      _selectedCategory = 'Fruits';
      _selectedImage = null;
      _showResetMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showResetMessage = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FDF8),
        elevation: 0,
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.menu, color: Colors.green[700]),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add New Product',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.agriculture, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'FarmerCrate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome, Farmer!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(Icons.home, 'Home', () => _onNavItemTapped(0)),
              _buildDrawerItem(Icons.add_circle, 'Add Product', () => _onNavItemTapped(1)),
              _buildDrawerItem(Icons.edit, 'Edit Products', () => _onNavItemTapped(2)),
              _buildDrawerItem(Icons.contact_mail, 'Contact Admin', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FarmersHomePage(token: widget.token)),
                );
              }),
              _buildDrawerItem(Icons.person, 'Profile', () => _onNavItemTapped(3)),
              const Divider(color: Colors.green, thickness: 1),
              _buildDrawerItem(Icons.logout, 'Logout', () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              }, isLogout: true),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.local_florist, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Share Your Harvest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add your fresh products to reach more customers',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Loading Indicator
            if (_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Adding Product...',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoading) const SizedBox(height: 20),

            // Success Message
            if (_showSuccessMessage)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Product added successfully!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FarmerProductsPage(token: widget.token),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'View Products',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showSuccessMessage = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Add Another',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_showSuccessMessage) const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'OK',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                              addProduct();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 20),

            // Reset Message
            if (_showResetMessage)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Form reset successfully! Ready to add another product.',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_showResetMessage) const SizedBox(height: 20),

            // Image Upload Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: _selectedImage != null
                            ? null
                            : LinearGradient(
                          colors: [Colors.green[50]!, Colors.green[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green[200]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: _selectedImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                _selectedImage!,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green[400]!, Colors.green[600]!],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '📸 Tap to upload beautiful product photos',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Form Fields Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnhancedLabel('Product Name', Icons.inventory),
                  const SizedBox(height: 12),
                  _buildEnhancedTextField(
                    controller: _nameController,
                    hintText: 'Give your product a catchy name',
                    icon: Icons.edit,
                  ),
                  const SizedBox(height: 20),

                  _buildEnhancedLabel('Description', Icons.description),
                  const SizedBox(height: 12),
                  _buildEnhancedTextField(
                    controller: _descriptionController,
                    hintText: 'Describe what makes your product special',
                    maxLines: 3,
                    icon: Icons.notes,
                  ),
                  const SizedBox(height: 20),

                  _buildEnhancedLabel('Category', Icons.category),
                  const SizedBox(height: 12),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEnhancedLabel('Price', Icons.currency_rupee),
                            const SizedBox(height: 12),
                            _buildEnhancedTextField(
                              controller: _priceController,
                              hintText: 'Enter price',
                              keyboardType: TextInputType.number,
                              icon: Icons.attach_money,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEnhancedLabel('Quantity', Icons.inventory_2),
                            const SizedBox(height: 12),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green[200]!, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.green[50],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.green[300]!, Colors.green[500]!],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        if (_quantity > 0) {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: Colors.white,
                                      child: Center(
                                        child: Text(
                                          _quantity.toString(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 50,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.green[300]!, Colors.green[500]!],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _quantity++;
                                        });
                                      },
                                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Save Button
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Save Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.green[600],
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            currentIndex: _currentIndex,
            elevation: 0,
            onTap: _onNavItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0 ? Colors.green[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home, size: 24),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentIndex == 1 ? Colors.green[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_circle, size: 24),
                ),
                label: 'Add Product',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentIndex == 2 ? Colors.green[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit, size: 24),
                ),
                label: 'Edit Product',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentIndex == 3 ? Colors.green[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, size: 24),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout ? Colors.red[100] : Colors.green[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red[600] : Colors.green[600],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red[600] : Colors.grey[800],
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEnhancedLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green[600], size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.green[800],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[200]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green[50],
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 14,
          color: Colors.green[800],
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.green[600], size: 20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[200]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green[50],
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        onChanged: (String? newValue) {
          setState(() {
            _selectedCategory = newValue!;
          });
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.category, color: Colors.green[600], size: 20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: Colors.green[800],
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Colors.green[600]),
        items: _categories.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.green[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}