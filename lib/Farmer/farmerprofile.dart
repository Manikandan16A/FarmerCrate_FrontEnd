import 'package:farmer_crate/Farmer/ProductEdit.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'homepage.dart';
import '../Signin.dart';
import '../Customer/Cart.dart';
import 'Addproduct.dart';

class FarmerProfilePage extends StatefulWidget {
  final String username;

  const FarmerProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  _FarmerProfilePageState createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _specializationController = TextEditingController();
  final _farmingTypeController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _irrigationTypeController = TextEditingController();
  final _annualYieldController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _crops = [
    {
      'id': '1',
      'name': 'Rice',
      'quantity': '500 kg',
      'price': '₹40/kg',
      'harvestDate': '2025-05-15',
    },
    {
      'id': '2',
      'name': 'Wheat',
      'quantity': '10 quintal',
      'price': '₹2000/quintal',
      'harvestDate': '2025-04-10',
    },
  ];

  List<Map<String, dynamic>> _orders = [
    {
      'orderId': 'ORD001',
      'crop': 'Rice',
      'quantity': '100 kg',
      'customerName': 'John Doe',
      'customerLocation': 'Chennai',
      'paymentStatus': 'Paid',
      'deliveryStatus': 'Delivered',
    },
    {
      'orderId': 'ORD002',
      'crop': 'Wheat',
      'quantity': '2 quintal',
      'customerName': 'Jane Smith',
      'customerLocation': 'Madurai',
      'paymentStatus': 'Pending',
      'deliveryStatus': 'In Transit',
    },
  ];

  int _currentIndex = 3;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.username;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    _specializationController.dispose();
    _farmingTypeController.dispose();
    _soilTypeController.dispose();
    _irrigationTypeController.dispose();
    _annualYieldController.dispose();
    _experienceController.dispose();
    super.dispose();
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
        targetPage = const FarmerProductsPage(); // Navigate to FarmerProductsPage
        break;
      case 3:
        targetPage = FarmerProfilePage(username: widget.username);
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

