import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/cloudinary_upload.dart';
import 'navigation_utils.dart';

class AddDeliveryAgentScreen extends StatefulWidget {
  final String? token;

  const AddDeliveryAgentScreen({super.key, required this.token});

  @override
  State<AddDeliveryAgentScreen> createState() => _AddDeliveryAgentScreenState();
}

class _AddDeliveryAgentScreenState extends State<AddDeliveryAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _currentLocationController = TextEditingController();

  String _selectedVehicleType = 'bike';
  bool _isLoading = false;
  File? _licenseImage;
  File? _profileImage;

  final List<Map<String, String>> _vehicleTypes = [
    {'label': 'Bike', 'value': 'bike'},
    {'label': 'Car', 'value': 'car'},
    {'label': 'Van', 'value': 'van'},
    {'label': 'Truck', 'value': 'truck'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNumberController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    _licenseUrlController.dispose();
    _imageUrlController.dispose();
    _currentLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLicense) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isLicense) {
          _licenseImage = File(pickedFile.path);
        } else {
          _profileImage = File(pickedFile.path);
        }
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields correctly', isWarning: true);
      return;
    }

    if (_licenseImage == null || _profileImage == null) {
      _showSnackBar('Please select both license and profile images', isWarning: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images to Cloudinary
      final licenseUrl = await CloudinaryUploader.uploadImage(_licenseImage!);
      final profileUrl = await CloudinaryUploader.uploadImage(_profileImage!);

      if (licenseUrl == null || profileUrl == null) {
        _showSnackBar('Failed to upload images', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      final response = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/transporters/delivery-person'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'mobile_number': _mobileNumberController.text.trim(),
          'vehicle_number': _vehicleNumberController.text.replaceAll(' ', '').toUpperCase(),
          'license_number': _licenseNumberController.text.replaceAll(' ', '').toUpperCase(),
          'vehicle_type': _selectedVehicleType,
          'license_url': licenseUrl,
          'image_url': profileUrl,
          'current_location': _currentLocationController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? 'Delivery person added successfully!');
        _clearForm();
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['message'] ?? 'Failed to add delivery person', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _mobileNumberController.clear();
    _vehicleNumberController.clear();
    _licenseNumberController.clear();
    _licenseUrlController.clear();
    _imageUrlController.clear();
    _currentLocationController.clear();
    setState(() {
      _selectedVehicleType = 'bike';
      _licenseImage = null;
      _profileImage = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false, bool isInfo = false}) {
    Color backgroundColor;
    IconData icon;
    
    if (isError) {
      backgroundColor = Color(0xFFD32F2F);
      icon = Icons.error_outline;
    } else if (isWarning) {
      backgroundColor = Color(0xFFFF9800);
      icon = Icons.warning_amber;
    } else if (isInfo) {
      backgroundColor = Color(0xFF2196F3);
      icon = Icons.info_outline;
    } else {
      backgroundColor = Color(0xFF2E7D32);
      icon = Icons.check_circle;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        elevation: 6,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        title: Text('Add Delivery Person', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: TransporterNavigationUtils.buildTransporterDrawer(context, widget.token, 0, (index) {}),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delivery_dining, color: Colors.white, size: 48),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Add New Delivery Person',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fill in the details below',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Personal Information',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.2), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'Enter delivery person name',
                              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF2E7D32)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) return 'Please enter name';
                              if (value!.trim().length < 2) return 'Name must be at least 2 characters';
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _mobileNumberController,
                            decoration: InputDecoration(
                              labelText: 'Mobile Number *',
                              hintText: '10 digit mobile number',
                              prefixIcon: Icon(Icons.phone, color: Color(0xFF2E7D32)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              counterText: '',
                            ),
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter mobile number';
                              if (!RegExp(r'^[0-9]{10}$').hasMatch(value!)) return 'Enter valid 10-digit number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.directions_car, color: Color(0xFF2E7D32), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Vehicle Information',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.2), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedVehicleType,
                            decoration: InputDecoration(
                              labelText: 'Vehicle Type *',
                              prefixIcon: Icon(Icons.two_wheeler, color: Color(0xFF2E7D32)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: _vehicleTypes.map((type) {
                              return DropdownMenuItem(value: type['value'], child: Text(type['label']!));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicleType = value!;
                              });
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _vehicleNumberController,
                            decoration: InputDecoration(
                              labelText: 'Vehicle Number *',
                              hintText: 'e.g., KA01AB1234',
                              prefixIcon: Icon(Icons.confirmation_number, color: Color(0xFF2E7D32)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(15),
                              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter vehicle number';
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _licenseNumberController,
                            decoration: InputDecoration(
                              labelText: 'License Number *',
                              hintText: 'e.g., KA0120230001',
                              prefixIcon: Icon(Icons.card_membership, color: Color(0xFF2E7D32)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter license number';
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _pickImage(true),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: _licenseImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt, color: Color(0xFF2E7D32), size: 32),
                                        SizedBox(height: 8),
                                        Text('Tap to select License Image', style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(_licenseImage!, fit: BoxFit.cover),
                                    ),
                            ),
                          ),
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _pickImage(false),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: _profileImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person, color: Color(0xFF2E7D32), size: 32),
                                        SizedBox(height: 8),
                                        Text('Tap to select Profile Image', style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(_profileImage!, fit: BoxFit.cover),
                                    ),
                            ),
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _currentLocationController,
                            decoration: InputDecoration(
                              labelText: 'Current Location *',
                              hintText: 'e.g., Bangalore, Karnataka',
                              prefixIcon: Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter current location';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2E7D32).withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Delivery Person',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
