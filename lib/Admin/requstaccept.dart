import 'package:farmer_crate/Admin/adminreport.dart';
import 'package:farmer_crate/Admin/total_order.dart';
import 'package:farmer_crate/Admin/transpoter_mang.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Signin.dart';
import 'ConsumerManagement.dart';
import 'Farmeruser.dart';


class AdminManagementPage extends StatefulWidget {
  final dynamic user;
  final String token;
  const AdminManagementPage({Key? key, required this.user, required this.token}) : super(key: key);

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  List<Farmer> farmers = [];
  List<Transporter> transporters = [];
  bool isLoading = true;
  int _currentIndex = 0;
  String selectedCategory = 'Farmer'; // Default selection

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _fetchData();
  }

  Future<void> _checkAdminAccess() async {
    final role = widget.user['role'];
    final token = widget.token;

    print('=== Admin Access Check ===');
    print('Token: Present (${token.length} chars)');
    print('Role: $role');
    print('User: ${widget.user}');

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No authentication token found'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
      return;
    }

    if (role != 'admin' && role != 'super_admin' && role != 'moderator') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    }
  }

  Future<void> _fetchData() async {
    if (selectedCategory == 'Farmer') {
      await _fetchFarmers();
    } else {
      await _fetchTransporters();
    }
  }

  Future<void> _fetchFarmers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = widget.token;
      final role = widget.user['role'];

      print('=== Fetching Farmers ===');
      print('Token: Present (${token.length} chars)');
      print('Role: $role');

      if (token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedJson = jsonDecode(response.body);

        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson.containsKey('farmers') || decodedJson.containsKey('data')) {
            final List<dynamic> data = decodedJson['farmers'] ?? decodedJson['data'] ?? [];
            setState(() {
              farmers = data.map((json) => Farmer.fromJson(json)).toList();
              isLoading = false;
            });
            print('Successfully loaded ${farmers.length} farmers');
          } else if (decodedJson.containsKey('success') && decodedJson['success'] == true) {
            final List<dynamic> data = decodedJson['data'] ?? [];
            setState(() {
              farmers = data.map((json) => Farmer.fromJson(json)).toList();
              isLoading = false;
            });
            print('Successfully loaded ${farmers.length} farmers');
          } else {
            throw Exception('Unexpected response structure: ${response.body}');
          }
        } else if (decodedJson is List) {
          setState(() {
            farmers = decodedJson.map((json) => Farmer.fromJson(json)).toList();
            isLoading = false;
          });
          print('Successfully loaded ${farmers.length} farmers from direct array');
        } else {
          throw Exception('Unexpected response format: ${response.body}');
        }
      } else if (response.statusCode == 404) {
        // Try alternative endpoint for all farmers
        print('Pending endpoint not found, trying all farmers endpoint...');
        final allFarmersResponse = await http.get(
          Uri.parse('https://farmercrate.onrender.com/api/admin/farmers'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (allFarmersResponse.statusCode == 200) {
          final Map<String, dynamic> allFarmersData = jsonDecode(allFarmersResponse.body);

          if (allFarmersData.containsKey('farmers') || allFarmersData.containsKey('data')) {
            final List<dynamic> data = allFarmersData['farmers'] ?? allFarmersData['data'] ?? [];
            final pendingFarmers = data.where((farmer) =>
            farmer['verified_status'] == false ||
                farmer['isVerified'] == false ||
                farmer['verified'] == false
            ).toList();

            setState(() {
              farmers = pendingFarmers.map((json) => Farmer.fromJson(json)).toList();
              isLoading = false;
            });
            print('Successfully loaded ${farmers.length} pending farmers from all farmers');
          }
        } else {
          throw Exception('Failed to load farmers. Status: ${response.statusCode}');
        }
      } else {
        throw Exception('Failed to load farmers. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching farmers: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      print('Error details: $e');
    }
  }

  Future<void> _fetchTransporters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = widget.token;

      print('=== Fetching Transporters ===');
      print('Token: Present (${token.length} chars)');

      if (token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Try pending transporters endpoint first
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/transporters/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Transporter Response status: ${response.statusCode}');
      print('Transporter Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedJson = jsonDecode(response.body);

        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson.containsKey('transporters') || decodedJson.containsKey('data')) {
            final List<dynamic> data = decodedJson['transporters'] ?? decodedJson['data'] ?? [];
            setState(() {
              transporters = data.map((json) => Transporter.fromJson(json)).toList();
              isLoading = false;
            });
            print('Successfully loaded ${transporters.length} transporters');
          } else if (decodedJson.containsKey('success') && decodedJson['success'] == true) {
            final List<dynamic> data = decodedJson['data'] ?? [];
            setState(() {
              transporters = data.map((json) => Transporter.fromJson(json)).toList();
              isLoading = false;
            });
          }
        } else if (decodedJson is List) {
          setState(() {
            transporters = decodedJson.map((json) => Transporter.fromJson(json)).toList();
            isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        // Try alternative endpoint for all transporters
        print('Pending endpoint not found, trying all transporters endpoint...');
        final allTransportersResponse = await http.get(
          Uri.parse('https://farmercrate.onrender.com/api/admin/transporters'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (allTransportersResponse.statusCode == 200) {
          final Map<String, dynamic> allTransportersData = jsonDecode(allTransportersResponse.body);

          if (allTransportersData.containsKey('transporters') || allTransportersData.containsKey('data')) {
            final List<dynamic> data = allTransportersData['transporters'] ?? allTransportersData['data'] ?? [];
            final pendingTransporters = data.where((transporter) =>
            transporter['verified_status'] == false ||
                transporter['isVerified'] == false ||
                transporter['verified'] == false
            ).toList();

            setState(() {
              transporters = pendingTransporters.map((json) => Transporter.fromJson(json)).toList();
              isLoading = false;
            });
          }
        }
      } else {
        throw Exception('Failed to load transporters. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching transporters: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      print('Error details: $e');
    }
  }

  Future<void> _deleteItem(String itemId, String itemType) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Delete $itemType',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this $itemType? This action cannot be undone.',
            style: TextStyle(color: Color(0xFF424242)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF757575)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final token = widget.token;

                  if (token.isEmpty) {
                    throw Exception('No authentication token found. Please login again.');
                  }

                  final endpoint = itemType.toLowerCase() == 'farmer'
                      ? 'https://farmercrate.onrender.com/api/admin/farmers/$itemId'
                      : 'https://farmercrate.onrender.com/api/admin/transporters/$itemId';

                  final response = await http.delete(
                    Uri.parse(endpoint),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                  );

                  if (response.statusCode == 200 || response.statusCode == 204) {
                    setState(() {
                      if (itemType.toLowerCase() == 'farmer') {
                        farmers.removeWhere((farmer) => farmer.id == itemId);
                      } else {
                        transporters.removeWhere((transporter) => transporter.id == itemId);
                      }
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$itemType deleted successfully'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  } else {
                    throw Exception('Failed to delete $itemType. Status: ${response.statusCode}');
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting $itemType: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveItem(String itemId, String itemType) async {
    final uniqueId = _generateUniqueId(itemType);
    final TextEditingController approvalController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Approve $itemType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please provide approval notes for this $itemType account:'),
              SizedBox(height: 16),
              TextField(
                controller: approvalController,
                decoration: InputDecoration(
                  labelText: 'Approval Notes',
                  hintText: 'Enter approval notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
          actions: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (approvalController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please provide approval notes'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  await _processApproval(itemId, itemType, uniqueId, approvalController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Approve'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processApproval(String itemId, String itemType, String uniqueId, String approvalNotes) async {
    try {
      final token = widget.token;

      if (token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final isFarmer = itemType.toLowerCase() == 'farmer';
      final endpoint = isFarmer
          ? 'https://farmercrate.onrender.com/api/admin/farmers/$itemId/approve'
          : 'https://farmercrate.onrender.com/api/admin/transporters/$itemId/approve';

      print('=== Approving $itemType ===');
      print('Endpoint: $endpoint');
      print('Item ID: $itemId');
      print('Unique ID: $uniqueId');
      print('Approval Notes: $approvalNotes');

      http.Response response;

      if (isFarmer) {
        // Farmers: keep POST with payload
        final requestBody = {
          'unique_id': uniqueId,
          'verified': true,
          'verified_at': DateTime.now().toIso8601String(),
        };

        response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        );
      } else {
        // Transporters: use PUT method
        final requestBody = {
          'unique_id': uniqueId,
          'verified': true,
          'verified_at': DateTime.now().toIso8601String(),
          'approval_notes': approvalNotes,
        };

        response = await http.put(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        );
      }

      // Handle HTTP redirects explicitly (e.g., 307 from http->https)
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers['location'] != null) {
        final redirectUrl = response.headers['location']!;
        if (isFarmer) {
          response = await http.post(
            Uri.parse(redirectUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'unique_id': uniqueId,
              'verified': true,
              'verified_at': DateTime.now().toIso8601String(),
            }),
          );
        } else {
          response = await http.put(
            Uri.parse(redirectUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'unique_id': uniqueId,
              'verified': true,
              'verified_at': DateTime.now().toIso8601String(),
              'approval_notes': approvalNotes,
            }),
          );
        }
      }

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Show success message with the generated ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$itemType account verified successfully!'),
                SizedBox(height: 4),
                Text(
                  'Unique ID: $uniqueId',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!isFarmer) ...[
                  SizedBox(height: 4),
                  Text(
                    'Notes: $approvalNotes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copy ID',
              textColor: Colors.white,
              onPressed: () {
                // Copy to clipboard functionality can be added here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ID copied to clipboard: $uniqueId'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
        _fetchData(); // Refresh the list
      } else {
        String errorMessage = 'Failed to verify account';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage (Status: ${response.statusCode})'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _rejectItem(String itemId, String itemType) async {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reject $itemType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please provide a reason for rejecting this $itemType account:'),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'Enter the reason for rejection...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
          actions: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please provide a rejection reason'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  await _processRejection(itemId, itemType, reasonController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Reject'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRejection(String itemId, String itemType, String reason) async {
    try {
      final token = widget.token;

      if (token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final isFarmer = itemType.toLowerCase() == 'farmer';
      String endpoint = isFarmer
          ? 'https://farmercrate.onrender.com/api/admin/farmers/$itemId/reject'
          : 'https://farmercrate.onrender.com/api/admin/transporters/$itemId/reject';

      final requestBody = {
        'rejection_reason': reason,
        'rejected_at': DateTime.now().toIso8601String(),
      };

      print('=== Rejecting $itemType ===');
      print('Endpoint: $endpoint');
      print('Item ID: $itemId');
      print('Request Body: ${jsonEncode(requestBody)}');

      var response = isFarmer 
          ? await http.post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestBody),
            )
          : await http.put(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestBody),
            );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle HTTP redirects explicitly (e.g., 307 from http->https)
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers['location'] != null) {
        final redirectUrl = response.headers['location']!;
        response = isFarmer 
            ? await http.post(
                Uri.parse(redirectUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode(requestBody),
              )
            : await http.put(
                Uri.parse(redirectUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode(requestBody),
              );
      }


      if (response.statusCode == 200) {
        // Remove the rejected item from the local list
        setState(() {
          if (isFarmer) {
            farmers.removeWhere((farmer) => farmer.id == itemId);
          } else {
            transporters.removeWhere((transporter) => transporter.id == itemId);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemType account rejected successfully'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        _fetchData(); // Refresh the list
      } else {
        String errorMessage = 'Failed to reject account';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage (Status: ${response.statusCode})'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  String _generateUniqueId(String itemType) {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final prefix = itemType.toLowerCase() == 'farmer' ? 'FARM' : 'TRANS';
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '$prefix$random';
  }

  Widget _buildCategorySelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: screenWidth * 0.025,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (selectedCategory != 'Farmer') {
                  setState(() {
                    selectedCategory = 'Farmer';
                  });
                  _fetchData();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                decoration: BoxDecoration(
                  gradient: selectedCategory == 'Farmer'
                      ? const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  )
                      : null,
                  color: selectedCategory != 'Farmer' ? Colors.grey[100] : null,
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.agriculture,
                      color: selectedCategory == 'Farmer' ? Colors.white : Colors.grey[600],
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Farmers',
                      style: TextStyle(
                        color: selectedCategory == 'Farmer' ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (selectedCategory != 'Transporter') {
                  setState(() {
                    selectedCategory = 'Transporter';
                  });
                  _fetchData();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                decoration: BoxDecoration(
                  gradient: selectedCategory == 'Transporter'
                      ? const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                  )
                      : null,
                  color: selectedCategory != 'Transporter' ? Colors.grey[100] : null,
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping,
                      color: selectedCategory == 'Transporter' ? Colors.white : Colors.grey[600],
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Transporters',
                      style: TextStyle(
                        color: selectedCategory == 'Transporter' ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final currentList = selectedCategory == 'Farmer' ? farmers : transporters;
    final verifiedCount = selectedCategory == 'Farmer' 
        ? farmers.where((farmer) => farmer.isVerified).length
        : transporters.where((transporter) => transporter.isVerified).length;
    final pendingCount = selectedCategory == 'Farmer'
        ? farmers.where((farmer) => !farmer.isVerified).length
        : transporters.where((transporter) => !transporter.isVerified).length;

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
          'FarmerCrate Admin',
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
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refreshing ${selectedCategory.toLowerCase()}s list...'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 1),
                ),
              );
            },
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
                    'FarmerCrate Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome, Admin!',
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
              title: const Text('Home'),
              onTap: () {
                setState(() { _currentIndex = 0; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.pending_actions, color: Colors.green[600]),
              title: const Text('User Management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminUserManagementPage(
                      token: widget.token,
                      user: widget.user,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: Colors.green[600]),
              title: const Text('Consumer Management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerManagementScreen(
                      token: widget.token,
                      user: widget.user,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.green[600]),
              title: const Text('Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsPage(token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.green[600]),
              title: const Text('Transpoter Management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransporterManagementPage(
                      token: widget.token,
                      user: widget.user,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.green[600]),
              title: const Text('Total Orders'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrdersManagementPage(
                      user: widget.user,
                      token: widget.token,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFC8E6C9),
              Color(0xFFA5D6A7),
              Color(0xFF81C784),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedCategory} Management',
                      style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Manage ${selectedCategory.toLowerCase()} accounts and verification',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCategorySelector(),
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: screenWidth * 0.025,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total ${selectedCategory}s',
                      currentList.length.toString(),
                      Icons.group,
                    ),
                    Container(
                      height: screenHeight * 0.06,
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    _buildStatItem(
                      'Verified',
                      verifiedCount.toString(),
                      Icons.verified,
                    ),
                    Container(
                      height: screenHeight * 0.06,
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    _buildStatItem(
                      'Pending',
                      pendingCount.toString(),
                      Icons.pending,
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : currentList.isEmpty
                      ? RefreshIndicator(
                    onRefresh: _fetchData,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedCategory == 'Farmer' ? Icons.agriculture : Icons.local_shipping,
                            size: screenWidth * 0.2,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'No ${selectedCategory.toLowerCase()}s found',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Pull down to refresh',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: SingleChildScrollView(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: screenHeight * 0.025),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: screenWidth / (screenHeight * 0.2),
                          mainAxisSpacing: screenHeight * 0.02,
                        ),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          final item = currentList[index];
                          return selectedCategory == 'Farmer'
                              ? _buildFarmerCard(item as Farmer)
                              : _buildTransporterCard(item as Transporter);
                        },
                      ),
                    ),
                  ),
                ),
              ),
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
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            
            // Handle navigation based on selected index
            if (index == 2) { // Orders tab
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersManagementPage(
                    user: widget.user,
                    token: widget.token,
                  ),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions, size: 24),
              label: 'Total Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pin_invoke_sharp, size: 24),
              label: 'Report',
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

  Widget _buildStatItem(String title, String value, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2E7D32),
          size: screenWidth * 0.07,
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: const Color(0xFF424242),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmerCard(Farmer farmer) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: screenWidth * 0.025,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.075),
                  ),
                  child: farmer.imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.075),
                    child: Image.network(
                      farmer.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            farmer.name.split(' ').map((n) => n[0]).take(2).join(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                      : Center(
                    child: Text(
                      farmer.name.split(' ').map((n) => n[0]).take(2).join(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.05),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              farmer.name,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (farmer.isVerified)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenWidth * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                              child: Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.025,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(Icons.email, farmer.email),
                                _buildDetailRow(Icons.phone, farmer.mobileNumber),
                                _buildDetailRow(Icons.location_on, farmer.address),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(Icons.landscape, farmer.zone),
                                _buildDetailRow(Icons.grass, farmer.state),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: () => _approveItem(farmer.id, 'Farmer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: farmer.isVerified ? const Color(0xFF4CAF50) : const Color(0xFF8BC34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        elevation: 2,
                        minimumSize: Size(screenWidth * 0.12, screenHeight * 0.04),
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                      ),
                      child: Text(
                        farmer.isVerified ? 'Verified' : 'Verify',
                        style: TextStyle(fontSize: screenWidth * 0.028),
                      ),
                    ),
                  ),
                ),
                if (!farmer.isVerified)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: ElevatedButton(
                        onPressed: () => _rejectItem(farmer.id, 'Farmer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          elevation: 2,
                          minimumSize: Size(screenWidth * 0.12, screenHeight * 0.04),
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                        ),
                        child: Text(
                          'Reject',
                          style: TextStyle(fontSize: screenWidth * 0.028),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: () => _showFarmerDetailsDialog(farmer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        elevation: 2,
                        minimumSize: Size(screenWidth * 0.12, screenHeight * 0.04),
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                      ),
                      child: Text(
                        'Details',
                        style: TextStyle(fontSize: screenWidth * 0.028),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransporterCard(Transporter transporter) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: screenWidth * 0.025,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.075),
                  ),
                  child: transporter.imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.075),
                    child: Image.network(
                      transporter.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            transporter.name.split(' ').map((n) => n[0]).take(2).join(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                      : Center(
                    child: Text(
                      transporter.name.split(' ').map((n) => n[0]).take(2).join(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.05),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transporter.name,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (transporter.isVerified)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenWidth * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                              child: Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.025,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(Icons.email, transporter.email),
                                _buildDetailRow(Icons.phone, transporter.mobileNumber),
                                _buildDetailRow(Icons.location_on, transporter.address),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(Icons.local_shipping, transporter.vehicleType),
                                _buildDetailRow(Icons.confirmation_number, transporter.vehicleNumber),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: () => _approveItem(transporter.id, 'Transporter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: transporter.isVerified ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        elevation: 2,
                        minimumSize: Size(screenWidth * 0.12, screenHeight * 0.04),
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                      ),
                      child: Text(
                        transporter.isVerified ? 'Verified' : 'Verify',
                        style: TextStyle(fontSize: screenWidth * 0.028),
                      ),
                    ),
                  ),
                ),
                if (!transporter.isVerified)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: ElevatedButton(
                        onPressed: () => _rejectItem(transporter.id, 'Transporter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          elevation: 2,
                          minimumSize: Size(screenWidth * 0.12, screenHeight * 0.04),
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                        ),
                        child: Text(
                          'Reject',
                          style: TextStyle(fontSize: screenWidth * 0.028),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: () => _showTransporterDetailsDialog(transporter),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        elevation: 2,
                        minimumSize: Size(screenWidth * 0.12, screenHeight * 0.04),
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                      ),
                      child: Text(
                        'Details',
                        style: TextStyle(fontSize: screenWidth * 0.028),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.01),
      child: Row(
        children: [
          Icon(
            icon,
            size: screenWidth * 0.035,
            color: const Color(0xFF757575),
          ),
          SizedBox(width: screenWidth * 0.015),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: const Color(0xFF424242),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showFarmerDetailsDialog(Farmer farmer) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FarmerDetailsFullScreen(farmer: farmer),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _showTransporterDetailsDialog(Transporter transporter) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _TransporterDetailsFullScreen(transporter: transporter),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}

// Transporter Details Full Screen
class _TransporterDetailsFullScreen extends StatelessWidget {
  final Transporter transporter;

  const _TransporterDetailsFullScreen({
    required this.transporter,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
              Color(0xFF90CAF9),
              Color(0xFF64B5F6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF1565C0)),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Text(
                        'Transporter Details',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenWidth * 0.02,
                      ),
                      decoration: BoxDecoration(
                        gradient: transporter.isVerified
                            ? const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        )
                            : const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        boxShadow: [
                          BoxShadow(
                            color: (transporter.isVerified
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800))
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            transporter.isVerified ? Icons.verified : Icons.pending,
                            color: Colors.white,
                            size: screenWidth * 0.04,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            transporter.isVerified ? 'VERIFIED' : 'PENDING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: screenWidth * 0.25,
                              height: screenWidth * 0.25,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.125),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2196F3).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: transporter.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(screenWidth * 0.125),
                                child: Image.network(
                                  transporter.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        transporter.name.split(' ').map((n) => n[0]).take(2).join(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.08,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                                  : Center(
                                child: Text(
                                  transporter.name.split(' ').map((n) => n[0]).take(2).join(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.08,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.04),
                            Text(
                              transporter.name,
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1565C0),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            Text(
                              transporter.email,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: const Color(0xFF757575),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Personal Information',
                        Icons.person,
                        [
                          _buildInfoTile(Icons.phone, 'Mobile Number', transporter.mobileNumber),
                          _buildInfoTile(Icons.cake, 'Age', '${transporter.age} years'),
                          _buildInfoTile(Icons.location_on, 'Address', transporter.address),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Vehicle Information',
                        Icons.local_shipping,
                        [
                          _buildInfoTile(Icons.directions_car, 'Vehicle Type', transporter.vehicleType),
                          _buildInfoTile(Icons.confirmation_number, 'Vehicle Number', transporter.vehicleNumber),
                          _buildInfoTile(Icons.card_membership, 'License Number', transporter.licenseNumber),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Location Details',
                        Icons.map,
                        [
                          _buildInfoTile(Icons.location_city, 'State', transporter.state),
                          _buildInfoTile(Icons.domain, 'District', transporter.district),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Banking Details',
                        Icons.account_balance,
                        [
                          _buildInfoTile(Icons.account_balance_wallet, 'Account Number', transporter.accountNumber),
                          _buildInfoTile(Icons.code, 'IFSC Code', transporter.ifscCode),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Account Information',
                        Icons.info,
                        [
                          _buildInfoTile(Icons.calendar_today, 'Created At', transporter.createdAt),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.08),
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

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.isEmpty ? const Color(0xFF9E9E9E) : const Color(0xFF424242),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Farmer Details Full Screen
class _FarmerDetailsFullScreen extends StatelessWidget {
  final Farmer farmer;

  const _FarmerDetailsFullScreen({
    required this.farmer,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFC8E6C9),
              Color(0xFFA5D6A7),
              Color(0xFF81C784),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Text(
                        'Farmer Details',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenWidth * 0.02,
                      ),
                      decoration: BoxDecoration(
                        gradient: farmer.isVerified
                            ? const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        )
                            : const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        boxShadow: [
                          BoxShadow(
                            color: (farmer.isVerified
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800))
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            farmer.isVerified ? Icons.verified : Icons.pending,
                            color: Colors.white,
                            size: screenWidth * 0.04,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            farmer.isVerified ? 'VERIFIED' : 'PENDING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: screenWidth * 0.25,
                              height: screenWidth * 0.25,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.125),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: farmer.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(screenWidth * 0.125),
                                child: Image.network(
                                  farmer.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        farmer.name.split(' ').map((n) => n[0]).take(2).join(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.08,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                                  : Center(
                                child: Text(
                                  farmer.name.split(' ').map((n) => n[0]).take(2).join(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.08,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.04),
                            Text(
                              farmer.name,
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            Text(
                              farmer.email,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: const Color(0xFF757575),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildFarmerInfoSection(
                        'Personal Information',
                        Icons.person,
                        [
                          _buildFarmerInfoTile(Icons.phone, 'Mobile Number', farmer.mobileNumber),
                          _buildFarmerInfoTile(Icons.cake, 'Age', '${farmer.age} years'),
                          _buildFarmerInfoTile(Icons.location_on, 'Address', farmer.address),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildFarmerInfoSection(
                        'Location Details',
                        Icons.map,
                        [
                          _buildFarmerInfoTile(Icons.landscape, 'Zone', farmer.zone),
                          _buildFarmerInfoTile(Icons.location_city, 'State', farmer.state),
                          _buildFarmerInfoTile(Icons.domain, 'District', farmer.district),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildFarmerInfoSection(
                        'Banking Details',
                        Icons.account_balance,
                        [
                          _buildFarmerInfoTile(Icons.account_balance_wallet, 'Account Number', farmer.accountNumber),
                          _buildFarmerInfoTile(Icons.code, 'IFSC Code', farmer.ifscCode),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildFarmerInfoSection(
                        'Account Information',
                        Icons.info,
                        [
                          _buildFarmerInfoTile(Icons.calendar_today, 'Created At', farmer.createdAt),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.08),
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

  Widget _buildFarmerInfoSection(String title, IconData icon, List<Widget> children, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFarmerInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.isEmpty ? const Color(0xFF9E9E9E) : const Color(0xFF424242),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Transporter Model
class Transporter {
  final String id;
  final String name;
  final String email;
  final String mobileNumber;
  final String address;
  final String state;
  final String district;
  final int age;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final String accountNumber;
  final String ifscCode;
  final String imageUrl;
  final String createdAt;
  final String uniqueId;
  bool isVerified;

  Transporter({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.state,
    required this.district,
    required this.age,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.licenseNumber,
    required this.accountNumber,
    required this.ifscCode,
    required this.imageUrl,
    required this.createdAt,
    required this.uniqueId,
    required this.isVerified,
  });

  factory Transporter.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing transporter JSON: $json');

      // Handle different verification status field names
      bool isVerified = false;
      if (json.containsKey('verified_status')) {
        isVerified = json['verified_status'] == true;
      } else if (json.containsKey('isVerified')) {
        isVerified = json['isVerified'] == true;
      } else if (json.containsKey('verified')) {
        isVerified = json['verified'] == true;
      } else if (json.containsKey('status')) {
        isVerified = json['status'] == 'verified' || json['status'] == 'approved';
      }

      return Transporter(
        id: json['id']?.toString() ?? json['transporter_id']?.toString() ?? '',
        name: json['name'] ?? json['transporter_name'] ?? '',
        email: json['email'] ?? '',
        mobileNumber: json['mobile_number'] ?? json['mobileNumber'] ?? '',
        address: json['address'] ?? '',
        state: json['state'] ?? '',
        district: json['district'] ?? '',
        age: json['age'] ?? 0,
        vehicleType: json['vehicle_type'] ?? json['vehicleType'] ?? '',
        vehicleNumber: json['vehicle_number'] ?? json['vehicleNumber'] ?? '',
        licenseNumber: json['license_number'] ?? json['licenseNumber'] ?? '',
        accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
        ifscCode: json['ifsc_code'] ?? json['ifscCode'] ?? '',
        imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
        createdAt: json['created_at'] ?? json['createdAt'] ?? '',
        uniqueId: json['unique_id'] ?? json['uniqueId'] ?? '',
        isVerified: isVerified,
      );
    } catch (e) {
      print('Error parsing transporter JSON: $e');
      print('JSON data: $json');
      // Return a default transporter object if parsing fails
      return Transporter(
        id: '0',
        name: 'Error parsing transporter data',
        email: '',
        mobileNumber: '',
        address: '',
        state: '',
        district: '',
        age: 0,
        vehicleType: '',
        vehicleNumber: '',
        licenseNumber: '',
        accountNumber: '',
        ifscCode: '',
        imageUrl: '',
        createdAt: '',
        uniqueId: '',
        isVerified: false,
      );
    }
  }
}

// Farmer Model (keeping the original)
class Farmer {
  final String id;
  final String name;
  final String email;
  final String mobileNumber;
  final String address;
  final String zone;
  final String state;
  final String district;
  final int age;
  final String accountNumber;
  final String ifscCode;
  final String imageUrl;
  final String createdAt;
  final String uniqueId;
  bool isVerified;

  Farmer({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.zone,
    required this.state,
    required this.district,
    required this.age,
    required this.accountNumber,
    required this.ifscCode,
    required this.imageUrl,
    required this.createdAt,
    required this.uniqueId,
    required this.isVerified,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing farmer JSON: $json');

      // Handle different verification status field names
      bool isVerified = false;
      if (json.containsKey('verified_status')) {
        isVerified = json['verified_status'] == true;
      } else if (json.containsKey('isVerified')) {
        isVerified = json['isVerified'] == true;
      } else if (json.containsKey('verified')) {
        isVerified = json['verified'] == true;
      } else if (json.containsKey('status')) {
        isVerified = json['status'] == 'verified' || json['status'] == 'approved';
      }

      return Farmer(
        id: json['id']?.toString() ?? json['farmer_id']?.toString() ?? '',
        name: json['name'] ?? json['farmer_name'] ?? '',
        email: json['email'] ?? '',
        mobileNumber: json['mobile_number'] ?? json['mobileNumber'] ?? '',
        address: json['address'] ?? '',
        zone: json['zone'] ?? '',
        state: json['state'] ?? '',
        district: json['district'] ?? '',
        age: json['age'] ?? 0,
        accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
        ifscCode: json['ifsc_code'] ?? json['ifscCode'] ?? '',
        imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
        createdAt: json['created_at'] ?? json['createdAt'] ?? '',
        uniqueId: json['unique_id'] ?? json['uniqueId'] ?? '',
        isVerified: isVerified,
      );
    } catch (e) {
      print('Error parsing farmer JSON: $e');
      print('JSON data: $json');
      // Return a default farmer object if parsing fails
      return Farmer(
        id: '0',
        name: 'Error parsing farmer data',
        email: '',
        mobileNumber: '',
        address: '',
        zone: '',
        state: '',
        district: '',
        age: 0,
        accountNumber: '',
        ifscCode: '',
        imageUrl: '',
        createdAt: '',
        uniqueId: '',
        isVerified: false,
      );
    }
  }
}