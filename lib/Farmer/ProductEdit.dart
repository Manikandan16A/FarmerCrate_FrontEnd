import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../Signin.dart'; // Ensure this path is correct
import 'Addproduct.dart'; // Ensure this path is correct
import 'farmerprofile.dart'; // Ensure this path is correct
import 'homepage.dart';
import '../utils/cloudinary_upload.dart';

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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 0,
      category: json['category'] ?? '',
      images: json['images'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category,
      'images': images,
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
    fetchProducts();
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
      
      if (widget.token != null && widget.token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${widget.token}';
        print('Token being used: ${widget.token!.substring(0, widget.token!.length > 20 ? 20 : widget.token!.length)}...'); // Debug print
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
      // Handle image upload if it's a local file
      String? imageUrl = product.images;
      if (product.images != null && !product.images!.startsWith('http') && File(product.images!).existsSync()) {
        print('Uploading new image for product update');
        imageUrl = await CloudinaryUploader.uploadImage(File(product.images!));
        if (imageUrl == null) {
          setState(() {
            isLoading = false;
            errorMessage = 'Failed to upload image. Please try again.';
          });
          return;
        }
        print('Image uploaded successfully: $imageUrl');
      }

      final uri = Uri.parse('https://farmercrate.onrender.com/api/products/${product.id}');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (widget.token != null && widget.token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      } else {
        setState(() {
          errorMessage = 'Authentication token not available. Please login again.';
          isLoading = false;
        });
        return;
      }

      // Create updated product with the new image URL
      final updatedProductData = {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'quantity': product.quantity,
        'category': product.category,
        'images': imageUrl,
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

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh the product list
        await fetchProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated successfully in database!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Authentication failed. Please login again.';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed. Please login again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (response.statusCode == 403) {
        setState(() {
          errorMessage = 'Access denied. You don\'t have permission to update this product.';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access denied. You don\'t have permission to update this product.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'Product not found. It may have been deleted.';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product not found. It may have been deleted.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on TimeoutException catch (e) {
      print('Update timeout error: $e');
      setState(() {
        errorMessage = 'Request timed out. Please try again.';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request timed out. Please try again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } on SocketException catch (e) {
      print('Update socket error: $e');
      setState(() {
        errorMessage = 'No internet connection. Please check your network.';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No internet connection. Please check your network.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Update general error: $e');
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
    String? imagePath = product?.images;

    String selectedCategoryDialog = product?.category ?? 'Fruits';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryDialog,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final pickedImage = await _pickImageFromGallery();
                            if (pickedImage != null) {
                              setDialogState(() {
                                imagePath = pickedImage;
                              });
                            }
                          },
                          child: Text('Choose Photo'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final pickedImage = await _pickImageFromCamera();
                            if (pickedImage != null) {
                              setDialogState(() {
                                imagePath = pickedImage;
                              });
                            }
                          },
                          child: Text('Take Photo'),
                        ),
                      ],
                    ),
                    if (imagePath != null) ...[
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imagePath!.startsWith('http')
                            ? Image.network(
                                imagePath!,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 24,
                                          color: Colors.grey.shade600,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Error',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : File(imagePath!).existsSync()
                                ? Image.file(
                                    File(imagePath!),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      size: 30,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            imagePath = null;
                          });
                        },
                        child: Text(
                          'Remove Photo',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        descriptionController.text.isNotEmpty &&
                        quantityController.text.isNotEmpty &&
                        priceController.text.isNotEmpty) {
                      
                      Navigator.of(context).pop();
                      
                      if (isEdit && product != null) {
                        // Update existing product
                        final updatedProduct = Product(
                          id: product.id,
                          name: nameController.text,
                          description: descriptionController.text,
                          price: double.tryParse(priceController.text) ?? 0.0,
                          quantity: int.tryParse(quantityController.text) ?? 0,
                          category: selectedCategoryDialog,
                          images: imagePath,
                          createdAt: product.createdAt,
                          updatedAt: DateTime.now(),
                        );
                        await updateProduct(updatedProduct);
                      } else {
                        // Navigate to AddProduct page for new products
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddProductPage(token: widget.token),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEdit ? 'Update' : 'Add'),
                ),
              ],
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

  void _showDebugInfo() {
    String tokenInfo = widget.token != null && widget.token!.isNotEmpty 
        ? 'Token: ${widget.token!.substring(0, widget.token!.length > 30 ? 30 : widget.token!.length)}...'
        : 'No token available';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Debug Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Token Status: $tokenInfo'),
              SizedBox(height: 16),
              Text('Products loaded: ${products.length}'),
              SizedBox(height: 8),
              Text('Filtered products: ${filteredProducts.length}'),
              SizedBox(height: 8),
              Text('Loading: $isLoading'),
              SizedBox(height: 8),
              if (errorMessage != null)
                Text('Error: $errorMessage'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await fetchProducts();
              },
              child: Text('Refresh Products'),
            ),
          ],
        );
      },
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
            icon: Icon(Icons.refresh, color: Colors.green[800]),
            onPressed: () {
              fetchProducts();
            },
            tooltip: 'Refresh Products',
          ),
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.orange[800]),
            onPressed: () {
              _showDebugInfo();
            },
            tooltip: 'Debug Info',
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.green[800]),
            onPressed: () {},
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
              leading: Icon(Icons.add, color: Colors.green[600]),
              title: Text('Add Product'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
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
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmerProductsPage(token: widget.token),
                  ),
                );
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
                    builder: (context) => FarmersHomePage(token: widget.token),
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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    _applyFiltersAndSort();
                  },
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          selectedCategory = newValue!;
                          _applyFiltersAndSort();
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: sortBy,
                        decoration: InputDecoration(
                          labelText: 'Sort By',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: 'createdAt', child: Text('Date Added')),
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'category', child: Text('Category')),
                          DropdownMenuItem(value: 'price', child: Text('Price')),
                          DropdownMenuItem(value: 'quantity', child: Text('Quantity')),
                        ],
                        onChanged: (String? newValue) {
                          sortBy = newValue!;
                          _applyFiltersAndSort();
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        isAscending = !isAscending;
                        _applyFiltersAndSort();
                      },
                      icon: Icon(
                        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.green.shade700,
                      ),
                      tooltip: isAscending ? 'Ascending' : 'Descending',
                    ),
                  ],
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
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.images != null)
                                    GestureDetector(
                                      onTap: () => _showImagePreview(product.images!),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: product.images!.startsWith('http')
                                            ? Image.network(
                                                product.images!,
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Container(
                                                    height: 150,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade200,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
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
                                                  return Container(
                                                    height: 150,
                                                    width: double.infinity,
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
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              )
                                            : File(product.images!).existsSync()
                                                ? Image.file(
                                                    File(product.images!),
                                                    height: 150,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
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
                                      ),
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
                                  SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              product.description,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                                                SizedBox(width: 4),
                                                Text(product.category),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                                                SizedBox(width: 4),
                                                Text('${product.quantity} units'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          Text(
                                            'Price',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                      SizedBox(width: 4),
                                      Text(
                                        product.createdAt != null 
                                            ? '${product.createdAt!.day}/${product.createdAt!.month}/${product.createdAt!.year}'
                                            : 'Date not available',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                      Spacer(),
                                      IconButton(
                                        onPressed: () => _showAddEditDialog(product: product),
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Edit Product',
                                      ),
                                    ],
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
          color: Colors.black,
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
                padding: EdgeInsets.all(4),
                child: Icon(Icons.home, size: 24),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.explore_outlined, size: 24),
              ),
              label: 'Add Product',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.mode_edit_sharp, size: 24),
              ),
              label: 'Edit Product',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.person_outline, size: 24),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green.shade700,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Product',
      ),
    );
  }
}