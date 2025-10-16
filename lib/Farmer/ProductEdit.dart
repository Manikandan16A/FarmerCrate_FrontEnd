import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/Signin.dart';
import 'Addproduct.dart';
import 'farmerprofile.dart';
import 'homepage.dart';
import 'orders_page.dart';
import '../utils/cloudinary_upload.dart';
import '../utils/notification_helper.dart';

class Product {
  final int id;
  String name;
  String description;
  double price;
  int quantity;
  String category;
  String? images;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? harvestDate;
  DateTime? expiryDate;
  String? grade;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.category,
    this.images,
    this.createdAt,
    this.updatedAt,
    this.harvestDate,
    this.expiryDate,
    this.grade,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    
    var imagesData = json['images'];
    if (imagesData is List && imagesData.isNotEmpty) {
      List<String> urls = [];
      for (var img in imagesData) {
        if (img is Map && img['image_url'] != null) {
          urls.add(img['image_url']);
        } else if (img is String) {
          urls.add(img);
        }
      }
      imageUrl = urls.isNotEmpty ? urls.join('|||') : null;
    }
    
    if (imageUrl == null) {
      var imageData = json['image_urls'];
      if (imageData is List && imageData.isNotEmpty) {
        imageUrl = imageData.join('|||');
      } else if (imageData is String && imageData.isNotEmpty) {
        imageUrl = imageData;
      } else {
        imageUrl = json['image_url'] ?? json['product_image'] ?? json['image'];
      }
    }

    return Product(
      id: json['id'] ?? json['product_id'] ?? 0,
      name: json['name'] ?? json['product_name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse((json['price'] ?? json['current_price'] ?? 0).toString()) ?? 0.0,
      quantity: json['quantity'] ?? json['stock'] ?? json['available_quantity'] ?? 0,
      category: json['category'] ?? '',
      images: imageUrl,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) :
      json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) :
      json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      harvestDate: json['harvest_date'] != null ? DateTime.parse(json['harvest_date']) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      grade: json['grade'] ?? json['quality'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'name': name,
      'description': description,
      'current_price': price.toStringAsFixed(2),
      'quantity': quantity,
      'category': category,
      'image_urls': images != null ? [images] : [],
      'status': 'available',
      'harvest_date': DateTime.now().toIso8601String().split('T')[0],
      'expiry_date': DateTime.now().add(Duration(days: 30)).toIso8601String().split('T')[0],
    };
  }
}

class FarmerProductsPage extends StatefulWidget {
  final String? token;

  const FarmerProductsPage({Key? key, this.token}) : super(key: key);

  @override
  _FarmerProductsPageState createState() => _FarmerProductsPageState();
}

class _FarmerProductsPageState extends State<FarmerProductsPage> {
  int _currentIndex = 2;
  List<Product> products = [];
  List<Product> filteredProducts = [];
  String searchQuery = '';
  String selectedCategory = 'All';
  String sortBy = 'createdAt';
  bool isAscending = false;
  bool isLoading = false;
  String? errorMessage;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    'All',
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

  final List<String> units = ['kg', 'liters', 'dozen', 'pieces', 'bags'];
  final List<String> statuses = ['Available', 'Low Stock', 'Out of Stock'];

