import 'package:farmer_crate/Farmer/ProductEdit.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'homepage.dart';
import '../Signin.dart';
import '../Customer/Cart.dart';
import 'Addproduct.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FarmerProfilePage extends StatefulWidget {
  final String? token;
  const FarmerProfilePage({Key? key, this.token}) : super(key: key);
  @override
  _FarmerProfilePageState createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _zoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isLoading = false;
  String? _farmerImageUrl;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchFarmerProfile();
  }

  Future<void> _fetchFarmerProfile() async {
    if (widget.token == null) return;
    setState(() { _isLoading = true; });
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/farmer/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final farmer = data['data'];
        setState(() {
          _nameController.text = farmer['name'] ?? '';
          _emailController.text = farmer['email'] ?? '';
          _phoneController.text = farmer['mobile_number'] ?? '';
          _addressController.text = farmer['address'] ?? '';
          _zoneController.text = farmer['zone'] ?? '';
          _stateController.text = farmer['state'] ?? '';
          _districtController.text = farmer['district'] ?? '';
          _ageController.text = farmer['age']?.toString() ?? '';
          _farmerImageUrl = farmer['image_url'];
        });
      }
    } catch (e) {
      // Optionally handle error
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _zoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
        _farmerImageUrl = null; // Clear URL if new image picked
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      String? imageUrl = _farmerImageUrl;
      // Optionally, upload _profileImage to your server/cloud and get the URL
      // For now, just use the existing URL or null
      final updateData = {
        'name': _nameController.text.trim(),
        'mobile_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'zone': _zoneController.text.trim(),
        'state': _stateController.text.trim(),
        'district': _districtController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'image_url': imageUrl,
      };
      try {
        final response = await http.put(
          Uri.parse('https://farmercrate.onrender.com/api/farmer/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode(updateData),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF2E7D32)),
          );
          _fetchFarmerProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: ${response.body}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Farmer Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: _buildSideNav(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : (_farmerImageUrl != null && _farmerImageUrl!.isNotEmpty)
                                    ? NetworkImage(_farmerImageUrl!) as ImageProvider
                                    : null,
                            child: (_profileImage == null && (_farmerImageUrl == null || _farmerImageUrl!.isEmpty))
                                ? const Icon(Icons.person, size: 60, color: Color(0xFF2E7D32))
                                : null,
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
                                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF000000)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email address';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email address';
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
                        if (value == null || value.isEmpty) return 'Please enter your phone number';
                        if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) return 'Please enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_city,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your address' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _zoneController,
                      label: 'Zone',
                      icon: Icons.map,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your zone' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.flag,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your state' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _districtController,
                      label: 'District',
                      icon: Icons.location_on,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your district' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your age';
                        if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Please enter a valid age';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56.0,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: Colors.green.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
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

  Widget _buildSideNav() {
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
                  backgroundImage: (_farmerImageUrl != null && _farmerImageUrl!.isNotEmpty)
                      ? NetworkImage(_farmerImageUrl!)
                      : null,
                  child: (_farmerImageUrl == null || _farmerImageUrl!.isEmpty)
                      ? Icon(Icons.person, size: 40, color: Colors.green[700])
                      : null,
                ),
                SizedBox(height: 10),
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage Your Farmer Profile',
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
                context,
                MaterialPageRoute(builder: (context) => FarmersHomePage(token: widget.token)),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FarmerProfilePage(token: widget.token)),
              );
            },
          ),
          // Add more farmer-specific navigation items here as needed
          Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

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
        currentIndex: 1, // Profile is selected
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FarmersHomePage(token: widget.token)),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FarmerProfilePage(token: widget.token)),
              );
              break;
            // Add more cases for other farmer pages if needed
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}