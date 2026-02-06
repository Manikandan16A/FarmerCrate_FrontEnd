import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../Customer/customerhomepage.dart';
import '../auth/Signin.dart';
import 'Categories.dart';
import 'Cart.dart';
import 'order history.dart';
import 'navigation_utils.dart';
import 'AppInfo.dart';
import 'wishlist.dart';
import 'AppSettingsPage.dart';
import 'NotificationsPage.dart';
import '../common/help_support_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/cloudinary_upload.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerProfilePage extends StatefulWidget {
  final String? token;
  const CustomerProfilePage({Key? key, this.token}) : super(key: key);
  @override
  _CustomerProfilePageState createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _zoneController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  String? _customerImageUrl;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Dropdown values
  String? _selectedState;
  String? _selectedDistrict;

  // South Indian States
  final List<String> _southStates = [
    'Tamil Nadu',
    'Kerala',
    'Karnataka',
    'Andhra Pradesh',
    'Telangana',
    'Puducherry',
  ];

  // Tamil Nadu Districts
  final List<String> _tamilNaduDistricts = [
    'Ariyalur',
    'Chengalpattu',
    'Chennai',
    'Coimbatore',
    'Cuddalore',
    'Dharmapuri',
    'Dindigul',
    'Erode',
    'Kallakurichi',
    'Kanchipuram',
    'Kanyakumari',
    'Karur',
    'Krishnagiri',
    'Madurai',
    'Mayiladuthurai',
    'Nagapattinam',
    'Namakkal',
    'Nilgiris',
    'Perambalur',
    'Pudukkottai',
    'Ramanathapuram',
    'Ranipet',
    'Salem',
    'Sivaganga',
    'Tenkasi',
    'Thanjavur',
    'Theni',
    'Thoothukudi',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tirupathur',
    'Tiruppur',
    'Tiruvallur',
    'Tiruvannamalai',
    'Tiruvarur',
    'Vellore',
    'Viluppuram',
    'Virudhunagar',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fetchCustomerProfile();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomerProfile() async {
    String? token = widget.token;

    // If no token from widget, try to get from SharedPreferences
    if (token == null || token
        .trim()
        .isEmpty) {
      print('No token from widget, trying SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
    }

    if (token == null || token
        .trim()
        .isEmpty) {
      print('No token found in SharedPreferences either');
      _showSnackBar(
          'Authentication required. Please log in again.', Colors.red);
      return;
    }

    print('Profile page using token: ${token.substring(0, 10)}...');
    setState(() {
      _isLoading = true;
    });
    try {
      print(
          'Fetching customer profile with token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/customers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Profile API Response Status: ${response.statusCode}');
      print('Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final customer = data['data'];
        print('Customer data received: $customer');

        setState(() {
          _nameController.text =
              (customer['customer_name'] ?? customer['name'] ??
                  customer['username'] ?? '').toString();
          _emailController.text = customer['email'] ?? '';
          _phoneController.text = customer['mobile_number'] ?? '';
          _addressController.text = customer['address'] ?? '';
          _zoneController.text = customer['zone'] ?? '';
          _selectedState = customer['state'] ?? '';
          _selectedDistrict = customer['district'] ?? '';
          _customerImageUrl = customer['image_url'];

          // Ensure selected values are in the lists
          if (_selectedState != null &&
              !_southStates.contains(_selectedState)) {
            print('State $_selectedState not in list, setting to null');
            _selectedState = null;
          }
          if (_selectedDistrict != null &&
              !_tamilNaduDistricts.contains(_selectedDistrict)) {
            print('District $_selectedDistrict not in list, setting to null');
            _selectedDistrict = null;
          }
        });

        _showSnackBar('Profile loaded successfully!', const Color(0xFF00C853));
      } else {
        final errorBody = response.body;
        print('Profile API Error: $errorBody');
        _showSnackBar(
            'Failed to load profile (${response.statusCode})', Colors.red);
      }
    } catch (e) {
      print('Profile fetch error: $e');
      _showSnackBar('Error loading profile: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error_outline : Icons
                  .check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEditConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.edit_outlined, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to edit your profile?',
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
                        onPressed: () => Navigator.of(context).pop(),
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
                          Navigator.of(context).pop();
                          _enableEditMode();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Yes, Edit',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 16),
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

  void _enableEditMode() {
    setState(() {
      _isEditMode = true;
    });
    _showSnackBar('Edit mode enabled. You can now modify your profile.',
        const Color(0xFF4CAF50));
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _fetchCustomerProfile();
    });
    _showSnackBar('Edit cancelled. Changes discarded.', Colors.orange);
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final url = await CloudinaryUploader.uploadImage(image);
      if (url == null || url.isEmpty) {
        _showSnackBar('Failed to upload image. Please try again.', Colors.red);
        return null;
      }
      return url;
    } catch (e) {
      _showSnackBar('Error uploading image: $e', Colors.red);
      return null;
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Choose Profile Photo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildImageOption(
                    icon: Icons.camera_alt_outlined,
                    title: 'Take Photo',
                    subtitle: 'Use camera to take a new photo',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await _picker.pickImage(
                          source: ImageSource.camera);
                      if (image != null) {
                        setState(() {
                          _profileImage = File(image.path);
                          _customerImageUrl = null;
                        });
                        await _uploadAndPersistImage();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildImageOption(
                    icon: Icons.photo_library_outlined,
                    title: 'Choose from Gallery',
                    subtitle: 'Select from existing photos',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          _profileImage = File(image.path);
                          _customerImageUrl = null;
                        });
                        await _uploadAndPersistImage();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          gradient: const LinearGradient(
            colors: [Color(0xFFFAFAFA), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndPersistImage() async {
    if (widget.token == null || widget.token!.isEmpty) return;
    if (_profileImage == null) return;
    setState(() {
      _isLoading = true;
    });
    final uploadedUrl = await _uploadImage(_profileImage!);
    if (uploadedUrl == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final updateData = {
      'customer_name': _nameController.text.trim(),
      'mobile_number': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'zone': _zoneController.text.trim(),
      'state': _selectedState ?? '',
      'district': _selectedDistrict ?? '',
      'image_url': uploadedUrl,
    };
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/customers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(updateData),
      );
      if (response.statusCode == 200) {
        setState(() {
          _customerImageUrl = uploadedUrl;
          _profileImage = null;
        });
        _showSnackBar(
            'Profile photo updated successfully!', const Color(0xFF00C853));
      } else {
        _showSnackBar('Failed to update photo', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error updating photo: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSaveConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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
                      colors: [Color(0xFF00C853), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.save_outlined, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to save your changes?',
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
                        onPressed: () => Navigator.of(context).pop(),
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
                          Navigator.of(context).pop();
                          _saveProfile();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 16),
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

  void _contactUs() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF4CAF50)),
              title: const Text('Email'),
              subtitle: const Text('support@farmercrate.com'),
              onTap: () async {
                final uri = Uri.parse('mailto:support@farmercrate.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
              title: const Text('Phone'),
              subtitle: const Text('+91 1234567890'),
              onTap: () async {
                final uri = Uri.parse('tel:+911234567890');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF4CAF50)),
              title: const Text('Website'),
              subtitle: const Text('www.farmercrate.com'),
              onTap: () async {
                final uri = Uri.parse('https://www.farmercrate.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'Check out Farmer Crate - Fresh produce directly from farmers! Download now: https://play.google.com/store/apps/farmercrate',
      subject: 'Farmer Crate App',
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Clear stored tokens and navigate to login
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('jwt_token');
      } catch (e) {
        // ignore errors silently; still continue to logout
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      String? token = widget.token;
      if (token == null || token
          .trim()
          .isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token');
      }

      if (token == null || token
          .trim()
          .isEmpty) {
        _showSnackBar(
            'Authentication required. Please log in again.', Colors.red);
        return;
      }

      setState(() {
        _isLoading = true;
      });
      String? imageUrl = _customerImageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadImage(_profileImage!);
        if (imageUrl == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      final updateData = {
        'customer_name': _nameController.text.trim(),
        'mobile_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'zone': _zoneController.text.trim(),
        'state': _selectedState ?? '',
        'district': _selectedDistrict ?? '',
        'image_url': imageUrl,
      };

      print('Updating profile with data: $updateData');

      try {
        final response = await http.put(
          Uri.parse('https://farmercrate.onrender.com/api/customers/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(updateData),
        );

        print('Profile update response status: ${response.statusCode}');
        print('Profile update response body: ${response.body}');

        if (response.statusCode == 200) {
          setState(() {
            _isEditMode = false;
          });
          _showSnackBar(
              'Profile updated successfully!', const Color(0xFF00C853));
          _fetchCustomerProfile();
        } else {
          final errorBody = response.body;
          print('Profile update failed with status ${response
              .statusCode}: $errorBody');
          _showSnackBar(
              'Failed to update profile (${response.statusCode})', Colors.red);
        }
      } catch (e) {
        print('Profile update error: $e');
        _showSnackBar('Error: $e', Colors.red);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerHomePage(token: widget.token),
          ),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _isLoading ? _buildLoadingWidget() : _buildProfileForm(),
                ),
              ),
            ),
          ],
        ),
        drawer: CustomerNavigationUtils.buildCustomerDrawer(
          parentContext: context,
          token: widget.token,
          customerImageUrl: _customerImageUrl,
          customerName: _nameController.text,
          isLoadingProfile: _isLoading,
        ),
        bottomNavigationBar: CustomerNavigationUtils.buildCustomerBottomNav(
          currentIndex: 3, // Profile is index 3
          onTap: (index) {
            if (index != 3) {
              switch (index) {
                case 0:
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => CustomerHomePage(token: widget.token)),
                    (route) => false,
                  );
                  break;
                case 1:
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => CategoryPage(token: widget.token)),
                    (route) => false,
                  );
                  break;
                case 2:
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage(token: widget.token)),
                    (route) => false,
                  );
                  break;
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Customer Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage your personal information',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchCustomerProfile,
            tooltip: 'Refresh Profile',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(_isEditMode ? Icons.close_rounded : Icons.edit_outlined,
                color: Colors.white),
            onPressed: _isEditMode ? _cancelEdit : _showEditConfirmation,
            tooltip: _isEditMode ? 'Cancel Edit' : 'Edit Profile',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: MediaQuery
          .of(context)
          .size
          .height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading your profile...',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching data from server',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProfileImageSection(),
            const SizedBox(height: 32),
            _buildPersonalInfoCard(),
            const SizedBox(height: 20),
            _buildContactInfoCard(),
            const SizedBox(height: 20),
            _buildLocationInfoCard(),
            const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.history, color: Colors.green[700]),
                      title: const Text('Order History'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderHistoryPage(token: widget.token)),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.favorite_outline, color: Colors.green[700]),
                      title: const Text('My Wishlist'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => WishlistPage(token: widget.token)),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.notifications_outlined, color: Colors.green[700]),
                      title: const Text('Notifications'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationsPage(token: widget.token)),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.settings_outlined, color: Colors.green[700]),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AppSettingsPage(token: widget.token)),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: Colors.green[700]),
                      title: const Text('App Info / Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AppInfoPage()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.help_outline, color: Colors.green[700]),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.contact_mail_outlined, color: Colors.green[700]),
                      title: const Text('Contact Us'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _contactUs,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.share_outlined, color: Colors.green[700]),
                      title: const Text('Share App'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _shareApp,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout_outlined, color: Colors.red[700]),
                      title: const Text('Logout'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF5722),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.logout, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Confirm Logout',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Are you sure you want to logout?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () => Navigator.pop(dialogContext),
                                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(dialogContext);
                                              try {
                                                final prefs = await SharedPreferences.getInstance();
                                                await prefs.remove('auth_token');
                                                await prefs.remove('jwt_token');
                                              } catch (e) {}
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(builder: (context) => LoginPage()),
                                                (Route<dynamic> route) => false,
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF5722),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('Logout'),
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
                      },
                    ),
                  ],
                ),
              ),
            if (_isEditMode) ...[
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
            const SizedBox(height: 100), // Extra space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.1),
                      const Color(0xFF2E7D32).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_customerImageUrl != null &&
                      _customerImageUrl!.isNotEmpty)
                      ? NetworkImage(_customerImageUrl!) as ImageProvider
                      : null,
                  child: (_profileImage == null &&
                      (_customerImageUrl == null || _customerImageUrl!.isEmpty))
                      ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                        Icons.person, size: 60, color: Colors.white),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                        Icons.camera_alt, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'Welcome!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customer Profile',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildInfoCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildTextFormField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          validator: (value) =>
          value == null || value.isEmpty
              ? 'Please enter your full name'
              : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your email address';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoCard() {
    return _buildInfoCard(
      title: 'Contact Information',
      icon: Icons.phone_outlined,
      children: [
        _buildTextFormField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your phone number';
            if (value.length != 10)
              return 'Phone number must be exactly 10 digits';
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Phone number must contain only digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationInfoCard() {
    return _buildInfoCard(
      title: 'Location Details',
      icon: Icons.location_on_outlined,
      children: [
        _buildTextFormField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_city_outlined,
          validator: (value) =>
          value == null || value.isEmpty
              ? 'Please enter your address'
              : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _zoneController,
          label: 'Zone',
          icon: Icons.map_outlined,
          validator: (value) =>
          value == null || value.isEmpty
              ? 'Please enter your zone'
              : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          value: _selectedState,
          items: _southStates,
          label: 'State',
          icon: Icons.flag_outlined,
          onChanged: (String? newValue) {
            setState(() {
              _selectedState = newValue;
            });
          },
          validator: (value) =>
          value == null || value.isEmpty
              ? 'Please select your state'
              : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          value: _selectedDistrict,
          items: _tamilNaduDistricts,
          label: 'District',
          icon: Icons.location_on_outlined,
          onChanged: (String? newValue) {
            setState(() {
              _selectedDistrict = newValue;
            });
          },
          validator: (value) =>
          value == null || value.isEmpty
              ? 'Please select your district'
              : null,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isEditMode ? [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ] : [],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLength: maxLength,
        readOnly: !_isEditMode,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.2),
                  const Color(0xFF2E7D32).withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: _isEditMode ? Colors.white : const Color(0xFFF8F9FA),
          labelStyle: TextStyle(
            color: _isEditMode ? const Color(0xFF4CAF50) : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          counterText: maxLength != null ? null : '',
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isEditMode ? [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ] : [],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
          );
        }).toList(),
        onChanged: _isEditMode ? onChanged : null,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.2),
                  const Color(0xFF2E7D32).withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: _isEditMode ? Colors.white : const Color(0xFFF8F9FA),
          labelStyle: TextStyle(
            color: _isEditMode ? const Color(0xFF4CAF50) : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 18),
        ),
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _isEditMode ? const Color(0xFF4CAF50) : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF2E7D32)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _showSaveConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Saving...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Save Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