  @override
  void initState() {
    super.initState();
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    String? effectiveToken = widget.token;

    if (effectiveToken == null || effectiveToken.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        effectiveToken = prefs.getString('auth_token');
        print('Retrieved token from SharedPreferences: ${effectiveToken != null ? effectiveToken.substring(0, effectiveToken.length > 20 ? 20 : effectiveToken.length) + '...' : 'null'}');
      } catch (e) {
        print('Error retrieving token from SharedPreferences: $e');
      }
    }

    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      await fetchProducts();
    } else {
      setState(() {
        errorMessage = 'Authentication token not available. Please login again.';
        isLoading = false;
      });
    }
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
      };


      String? effectiveToken = widget.token;
      if (effectiveToken == null || effectiveToken.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          effectiveToken = prefs.getString('auth_token');
        } catch (e) {
          print('Error retrieving token from SharedPreferences: $e');
        }
      }

      if (effectiveToken != null && effectiveToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $effectiveToken';
        print('Token being used: ${effectiveToken.substring(0, effectiveToken.length > 20 ? 20 : effectiveToken.length)}...'); // Debug print
      } else {
        print('No token available'); // Debug print
        setState(() {
          errorMessage = 'Authentication token not available. Please login again.';
          isLoading = false;
        });
        return;
      }

      print('Fetching products from: $uri'); // Debug print
      print('Headers: $headers'); // Debug print

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('API call timed out');
          throw TimeoutException('Request timed out');
        },
      );

      print('Response status code: ${response.statusCode}'); // Debug print

      if (response.body.isNotEmpty) {
        print('Response body: ${response.body}'); // Debug print - show full response
      }

      if (response.statusCode == 200) {
        try {
          final dynamic responseData = jsonDecode(response.body);
          print('Parsed response data type: ${responseData.runtimeType}'); // Debug print
          print('Parsed response data: $responseData'); // Debug print

          List<dynamic> productsData = [];

          if (responseData is Map && responseData.containsKey('data')) {
            productsData = responseData['data'] ?? [];
          }

          print('Final products data: $productsData'); // Debug print

          if (productsData.isNotEmpty) {
            setState(() {
              products = productsData.map((json) {
                print('Processing product: $json'); // Debug print
                return Product.fromJson(json);
              }).toList();
              filteredProducts = List.from(products);
              isLoading = false;
            });
            _applyFiltersAndSort();

            print('Successfully loaded ${products.length} products'); // Debug print
          } else {
            print('No products found in response'); // Debug print
            setState(() {
              products = [];
              filteredProducts = [];
              isLoading = false;
              errorMessage = 'No products found. Add your first product.';
            });
          }
        } catch (parseError) {
          print('JSON parsing error: $parseError'); // Debug print
          print('Response body that caused error: ${response.body}'); // Debug print
          setState(() {
            errorMessage = 'Invalid response format from server. Please try again.';
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        print('Authentication failed - status 401'); // Debug print
        setState(() {
          errorMessage = 'Authentication failed. Please login again.';
          isLoading = false;
        });
      } else if (response.statusCode == 403) {
        print('Access denied - status 403'); // Debug print
        setState(() {
          errorMessage = 'Access denied. You don\'t have permission to view products.';
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        print(' not found - API endpointstatus 404'); // Debug print
        setState(() {
          errorMessage = 'API endpoint not found. Please check the URL.';
          isLoading = false;
        });
      } else if (response.statusCode >= 500) {
        print('Server error - status ${response.statusCode}'); // Debug print
        setState(() {
          errorMessage = 'Server error (${response.statusCode}). Please try again later.';
          isLoading = false;
        });
      } else {
        print('Unexpected status code: ${response.statusCode}'); // Debug print
        setState(() {
          errorMessage = 'Failed to fetch products. Status: ${response.statusCode}. Response: ${response.body}';
          isLoading = false;
        });
      }
    } on FormatException catch (e) {
      print('JSON parsing error: $e'); // Debug print
      setState(() {
        errorMessage = 'Invalid response from server. Please try again.';
        isLoading = false;
      });
    } on SocketException catch (e) {
      print('Socket error: $e'); // Debug print
      setState(() {
        errorMessage = 'No internet connection. Please check your network.';
        isLoading = false;
      });
    } on TimeoutException catch (e) {
      print('Timeout error: $e'); // Debug print
      setState(() {
        errorMessage = 'Request timed out. Please try again.';
        isLoading = false;
      });
    } catch (e) {
      print('General error: $e'); // Debug print
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> updateProduct(Product product) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      List<String> imageUrls = [];
      if (product.images != null) {
        final images = product.images!.contains('|||')
            ? product.images!.split('|||').map((e) => e.trim()).toList()
            : [product.images!];
        for (String img in images) {
          if (img.startsWith('http')) {
            imageUrls.add(img);
          } else if (File(img).existsSync()) {
            print('Uploading new image for product update');
            final uploadedUrl = await CloudinaryUploader.uploadImage(File(img));
            if (uploadedUrl == null) {
              setState(() {
                isLoading = false;
                errorMessage = 'Failed to upload image. Please try again.';
              });
              return;
            }
            imageUrls.add(uploadedUrl);
            print('Image uploaded successfully: $uploadedUrl');
          }
        }
      }

      final uri = Uri.parse('https://farmercrate.onrender.com/api/products/${product.id}');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Get effective token (from widget or SharedPreferences)
      String? effectiveToken = widget.token;
      if (effectiveToken == null || effectiveToken.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          effectiveToken = prefs.getString('auth_token');
        } catch (e) {
          print('Error retrieving token from SharedPreferences: $e');
        }
      }

      if (effectiveToken != null && effectiveToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $effectiveToken';
      } else {
        setState(() {
          errorMessage = 'Authentication token not available. Please login again.';
          isLoading = false;
        });
        return;
      }

      final updatedProductData = {
        'name': product.name,
        'description': product.description,
        'current_price': product.price.toStringAsFixed(2),
        'quantity': product.quantity,
        'category': product.category,
        'image_urls': imageUrls,
        'status': 'available',
        'harvest_date': DateTime.now().toIso8601String().split('T')[0],
        'expiry_date': DateTime.now().add(Duration(days: 30)).toIso8601String().split('T')[0],
      };

      print('Updating product with ID: ${product.id}');
      print('Update request to: $uri');
      print('Update data: $updatedProductData');

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(updatedProductData),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Update request timed out');
          throw TimeoutException('Update request timed out');
        },
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      // Log the full response for debugging
      print('Full response headers: ${response.headers}');
      print('Request URL: $uri');
      print('Request headers: $headers');
      print('Request body: ${jsonEncode(updatedProductData)}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh the product list
        await fetchProducts();
        NotificationHelper.showInfo(context, 'Product updated successfully in database!');
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Authentication failed. Please login again.';
          isLoading = false;
        });
        NotificationHelper.showError(context, 'Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        setState(() {
          errorMessage = 'Access denied. You don\'t have permission to update this product.';
          isLoading = false;
        });
        NotificationHelper.showError(context, 'Access denied. You don\'t have permission to update this product.');
      } else if (response.statusCode == 400) {
        // Handle 400 Bad Request specifically
        String errorDetail = 'Invalid request data. Please check your input.';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorDetail = errorData['message'] ?? errorData['error'] ?? errorDetail;
            print('Server validation error: $errorData');
          }
        } catch (e) {
          errorDetail = 'Invalid request format. Please check all fields.';
        }

        setState(() {
          errorMessage = errorDetail;
          isLoading = false;
        });
        NotificationHelper.showWarning(context, errorDetail);
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'Product not found. It may have been deleted.';
          isLoading = false;
        });
        NotificationHelper.showWarning(context, 'Product not found. It may have been deleted.');
      } else {
        String errorMessage = 'Failed to update product in database.';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          }
        } catch (e) {
          errorMessage = 'Failed to update product in database. Status: ${response.statusCode}';
        }

        setState(() {
          this.errorMessage = errorMessage;
          isLoading = false;
        });
        NotificationHelper.showError(context, errorMessage);
      }
    } on TimeoutException catch (e) {
      print('Update timeout error: $e');
      setState(() {
        errorMessage = 'Request timed out. Please try again.';
        isLoading = false;
      });
      NotificationHelper.showWarning(context, 'Request timed out. Please try again.');
    } on SocketException catch (e) {
      print('Update socket error: $e');
      setState(() {
        errorMessage = 'No internet connection. Please check your network.';
        isLoading = false;
      });
      NotificationHelper.showError(context, 'No internet connection. Please check your network.');
    } catch (e) {
      print('Update general error: $e');
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
      NotificationHelper.showError(context, 'Network error. Please try again.');
    }
  }

  Future<void> deleteProduct(int productId) async {
    setState(() {
      isLoading = true;
    });

    try {
      String? effectiveToken = widget.token;
      if (effectiveToken == null || effectiveToken.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        effectiveToken = prefs.getString('auth_token');
      }

      final response = await http.delete(
        Uri.parse('https://farmercrate.onrender.com/api/products/$productId'),
        headers: {
          'Authorization': 'Bearer $effectiveToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchProducts();
        NotificationHelper.showInfo(context, 'Product deleted successfully');
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      NotificationHelper.showError(context, 'Failed to delete product');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            SizedBox(width: 8),
            Text('Delete Product?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
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

  String _getProductStatus(Product product) {
    if (product.quantity == 0) return 'Out of Stock';
    if (product.quantity < 10) return 'Low Stock';
    return 'Active';
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return Text('🌱', style: TextStyle(fontSize: 20));
      case 'Low Stock':
        return Text('⏰', style: TextStyle(fontSize: 20));
      case 'Out of Stock':
        return Text('❌', style: TextStyle(fontSize: 20));
      default:
        return SizedBox();
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      filteredProducts = products.where((product) {
        bool matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
            product.category.toLowerCase().contains(searchQuery.toLowerCase());
        bool matchesCategory = selectedCategory == 'All' || product.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();

      filteredProducts.sort((a, b) {
        dynamic aValue, bValue;
        switch (sortBy) {
          case 'name':
            aValue = a.name.toLowerCase();
            bValue = b.name.toLowerCase();
            break;
          case 'category':
            aValue = a.category.toLowerCase();
            bValue = b.category.toLowerCase();
            break;
          case 'price':
            aValue = a.price;
            bValue = b.price;
            break;
          case 'quantity':
            aValue = a.quantity;
            bValue = b.quantity;
            break;
          case 'createdAt':
          default:
            aValue = a.createdAt ?? DateTime.now();
            bValue = b.createdAt ?? DateTime.now();
            break;
        }
        int comparison = aValue.compareTo(bValue);
        return isAscending ? comparison : -comparison;
      });
    });
  }

  Future<String?> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile?.path;
  }

  Future<String?> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    return pickedFile?.path;
  }

  void _showAddEditDialog({Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    final priceController = TextEditingController(text: product?.price.toStringAsFixed(2) ?? '');
    
    List<String?> imagePaths = [null, null, null];
    if (product?.images != null) {
      final images = product!.images!.contains('|||')
          ? product!.images!.split('|||').map((e) => e.trim()).toList()
          : [product!.images!];
      for (int i = 0; i < images.length && i < 3; i++) {
        imagePaths[i] = images[i];
      }
    }

    String selectedCategoryDialog = product?.category ?? 'Fruits';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.green.shade50],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade600, Colors.green.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(isEdit ? Icons.edit : Icons.add_circle, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Product' : 'Add New Product',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Product Name',
                                prefixIcon: Icon(Icons.shopping_bag, color: Colors.green.shade600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedCategoryDialog,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category, color: Colors.green.shade600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: categories.where((cat) => cat != 'All').map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setDialogState(() {
                                  selectedCategoryDialog = newValue!;
                                });
                              },
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: Icon(Icons.inventory, color: Colors.green.shade600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Price (₹)',
                                prefixIcon: Icon(Icons.currency_rupee, color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                fillColor: Colors.grey[100],
                                filled: true,
                                suffixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                prefixIcon: Icon(Icons.description, color: Colors.green.shade600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade50, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade200, width: 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.photo_library, color: Colors.green.shade700, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Product Images',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  ...List.generate(3, (index) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
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
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Image ${index + 1}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                              ),
                                              if (imagePaths[index] != null)
                                                Padding(
                                                  padding: EdgeInsets.only(left: 8),
                                                  child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          if (imagePaths[index] == null)
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final pickedImage = await showModalBottomSheet<String?>(
                                                  context: context,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                                  builder: (context) => Container(
                                                    padding: EdgeInsets.all(20),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          leading: Icon(Icons.camera_alt, color: Colors.green[600]),
                                                          title: Text('Take Photo'),
                                                          onTap: () async {
                                                            final result = await _pickImageFromCamera();
                                                            Navigator.pop(context, result);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: Icon(Icons.photo_library, color: Colors.green[600]),
                                                          title: Text('Upload from Device'),
                                                          onTap: () async {
                                                            final result = await _pickImageFromGallery();
                                                            Navigator.pop(context, result);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: Icon(Icons.cancel, color: Colors.red[600]),
                                                          title: Text('Cancel'),
                                                          onTap: () => Navigator.pop(context),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                                if (pickedImage != null) {
                                                  setDialogState(() {
                                                    imagePaths[index] = pickedImage;
                                                  });
                                                }
                                              },
                                              icon: Icon(Icons.add_photo_alternate, size: 18),
                                              label: Text('Add Image', style: TextStyle(fontSize: 13)),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.green.shade700,
                                                side: BorderSide(color: Colors.green.shade300, width: 1.5),
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            )
                                          else
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: imagePaths[index]!.startsWith('http')
                                                      ? Image.network(
                                                          imagePaths[index]!,
                                                          height: 120,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : File(imagePaths[index]!).existsSync()
                                                          ? Image.file(
                                                              File(imagePaths[index]!),
                                                              height: 120,
                                                              width: double.infinity,
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Container(
                                                              height: 120,
                                                              width: double.infinity,
                                                              color: Colors.grey.shade200,
                                                              child: Icon(Icons.image, size: 40, color: Colors.grey.shade600),
                                                            ),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(8),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.2),
                                                              blurRadius: 4,
                                                            ),
                                                          ],
                                                        ),
                                                        child: IconButton(
                                                          onPressed: () async {
                                                            final pickedImage = await showModalBottomSheet<String?>(
                                                              context: context,
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                                              builder: (context) => Container(
                                                                padding: EdgeInsets.all(20),
                                                                child: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    ListTile(
                                                                      leading: Icon(Icons.camera_alt, color: Colors.green[600]),
                                                                      title: Text('Take Photo'),
                                                                      onTap: () async {
                                                                        final result = await _pickImageFromCamera();
                                                                        Navigator.pop(context, result);
                                                                      },
                                                                    ),
                                                                    ListTile(
                                                                      leading: Icon(Icons.photo_library, color: Colors.green[600]),
                                                                      title: Text('Upload from Device'),
                                                                      onTap: () async {
                                                                        final result = await _pickImageFromGallery();
                                                                        Navigator.pop(context, result);
                                                                      },
                                                                    ),
                                                                    ListTile(
                                                                      leading: Icon(Icons.cancel, color: Colors.red[600]),
                                                                      title: Text('Cancel'),
                                                                      onTap: () => Navigator.pop(context),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                            if (pickedImage != null) {
                                                              setDialogState(() {
                                                                imagePaths[index] = pickedImage;
                                                              });
                                                            }
                                                          },
                                                          icon: Icon(Icons.edit, color: Colors.blue, size: 18),
                                                          padding: EdgeInsets.all(8),
                                                          constraints: BoxConstraints(),
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(8),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.2),
                                                              blurRadius: 4,
                                                            ),
                                                          ],
                                                        ),
                                                        child: IconButton(
                                                          onPressed: () {
                                                            setDialogState(() {
                                                              imagePaths[index] = null;
                                                            });
                                                          },
                                                          icon: Icon(Icons.delete, color: Colors.red, size: 18),
                                                          padding: EdgeInsets.all(8),
                                                          constraints: BoxConstraints(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.isNotEmpty &&
                                    descriptionController.text.isNotEmpty &&
                                    quantityController.text.isNotEmpty &&
                                    priceController.text.isNotEmpty) {

                                  Navigator.of(context).pop();

                                  if (isEdit && product != null) {
                                    final validImages = imagePaths.where((img) => img != null).toList();
                                    final updatedProduct = Product(
                                      id: product.id,
                                      name: nameController.text,
                                      description: descriptionController.text,
                                      price: double.tryParse(priceController.text) ?? 0.0,
                                      quantity: int.tryParse(quantityController.text) ?? 0,
                                      category: selectedCategoryDialog,
                                      images: validImages.isNotEmpty ? validImages.join('|||') : null,
                                      createdAt: product.createdAt,
                                      updatedAt: DateTime.now(),
                                    );
                                    await updateProduct(updatedProduct);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddProductPage(token: widget.token),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                isEdit ? 'Update Product' : 'Add Product',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  MaterialColor _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Low Stock':
        return Colors.orange;
      case 'Out of Stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
        return;
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

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = sortBy == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.green.shade700 : Colors.grey.shade600),
            SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            sortBy = value;
          });
          _applyFiltersAndSort();
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.green.shade100,
        checkmarkColor: Colors.green.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? Colors.green.shade400 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 40,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                        : File(imageUrl).existsSync()
                        ? Image.file(
                      File(imageUrl),
                      fit: BoxFit.contain,
                    )
                        : Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                  _applyFiltersAndSort();
                },
              )
            : Text(
                'Edit Products',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  searchQuery = '';
                  _applyFiltersAndSort();
                }
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmersHomePage(token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag, color: Colors.green[600]),
              title: Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrdersPage(token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.green[600]),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmerProfilePage(token: widget.token),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[600]),
              title: Text('Logout'),
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.green.shade700, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Filter by Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                            _applyFiltersAndSort();
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.green.shade100,
                          checkmarkColor: Colors.green.shade700,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: isSelected ? Colors.green.shade400 : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.sort, color: Colors.green.shade700, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade600, Colors.green.shade500],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              isAscending = !isAscending;
                            });
                            _applyFiltersAndSort();
                          },
                          icon: Icon(
                            isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white,
                            size: 18,
                          ),
                          tooltip: isAscending ? 'Ascending' : 'Descending',
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildSortChip('Date', 'createdAt', Icons.calendar_today),
                      _buildSortChip('Name', 'name', Icons.sort_by_alpha),
                      _buildSortChip('Category', 'category', Icons.category),
                      _buildSortChip('Price', 'price', Icons.currency_rupee),
                      _buildSortChip('Stock', 'quantity', Icons.inventory),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Indicator
          if (isLoading)
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading products...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error Message
          if (errorMessage != null && !isLoading)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        errorMessage = null;
                      });
                      fetchProducts();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!isLoading && errorMessage == null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Products (${filteredProducts.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pull down to refresh or add your first product',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: fetchProducts,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.green.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.15),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.green.shade200, width: 2),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.images != null && product.images!.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  List<String> images;
                                  if (product.images!.contains('|||')) {
                                    images = product.images!.split('|||').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                  } else if (product.images!.contains(',https://') || product.images!.contains(',http://')) {
                                    images = product.images!.split(RegExp(r',(?=https?://)')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                  } else {
                                    images = [product.images!.trim()];
                                  }
                                  
                                  print('Product ${product.name} images: $images');
                                  
                                  if (images.isEmpty) {
                                    return Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.image, size: 50, color: Colors.grey.shade600),
                                    );
                                  }
                                  
                                  return SizedBox(
                                    height: 150,
                                    child: PageView.builder(
                                      itemCount: images.length,
                                      itemBuilder: (context, imgIndex) {
                                        final imageUrl = images[imgIndex];
                                        print('Loading image: $imageUrl');
                                        
                                        return Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: imageUrl.startsWith('http')
                                                    ? Image.network(
                                                  imageUrl,
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      height: 150,
                                                      width: double.infinity,
                                                      color: Colors.grey.shade200,
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                              : null,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    print('Image load error: $error');
                                                    return Container(
                                                      height: 150,
                                                      width: double.infinity,
                                                      color: Colors.grey.shade200,
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.error_outline, size: 40, color: Colors.grey.shade600),
                                                          SizedBox(height: 8),
                                                          Text('Image not available', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                )
                                                    : File(imageUrl).existsSync()
                                                    ? Image.file(File(imageUrl), height: 150, width: double.infinity, fit: BoxFit.cover)
                                                    : Container(
                                                  height: 150,
                                                  width: double.infinity,
                                                  color: Colors.grey.shade200,
                                                  child: Icon(Icons.image, size: 50, color: Colors.grey.shade600),
                                                ),
                                              ),
                                              if (images.length > 1)
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.7),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '${imgIndex + 1}/${images.length}',
                                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                      },
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          product.description,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getProductStatus(product) == 'Active' ? Colors.green.shade100 :
                                             _getProductStatus(product) == 'Low Stock' ? Colors.orange.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _getStatusIcon(_getProductStatus(product)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade100, Colors.green.shade50],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.category, size: 18, color: Colors.green.shade700),
                                  SizedBox(width: 6),
                                  Text(
                                    product.category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _getProductStatus(product) == 'Active' ? Colors.green.shade600 :
                                             _getProductStatus(product) == 'Low Stock' ? Colors.orange.shade600 : Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_getProductStatus(product) == 'Active' ? Colors.green :
                                                 _getProductStatus(product) == 'Low Stock' ? Colors.orange : Colors.red).withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _getProductStatus(product),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          final qtyController = TextEditingController(text: product.quantity.toString());
                                          return AlertDialog(
                                            title: Text('Update Quantity'),
                                            content: TextField(
                                              controller: qtyController,
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(labelText: 'Quantity'),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                                              ElevatedButton(
                                                onPressed: () {
                                                  product.quantity = int.tryParse(qtyController.text) ?? product.quantity;
                                                  Navigator.pop(context);
                                                  updateProduct(product);
                                                },
                                                child: Text('Update'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.blue.shade100, Colors.blue.shade50],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.shade300, width: 1.5),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inventory, size: 18, color: Colors.blue.shade700),
                                          SizedBox(width: 6),
                                          Text(
                                            '${product.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'units',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          final priceController = TextEditingController(text: product.price.toStringAsFixed(2));
                                          return AlertDialog(
                                            title: Text('Update Price'),
                                            content: TextField(
                                              controller: priceController,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              decoration: InputDecoration(labelText: 'Price (₹)'),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                                              ElevatedButton(
                                                onPressed: () {
                                                  product.price = double.tryParse(priceController.text) ?? product.price;
                                                  Navigator.pop(context);
                                                  updateProduct(product);
                                                },
                                                child: Text('Update'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.green.shade100, Colors.green.shade50],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.shade300, width: 1.5),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.currency_rupee, size: 18, color: Colors.green.shade700),
                                          Text(
                                            '${product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                  SizedBox(width: 6),
                                  Text(
                                    product.createdAt != null
                                        ? '${product.createdAt!.day}/${product.createdAt!.month}/${product.createdAt!.year}'
                                        : 'Date not available',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: () => _showAddEditDialog(product: product),
                                      icon: Icon(Icons.edit, color: Colors.white, size: 20),
                                      tooltip: 'Edit Product',
                                      padding: EdgeInsets.all(8),
                                      constraints: BoxConstraints(),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.red.shade600, Colors.red.shade400],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: () => _confirmDelete(product),
                                      icon: Icon(Icons.delete, color: Colors.white, size: 20),
                                      tooltip: 'Delete Product',
                                      padding: EdgeInsets.all(8),
                                      constraints: BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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
}