  void _showCropDialog({Map<String, dynamic>? crop}) {
    final dialogContext = context;
    final cropNameController = TextEditingController(text: crop?['name']);
    final quantityController = TextEditingController(text: crop?['quantity']);
    final priceController = TextEditingController(text: crop?['price']);
    final harvestDateController = TextEditingController(text: crop?['harvestDate']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            crop == null ? 'Add Crop' : 'Edit Crop',
            style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: cropNameController,
                    decoration: const InputDecoration(
                      labelText: 'Crop Name *',
                      prefixIcon: Icon(Icons.local_florist, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Crop name is required';
                      }
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                        return 'Only letters and spaces allowed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (e.g., 500 kg) *',
                      prefixIcon: Icon(Icons.scale, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Quantity is required';
                      }
                      final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
                      final parts = normalized.split(' ');
                      if (parts.length != 2 || double.tryParse(parts[0]) == null || double.parse(parts[0]) <= 0) {
                        return 'Enter a valid quantity (e.g., 500 kg)';
                      }
                      if (!['kg', 'quintal'].contains(parts[1].toLowerCase())) {
                        return 'Unit must be kg or quintal';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Price (e.g., ₹40/kg) *',
                      prefixIcon: Icon(Icons.attach_money, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final cleaned = value.replaceAll('₹', '').trim().replaceAll(RegExp(r'\s+'), ' ');
                      final parts = cleaned.split('/');
                      if (parts.length != 2 || double.tryParse(parts[0]) == null || double.parse(parts[0]) <= 0) {
                        return 'Enter a valid price (e.g., ₹40/kg)';
                      }
                      if (!['kg', 'quintal'].contains(parts[1].toLowerCase())) {
                        return 'Unit must be kg or quintal';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: harvestDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Harvest Date (YYYY-MM-DD) *',
                      prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        harvestDateController.text = picked.toString().split(' ')[0];
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harvest date is required';
                      }
                      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                        return 'Enter date in YYYY-MM-DD format';
                      }
                      try {
                        final date = DateTime.parse(value);
                        if (date.year < 2000 || date.isAfter(DateTime.now().add(const Duration(days: 365)))) {
                          return 'Enter a valid date between 2000 and next year';
                        }
                      } catch (e) {
                        return 'Invalid date format';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push;
                cropNameController.dispose();
                quantityController.dispose();
                priceController.dispose();
                harvestDateController.dispose();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    if (crop == null) {
                      _crops.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': cropNameController.text.trim(),
                        'quantity': quantityController.text.trim(),
                        'price': priceController.text.trim(),
                        'harvestDate': harvestDateController.text.trim(),
                      });
                    } else {
                      final index = _crops.indexWhere((c) => c['id'] == crop['id']);
                      _crops[index] = {
                        'id': crop['id'],
                        'name': cropNameController.text.trim(),
                        'quantity': quantityController.text.trim(),
                        'price': priceController.text.trim(),
                        'harvestDate': harvestDateController.text.trim(),
                      };
                    }
                  });

                  Navigator.push;
                  cropNameController.dispose();
                  quantityController.dispose();
                  priceController.dispose();
                  harvestDateController.dispose();

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(crop == null ? 'Crop added!' : 'Crop updated!'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text(crop == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }


  void _deleteCrop(String id) {
    setState(() {
      _crops.removeWhere((crop) => crop['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crop deleted!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Farmer Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black, // Changed text color to black
          ),
        ),
        backgroundColor: Colors.white, // Changed nav bar color to white
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Changed icon color to black
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black), // Changed icon color to black
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
                  const Text(
                    'FarmerCrate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome, ${widget.username}!',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.green[600]),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _onNavItemTapped(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.add, color: Colors.green[600]),
              title: const Text('Add Product'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _onNavItemTapped(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.green[600]),
              title: const Text('Edit Products'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _onNavItemTapped(2); // Use _onNavItemTapped for consistency
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_mail, color: Colors.green[600]),
              title: const Text('Contact Admin'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FarmersHomePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.green[600]),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _onNavItemTapped(3);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[600]),
              title: const Text('Logout'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF2E7D32),
                            )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : widget.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailController.text.isNotEmpty
                          ? _emailController.text
                          : 'Not provided',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🌾 Farmer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('📞 Contact Information'),
              const SizedBox(height: 16),
              _buildInputCard([
                _buildTextFormField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_city,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your location';
                    }
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 30),
              _buildSectionTitle('🚜 Farm Details'),
              const SizedBox(height: 16),
              _buildInputCard([
                _buildTextFormField(
                  controller: _farmSizeController,
                  label: 'Farm Size (acres)',
                  icon: Icons.landscape,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter farm size';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _specializationController,
                  label: 'Specialization',
                  icon: Icons.local_florist,
                  hintText: 'e.g., Rice, Sugarcane',
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _farmingTypeController,
                  label: 'Farming Type',
                  icon: Icons.eco,
                  hintText: 'e.g., Organic, Conventional',
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _soilTypeController,
                  label: 'Soil Type',
                  icon: Icons.terrain,
                  hintText: 'e.g., Alluvial, Clay',
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _irrigationTypeController,
                  label: 'Irrigation Type',
                  icon: Icons.water_drop,
                  hintText: 'e.g., Drip, Sprinkler',
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _annualYieldController,
                  label: 'Annual Yield (tons)',
                  icon: Icons.agriculture,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter annual yield';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _experienceController,
                  label: 'Farming Experience (years)',
                  icon: Icons.history,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter years';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 30),
              _buildSectionTitle('🌾 Product Listings'),
              const SizedBox(height: 16),
              _buildInputCard([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Crops Available for Sale',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCropDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Crop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _crops.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No crops listed yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
                    : Column(
                  children: _crops.map((crop) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          crop['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity: ${crop['quantity']}'),
                            Text('Price: ${crop['price']}'),
                            Text('Harvest Date: ${crop['harvestDate']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                              onPressed: () => _showCropDialog(crop: crop),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCrop(crop['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),
              const SizedBox(height: 30),
              _buildSectionTitle('📦 Order History'),
              const SizedBox(height: 16),
              _buildInputCard([
                const Text(
                  'Past Sales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 10),
                _orders.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No orders yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
                    : Column(
                  children: _orders.map((order) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: const Icon(Icons.receipt, color: Color(0xFF2E7D32)),
                        title: Text(
                          'Order ${order['orderId']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        subtitle: Text('Crop: ${order['crop']}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity: ${order['quantity']}'),
                                Text('Customer: ${order['customerName']}'),
                                Text('Location: ${order['customerLocation']}'),
                                Text('Payment: ${order['paymentStatus']}'),
                                Text('Delivery: ${order['deliveryStatus']}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ]),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56.0,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.green.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Save Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.blueGrey,
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
          items: const [
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
              label: 'Edit Products',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 20),
                    const Text(
                      'Add Profile Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose how you want to add your photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildImageOption(
                          icon: Icons.camera_alt,
                          label: 'Take Photo',
                          subtitle: 'Use Camera',
                          onTap: () => _getImage(ImageSource.camera),
                        ),
                        _buildImageOption(
                          icon: Icons.photo_library,
                          label: 'Choose Photo',
                          subtitle: 'From Gallery',
                          onTap: () => _getImage(ImageSource.gallery),
                        ),
                        if (_profileImage != null)
                          _buildImageOption(
                            icon: Icons.delete,
                            label: 'Remove',
                            subtitle: 'Delete Photo',
                            onTap: _removeImage,
                            color: Colors.red,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your photo will be stored securely on your device and uploaded when you save your profile.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
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
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        width: 90,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF2E7D32)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (color ?? const Color(0xFF2E7D32)).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 30,
                color: color ?? const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF2E7D32),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: (color ?? const Color(0xFF2E7D32)).withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
          );
        },
      );

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      Navigator.of(context).pop();

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(source == ImageSource.camera
                    ? 'Photo captured successfully!'
                    : 'Photo selected successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Failed to ${source == ImageSource.camera ? 'capture' : 'select'} photo. Please try again.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }
}