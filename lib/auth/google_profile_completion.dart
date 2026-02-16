import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Customer/customerhomepage.dart';
import '../Farmer/homepage.dart';
import '../Transpoter/transporter_dashboard.dart';
import '../utils/snackbar_utils.dart';
import '../utils/cloudinary_upload.dart';

class GoogleProfileCompletionPage extends StatefulWidget {
  final String email;
  final String name;
  final String googleId;
  final String role;

  const GoogleProfileCompletionPage({
    Key? key,
    required this.email,
    required this.name,
    required this.googleId,
    required this.role,
  }) : super(key: key);

  @override
  _GoogleProfileCompletionPageState createState() => _GoogleProfileCompletionPageState();
}

class _GoogleProfileCompletionPageState extends State<GoogleProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _zoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _ageController = TextEditingController();
  final _aadharNumberController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _voterIdNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _globalFarmerIdController = TextEditingController();
  File? _selectedImage;
  File? _selectedAadharFile;
  File? _selectedPanFile;
  File? _selectedVoterIdFile;
  File? _selectedLicenseFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _zoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _ageController.dispose();
    _aadharNumberController.dispose();
    _panNumberController.dispose();
    _voterIdNumberController.dispose();
    _licenseNumberController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _globalFarmerIdController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    print('[PROFILE] Starting profile completion...');
    print('[PROFILE] Email: ${widget.email}');
    print('[PROFILE] Name: ${widget.name}');
    print('[PROFILE] Role: ${widget.role}');
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await CloudinaryUploader.uploadImage(_selectedImage!);
          if (imageUrl == null) {
            setState(() { _isLoading = false; });
            SnackBarUtils.showError(context, 'Failed to upload image. Please try again.');
            return;
          }
        }

        String? aadharUrl, panUrl, voterIdUrl, licenseUrl;
        if (widget.role == 'transporter') {
          if (_selectedAadharFile == null || _selectedPanFile == null ||
              _selectedVoterIdFile == null || _selectedLicenseFile == null) {
            setState(() { _isLoading = false; });
            SnackBarUtils.showError(context, 'Please upload all required documents');
            return;
          }

          aadharUrl = await CloudinaryUploader.uploadImage(_selectedAadharFile!);
          if (aadharUrl == null) {
            setState(() { _isLoading = false; });
            SnackBarUtils.showError(context, 'Failed to upload Aadhar document');
            return;
          }

          panUrl = await CloudinaryUploader.uploadImage(_selectedPanFile!);
          if (panUrl == null) {
            setState(() { _isLoading = false; });
            SnackBarUtils.showError(context, 'Failed to upload PAN document');
            return;
          }

          voterIdUrl = await CloudinaryUploader.uploadImage(_selectedVoterIdFile!);
          if (voterIdUrl == null) {
            setState(() { _isLoading = false; });
            SnackBarUtils.showError(context, 'Failed to upload Voter ID document');
            return;
          }

          licenseUrl = await CloudinaryUploader.uploadImage(_selectedLicenseFile!);
          if (licenseUrl == null) {
            setState(() { _isLoading = false; });
            SnackBarUtils.showError(context, 'Failed to upload License document');
            return;
          }
        }

        final requestBody = <String, dynamic>{
          'email': widget.email,
          'name': widget.name,
          'googleId': widget.googleId,
          'role': widget.role,
          'mobile_number': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'zone': _zoneController.text.trim(),
          'state': _stateController.text.trim(),
          'district': _districtController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
        };
        
        if (imageUrl != null) {
          requestBody['image_url'] = imageUrl;
        }
        
        if (widget.role == 'farmer') {
          requestBody['account_number'] = _accountNumberController.text.trim();
          requestBody['ifsc_code'] = _ifscCodeController.text.trim();
          requestBody['global_farmer_id'] = _globalFarmerIdController.text.trim();
        } else if (widget.role == 'transporter') {
          if (aadharUrl != null) requestBody['aadhar_url'] = aadharUrl;
          if (panUrl != null) requestBody['pan_url'] = panUrl;
          if (voterIdUrl != null) requestBody['voter_id_url'] = voterIdUrl;
          if (licenseUrl != null) requestBody['license_url'] = licenseUrl;
          requestBody['aadhar_number'] = _aadharNumberController.text.trim();
          requestBody['pan_number'] = _panNumberController.text.trim();
          requestBody['voter_id_number'] = _voterIdNumberController.text.trim();
          requestBody['license_number'] = _licenseNumberController.text.trim();
          requestBody['account_number'] = _accountNumberController.text.trim();
          requestBody['ifsc_code'] = _ifscCodeController.text.trim();
        }
        
        print('[PROFILE] Request body: $requestBody');
        
        final response = await http.put(
          Uri.parse('https://farmercrate.onrender.com/api/auth/google-complete-profile'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        print('[PROFILE] Response status: ${response.statusCode}');
        print('[PROFILE] Response body: ${response.body}');

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final user = data['user'];
          
          print('[PROFILE] User data: $user');

          if (widget.role == 'farmer' || widget.role == 'transporter') {
            final verificationStatus = user['verification_status'];
            print('[PROFILE] Verification status: $verificationStatus');

            if (verificationStatus == null || verificationStatus == 'pending') {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.pending_actions, color: Colors.orange, size: 28),
                      SizedBox(width: 12),
                      Expanded(child: Text('Verification Pending', style: TextStyle(fontSize: 20))),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your account has been created successfully and is currently under review by our admin team.',
                        style: TextStyle(fontSize: 15, height: 1.4),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You will be notified once your account is approved.',
                                style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Understood', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
              return;
            }
          }

          final token = data['token'];
          print('[PROFILE] Token received: ${token?.substring(0, 20)}...');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('auth_token', token);
          await prefs.setString('role', widget.role);
          await prefs.setInt('user_id', user['id']);
          await prefs.setString('username', widget.name);
          await prefs.setString('email', widget.email);
          await prefs.setBool('is_logged_in', true);
          
          print('[PROFILE] Navigating to ${widget.role} home page...');

          if (widget.role == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CustomerHomePage(token: token)),
            );
          } else if (widget.role == 'transporter') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TransporterDashboard(token: token)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FarmersHomePage(token: token)),
            );
          }
        } else if (response.statusCode == 400) {
          final data = jsonDecode(response.body);
          print('[PROFILE ERROR] User already exists: ${data['message']}');
          SnackBarUtils.showError(context, 'User already exists. Please login instead.');
        } else {
          print('[PROFILE ERROR] Failed with status ${response.statusCode}');
          SnackBarUtils.showError(context, 'Failed to complete profile. Please try again.');
        }
      } catch (e, stackTrace) {
        print('[PROFILE ERROR] Exception: $e');
        print('[PROFILE ERROR] Stack trace: $stackTrace');
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, 'Error: $e');
      }
    } else {
      print('[PROFILE] Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[PROFILE] Building page for ${widget.name} (${widget.role})');
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.name}!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please complete your profile to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              _buildImagePicker(),
              if (widget.role == 'transporter') ...[
                SizedBox(height: 16),
                _buildDocumentPickers(),
              ],
              SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  prefixText: '+91 ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 100) return 'Age must be 18-100';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _zoneController,
                decoration: InputDecoration(
                  labelText: 'Zone',
                  prefixIcon: Icon(Icons.map),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              if (widget.role == 'farmer') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(18),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 9 || value.length > 18) return 'Must be 9-18 digits';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _ifscCodeController,
                  decoration: InputDecoration(
                    labelText: 'IFSC Code',
                    prefixIcon: Icon(Icons.code),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) return 'Invalid IFSC code';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _globalFarmerIdController,
                  decoration: InputDecoration(
                    labelText: 'Global Farmer ID',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
              ],
              if (widget.role == 'transporter') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _aadharNumberController,
                  decoration: InputDecoration(
                    labelText: 'Aadhar Number',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length != 12) return 'Must be 12 digits';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _panNumberController,
                  decoration: InputDecoration(
                    labelText: 'PAN Number',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.toUpperCase())) return 'Invalid PAN (e.g., ABCDE1234F)';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _voterIdNumberController,
                  decoration: InputDecoration(
                    labelText: 'Voter ID Number',
                    prefixIcon: Icon(Icons.how_to_vote),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 3) return 'Must be at least 3 characters';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: InputDecoration(
                    labelText: 'License Number',
                    prefixIcon: Icon(Icons.drive_eta),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Z0-9-]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 5) return 'Must be at least 5 characters';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(18),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 9 || value.length > 18) return 'Must be 9-18 digits';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _ifscCodeController,
                  decoration: InputDecoration(
                    labelText: 'IFSC Code',
                    prefixIcon: Icon(Icons.code),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) return 'Invalid IFSC code';
                    return null;
                  },
                ),
              ],
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 22),
                            SizedBox(width: 8),
                            Text('Complete Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
                title: Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
                title: Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Error picking image: $e');
    }
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
                title: Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
                title: Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? file = await _picker.pickImage(source: source);
        if (file != null) {
          setState(() {
            switch (documentType) {
              case 'aadhar':
                _selectedAadharFile = File(file.path);
                break;
              case 'pan':
                _selectedPanFile = File(file.path);
                break;
              case 'voter':
                _selectedVoterIdFile = File(file.path);
                break;
              case 'license':
                _selectedLicenseFile = File(file.path);
                break;
            }
          });
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Error picking document: $e');
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Image',
          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF4CAF50)),
                      SizedBox(height: 8),
                      Text('Tap to select image', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Documents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
        ),
        SizedBox(height: 16),
        _buildDocumentPicker(
          label: 'Aadhar Card',
          file: _selectedAadharFile,
          onTap: () => _pickDocument('aadhar'),
          icon: Icons.credit_card,
        ),
        SizedBox(height: 12),
        _buildDocumentPicker(
          label: 'PAN Card',
          file: _selectedPanFile,
          onTap: () => _pickDocument('pan'),
          icon: Icons.badge,
        ),
        SizedBox(height: 12),
        _buildDocumentPicker(
          label: 'Voter ID',
          file: _selectedVoterIdFile,
          onTap: () => _pickDocument('voter'),
          icon: Icons.how_to_vote,
        ),
        SizedBox(height: 12),
        _buildDocumentPicker(
          label: 'Driving License',
          file: _selectedLicenseFile,
          onTap: () => _pickDocument('license'),
          icon: Icons.drive_eta,
        ),
      ],
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: file != null ? Color(0xFF4CAF50) : Colors.grey[300]!,
            width: file != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: file != null ? Color(0xFF4CAF50).withOpacity(0.1) : Colors.grey[50],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: file != null ? Color(0xFF4CAF50) : Colors.grey[600],
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  file != null ? '$label - Selected' : 'Tap to select $label',
                  style: TextStyle(
                    color: file != null ? Color(0xFF4CAF50) : Colors.grey[600],
                    fontWeight: file != null ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
              if (file != null)
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
