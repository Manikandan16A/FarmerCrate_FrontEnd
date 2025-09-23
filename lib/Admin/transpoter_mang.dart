import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'common_navigation.dart';

class Transporter {
  final int transporterId;
  final String? uniqueId;
  final String name;
  final String mobileNumber;
  final String email;
  final int? age;
  final String address;
  final String zone;
  final String district;
  final String state;
  final bool verifiedStatus;
  final String? approvedAt;
  final String? approvalNotes;
  final String? rejectedAt;
  final String? rejectionReason;
  final String? codeUpdatedAt;
  final String? imageUrl;
  final String? aadharUrl;
  final String? panUrl;
  final String? voterIdUrl;
  final String? licenseUrl;
  final String? aadharNumber;
  final String? panNumber;
  final String? voterIdNumber;
  final String? licenseNumber;
  final String createdAt;
  final String updatedAt;

  Transporter({
    required this.transporterId,
    this.uniqueId,
    required this.name,
    required this.mobileNumber,
    required this.email,
    this.age,
    required this.address,
    required this.zone,
    required this.district,
    required this.state,
    required this.verifiedStatus,
    this.approvedAt,
    this.approvalNotes,
    this.rejectedAt,
    this.rejectionReason,
    this.codeUpdatedAt,
    this.imageUrl,
    this.aadharUrl,
    this.panUrl,
    this.voterIdUrl,
    this.licenseUrl,
    this.aadharNumber,
    this.panNumber,
    this.voterIdNumber,
    this.licenseNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transporter.fromJson(Map<String, dynamic> json) {
    return Transporter(
      transporterId: json['transporter_id'],
      uniqueId: json['unique_id'],
      name: json['name'] ?? 'Unknown',
      mobileNumber: json['mobile_number'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      age: json['age'],
      address: json['address'] ?? 'N/A',
      zone: json['zone'] ?? 'N/A',
      district: json['district'] ?? 'N/A',
      state: json['state'] ?? 'N/A',
      verifiedStatus: json['verified_status'] ?? false,
      approvedAt: json['approved_at'],
      approvalNotes: json['approval_notes'],
      rejectedAt: json['rejected_at'],
      rejectionReason: json['rejection_reason'],
      codeUpdatedAt: json['code_updated_at'],
      imageUrl: json['image_url'],
      aadharUrl: json['aadhar_url'],
      panUrl: json['pan_url'],
      voterIdUrl: json['voter_id_url'],
      licenseUrl: json['license_url'],
      aadharNumber: json['aadhar_number'],
      panNumber: json['pan_number'],
      voterIdNumber: json['voter_id_number'],
      licenseNumber: json['license_number'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class TransporterManagementPage extends StatefulWidget {
  final String? token;
  final dynamic user;
  const TransporterManagementPage({Key? key, this.token, this.user}) : super(key: key);

  @override
  State<TransporterManagementPage> createState() => _TransporterManagementPageState();
}

class _TransporterManagementPageState extends State<TransporterManagementPage> {
  String _searchQuery = '';
  List<Transporter> transporters = [];
  bool _isLoading = true;
  String _filterStatus = 'All';
  int _currentIndex = 0; // Home tab is selected (no specific tab for transporters)

  @override
  void initState() {
    super.initState();
    _fetchTransporters();
  }

  Future<void> _fetchTransporters() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      // Add authorization header if token is available
      if (widget.token != null && widget.token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      }

      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/transporters/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            transporters = (data['data'] as List)
                .map((transporterJson) => Transporter.fromJson(transporterJson))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar('Failed to load transporter data');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Network error: $e');
    }
  }

  Future<void> _deleteTransporter(int transporterId) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      // Add authorization header if token is available
      if (widget.token != null && widget.token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      }

      final response = await http.delete(
        Uri.parse('https://farmercrate.onrender.com/api/admin/transporters/$transporterId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          transporters.removeWhere((t) => t.transporterId == transporterId);
        });
        _showSuccessSnackBar('Transporter deleted successfully');
      } else if (response.statusCode == 401) {
        _showErrorSnackBar('Authentication failed. Please login again.');
      } else {
        _showErrorSnackBar('Failed to delete transporter. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting transporter: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminNavigation.buildAppBar(context, 'Transporter Management', onRefresh: _fetchTransporters),
      drawer: AdminNavigation.buildDrawer(context, widget.user ?? {}, widget.token ?? ''),
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
              _buildFilterSection(),
              Expanded(
                child: _isLoading ? _buildLoadingWidget() : _buildTransporterList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminNavigation.buildBottomNavigationBar(context, _currentIndex, widget.user ?? {}, widget.token ?? ''),
    );
  }


  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 60,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading Transporters...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait while we fetch transporter details',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _fetchTransporters,
              icon: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search transporters...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF4CAF50)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Verified'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status) {
    final isSelected = _filterStatus == status;
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'Verified':
        backgroundColor = isSelected ? Colors.green : Colors.green[100]!;
        textColor = isSelected ? Colors.white : Colors.green[700]!;
        break;
      case 'Pending':
        backgroundColor = isSelected ? Colors.orange : Colors.orange[100]!;
        textColor = isSelected ? Colors.white : Colors.orange[700]!;
        break;
      case 'Rejected':
        backgroundColor = isSelected ? Colors.red : Colors.red[100]!;
        textColor = isSelected ? Colors.white : Colors.red[700]!;
        break;
      default:
        backgroundColor = isSelected ? Colors.grey[600]! : Colors.grey[200]!;
        textColor = isSelected ? Colors.white : Colors.grey[700]!;
    }

    return FilterChip(
      label: Text(status),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
        });
      },
      backgroundColor: backgroundColor,
      selectedColor: backgroundColor,
      labelStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? backgroundColor : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildTransporterList() {
    // Filter transporters based on search query and status
    List<Transporter> filteredTransporters = transporters.where((transporter) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          transporter.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          transporter.transporterId.toString().contains(_searchQuery) ||
          transporter.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          transporter.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          transporter.zone.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          transporter.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          transporter.district.toLowerCase().contains(_searchQuery.toLowerCase());

      // Status filter
      bool matchesFilter = true;
      if (_filterStatus == 'Verified') {
        matchesFilter = transporter.verifiedStatus == true;
      } else if (_filterStatus == 'Pending') {
        matchesFilter = transporter.verifiedStatus == false && transporter.rejectedAt == null;
      } else if (_filterStatus == 'Rejected') {
        matchesFilter = transporter.rejectedAt != null;
      }
      // 'All' shows everything

      return matchesSearch && matchesFilter;
    }).toList();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          // Show filter status and count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filterStatus} Transporters',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  '${filteredTransporters.length} found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredTransporters.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredTransporters.length,
              itemBuilder: (context, index) {
                return _buildTransporterCard(filteredTransporters[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No transporters found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Try adjusting your search',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransporterCard(Transporter transporter) {
    // Determine the status text and color
    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (transporter.rejectedAt != null) {
      statusText = 'Rejected';
      statusColor = Colors.red[700]!;
      statusBgColor = Colors.red[100]!;
    } else if (transporter.verifiedStatus) {
      statusText = 'Verified';
      statusColor = Colors.green[700]!;
      statusBgColor = Colors.green[100]!;
    } else {
      statusText = 'Pending';
      statusColor = Colors.orange[700]!;
      statusBgColor = Colors.orange[100]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E7D32),
          radius: 25,
          child: const Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          transporter.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(transporter.email, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text('${transporter.district}, ${transporter.state}', style: TextStyle(color: Colors.grey[600])),
            if (transporter.rejectedAt != null && transporter.rejectionReason != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'Rejected: ${transporter.rejectionReason}',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _showDeleteConfirmationDialog(transporter),
            ),
          ],
        ),
        onTap: () => _showTransporterInfoDialog(transporter),
      ),
    );
  }

