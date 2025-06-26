import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Signin.dart'; // Ensure this path is correct
import 'Addproduct.dart'; // Ensure this path is correct
import 'farmerprofile.dart'; // Ensure this path is correct
import 'homepage.dart';

class Product {
  final int id;
  String name;
  String farmer;
  String category;
  final double price;
  int quantity;
  String unit;
  final DateTime dateAdded;
  String status;
  String description;
  String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.farmer,
    required this.category,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.dateAdded,
    required this.status,
    required this.description,
    this.imageUrl,
  });
}

class FarmerProductsPage extends StatefulWidget {
  const FarmerProductsPage({Key? key}) : super(key: key);

  @override
  _FarmerProductsPageState createState() => _FarmerProductsPageState();
}

class _FarmerProductsPageState extends State<FarmerProductsPage> {
  int _currentIndex = 2; // Set to 2 to highlight "Edit Product" in BottomNavigationBar
  List<Product> products = [
    // Your existing product list remains unchanged
    Product(
      id: 1,
      name: 'Organic Tomatoes',
      farmer: 'John Smith',
      category: 'Vegetables',
      price: 45.00,
      quantity: 150,
      unit: 'kg',
      dateAdded: DateTime(2024, 6, 15),
      status: 'Available',
      description: 'Fresh organic tomatoes grown without pesticides',
      imageUrl: null,
    ),
    Product(
      id: 2,
      name: 'Fresh Milk',
      farmer: 'Mary Johnson',
      category: 'Dairy',
      price: 35.00,
      quantity: 50,
      unit: 'liters',
      dateAdded: DateTime(2024, 6, 18),
      status: 'Available',
      description: 'Pure cow milk from grass-fed cattle',
      imageUrl: null,
    ),
    Product(
      id: 3,
      name: 'Wheat Flour',
      farmer: 'David Brown',
      category: 'Grains',
      price: 28.00,
      quantity: 200,
      unit: 'kg',
      dateAdded: DateTime(2024, 6, 10),
      status: 'Low Stock',
      description: 'Stone-ground whole wheat flour',
      imageUrl: null,
    ),
    Product(
      id: 4,
      name: 'Free Range Eggs',
      farmer: 'Sarah Wilson',
      category: 'Poultry',
      price: 120.00,
      quantity: 100,
      unit: 'dozen',
      dateAdded: DateTime(2024, 6, 20),
      status: 'Available',
      description: 'Farm fresh eggs from free-range chickens',
      imageUrl: null,
    ),
    Product(
      id: 5,
      name: 'Organic Apples',
      farmer: 'Michael Davis',
      category: 'Fruits',
      price: 80.00,
      quantity: 75,
      unit: 'kg',
      dateAdded: DateTime(2024, 6, 12),
      status: 'Available',
      description: 'Crisp organic apples, variety mix',
      imageUrl: null,
    ),
  ];

  List<Product> filteredProducts = [];
  String searchQuery = '';
  String selectedCategory = 'All';
  String sortBy = 'dateAdded';
  bool isAscending = false;

