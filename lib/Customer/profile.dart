import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final String token; // Pass the token to this page
  const ProfilePage({Key? key, required this.token}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _updating = false;
  String? _error;

  // Controllers for each field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/customer/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final customer = data['data'];
        _nameController.text = customer['customer_name'] ?? '';
        _mobileController.text = customer['mobile_number'] ?? '';
        _emailController.text = customer['email'] ?? '';
        _ageController.text = customer['age']?.toString() ?? '';
        _addressController.text = customer['address'] ?? '';
        _zoneController.text = customer['zone'] ?? '';
        _stateController.text = customer['state'] ?? '';
        _districtController.text = customer['district'] ?? '';
        // If you want to display image, add: _imageUrlController.text = customer['image'] ?? '';
      } else {
        print('Response body: ${response.body}');
        _error = 'Failed to load profile (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _updating = true;
      _updating = true;
      _error = null;
    });
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/customers/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text,
          'mobilenumber': _mobileController.text,
          'email': _emailController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'address': _addressController.text,
          'zone': _zoneController.text,
          'state': _stateController.text,
          'district': _districtController.text,
          'image': _imageUrlController.text,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        _error = 'Failed to update profile (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    setState(() {
      _updating = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _zoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green[700],
        title: Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 16),
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.green[200],
                            backgroundImage: _imageUrlController.text.isNotEmpty
                                ? NetworkImage(_imageUrlController.text)
                                : null,
                            child: _imageUrlController.text.isEmpty
                                ? Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(_nameController, 'Name', Icons.person, validator: (v) => v!.isEmpty ? 'Enter name' : null),
                          _buildTextField(_mobileController, 'Mobile Number', Icons.phone, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Enter mobile number' : null),
                          _buildTextField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Enter email' : null),
                          _buildTextField(_ageController, 'Age', Icons.cake, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Enter age' : null),
                          _buildTextField(_addressController, 'Address', Icons.location_on, validator: (v) => v!.isEmpty ? 'Enter address' : null),
                          _buildTextField(_zoneController, 'Zone', Icons.map, validator: (v) => v!.isEmpty ? 'Enter zone' : null),
                          _buildTextField(_stateController, 'State', Icons.flag, validator: (v) => v!.isEmpty ? 'Enter state' : null),
                          _buildTextField(_districtController, 'District', Icons.location_city, validator: (v) => v!.isEmpty ? 'Enter district' : null),
                          _buildTextField(_imageUrlController, 'Image URL', Icons.image, validator: (v) => v!.isEmpty ? 'Enter image URL' : null),
                          SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(Icons.save, color: Colors.white),
                              label: _updating
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
                              onPressed: _updating ? null : _updateProfile,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green[700]),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
} 