  void _showTransporterInfoDialog(Transporter transporter) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Determine the status text and color
        String statusText;
        Color statusColor;

        if (transporter.rejectedAt != null) {
          statusText = 'Rejected';
          statusColor = Colors.red;
        } else if (transporter.verifiedStatus) {
          statusText = 'Verified';
          statusColor = Colors.green;
        } else {
          statusText = 'Pending';
          statusColor = Colors.orange;
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFF2E7D32),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transporter.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${transporter.transporterId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Transporter Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow('Mobile', transporter.mobileNumber),
                _buildInfoRow('Email', transporter.email),
                _buildInfoRow('Address', transporter.address),
                _buildInfoRow('Zone', transporter.zone),
                _buildInfoRow('District', transporter.district),
                _buildInfoRow('State', transporter.state),
                _buildInfoRow('Join Date', _formatDate(transporter.createdAt)),
                if (transporter.age != null) _buildInfoRow('Age', transporter.age.toString()),

                // Show rejection details if rejected
                if (transporter.rejectedAt != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red[600], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Rejection Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Rejected Date', _formatDate(transporter.rejectedAt!)),
                        if (transporter.rejectionReason != null)
                          _buildInfoRow('Rejection Reason', transporter.rejectionReason!),
                        if (transporter.approvalNotes != null)
                          _buildInfoRow('Approval Notes', transporter.approvalNotes!),
                      ],
                    ),
                  ),
                ],

                // Show approval details if verified
                if (transporter.verifiedStatus && transporter.approvedAt != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green[600], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Approval Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Approved Date', _formatDate(transporter.approvedAt!)),
                        if (transporter.approvalNotes != null)
                          _buildInfoRow('Approval Notes', transporter.approvalNotes!),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Color(0xFF4CAF50)),
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


  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Transporter transporter) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Transporter',
            style: TextStyle(color: Color(0xFF2E7D32)),
          ),
          content: Text(
            'Are you sure you want to delete transporter "${transporter.name}"?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteTransporter(transporter.transporterId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}