  final List<String> categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Grains',
    'Poultry',
  ];

  final List<String> units = ['kg', 'liters', 'dozen', 'pieces', 'bags'];
  final List<String> statuses = ['Available', 'Low Stock', 'Out of Stock'];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(products);
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    setState(() {
      filteredProducts = products.where((product) {
        bool matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            product.farmer.toLowerCase().contains(searchQuery.toLowerCase()) ||
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
          case 'farmer':
            aValue = a.farmer.toLowerCase();
            bValue = b.farmer.toLowerCase();
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
          case 'dateAdded':
          default:
            aValue = a.dateAdded;
            bValue = b.dateAdded;
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
    final farmerController = TextEditingController(text: product?.farmer ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    final priceController = TextEditingController(text: product?.price.toStringAsFixed(2) ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    String? imagePath = product?.imageUrl;

    String selectedCategoryDialog = product?.category ?? 'Vegetables';
    String selectedUnit = product?.unit ?? 'kg';
    String selectedStatus = product?.status ?? 'Available';

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
                    TextField(
                      controller: farmerController,
                      decoration: InputDecoration(
                        labelText: 'Farmer Name',
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
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: units.map((String unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                selectedUnit = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
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
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: statuses.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedStatus = newValue!;
                        });
                      },
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
                            setDialogState(() {
                              imagePath = pickedImage;
                            });
                          },
                          child: Text('Choose Photo'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final pickedImage = await _pickImageFromCamera();
                            setDialogState(() {
                              imagePath = pickedImage;
                            });
                          },
                          child: Text('Take Photo'),
                        ),
                      ],
                    ),
                    if (imagePath != null) ...[
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imagePath!),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
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
                    if (isEdit) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Price (₹${product!.price.toStringAsFixed(2)}) cannot be modified',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Fixed: Correctly close dialog
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        farmerController.text.isNotEmpty &&
                        quantityController.text.isNotEmpty &&
                        priceController.text.isNotEmpty) {
                      if (isEdit) {
                        setState(() {
                          product!.name = nameController.text;
                          product.farmer = farmerController.text;
                          product.category = selectedCategoryDialog;
                          product.quantity = int.tryParse(quantityController.text) ?? 0;
                          product.unit = selectedUnit;
                          product.status = selectedStatus;
                          product.description = descriptionController.text;
                          product.imageUrl = imagePath;
                        });
                      } else {
                        final newProduct = Product(
                          id: products.isEmpty
                              ? 1
                              : products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1,
                          name: nameController.text,
                          farmer: farmerController.text,
                          category: selectedCategoryDialog,
                          price: double.tryParse(priceController.text) ?? 0.0,
                          quantity: int.tryParse(quantityController.text) ?? 0,
                          unit: selectedUnit,
                          dateAdded: DateTime.now(),
                          status: selectedStatus,
                          description: descriptionController.text,
                          imageUrl: imagePath,
                        );
                        setState(() {
                          products.add(newProduct);
                        });
                      }
                      _applyFiltersAndSort();
                      Navigator.of(context).pop();
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

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Product'),
          content: Text('Are you sure you want to delete "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  products.removeWhere((p) => p.id == product.id);
                });
                _applyFiltersAndSort();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
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
        targetPage = const FarmersHomePage();
        break;
      case 1:
        targetPage = const AddProductPage();
        break;
      case 2:
        targetPage = const FarmerProductsPage();
        break;
      case 3:
        targetPage = const FarmerProfilePage(username: '');
        break;
      default:
        targetPage = const FarmersHomePage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
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
                Navigator.push;
                _onNavItemTapped(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.add, color: Colors.green[600]),
              title: Text('Add Product'),
              onTap: () {
                Navigator.push;
                _onNavItemTapped(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.green[600]),
              title: Text('Edit Products'),
              onTap: () {
                Navigator.push;
                _onNavItemTapped(2);
              },
            ),
            ListTile(
                leading: Icon(Icons.contact_mail, color: Colors.green[600]),
                title: Text('Contact Admin'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmersHomePage(),
                    ),
                  );
                }

            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.green[600]),
              title: Text('Profile'),
              onTap: () {
                Navigator.push;
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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products, farmers...',
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
                          DropdownMenuItem(value: 'dateAdded', child: Text('Date Added')),
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
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
                ],
              ),
            )
                : ListView.builder(
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
                        if (product.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(product.imageUrl!),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                      SizedBox(width: 4),
                                      Text(
                                        product.farmer,
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(product.status).shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                product.status,
                                style: TextStyle(
                                  color: _getStatusColor(product.status).shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
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
                                      Text('${product.quantity} ${product.unit}'),
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
                                  'Fixed Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (product.description.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            product.description,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              '${product.dateAdded.day}/${product.dateAdded.month}/${product.dateAdded.year}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () => _showAddEditDialog(product: product),
                              icon: Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit Product',
                            ),
                            IconButton(
                              onPressed: () => _deleteProduct(product),
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Product',
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