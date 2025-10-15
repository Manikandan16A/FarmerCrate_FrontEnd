import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'transporter_dashboard.dart';
import 'order_status_page.dart';
import 'order_history_page.dart';
import 'profile_page.dart';

class VehiclePage extends StatefulWidget {
  final String? token;

  const VehiclePage({super.key, this.token});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  List<dynamic> permanentVehicles = [];
  List<dynamic> temporaryVehicles = [];
  bool isLoading = true;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false, bool isInfo = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      ),
    );

    await Future.delayed(Duration(milliseconds: 500));
    Navigator.of(context, rootNavigator: true).pop();

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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  Future<void> _fetchVehicles() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/vehicles'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fleetData = data['data'];
        setState(() {
          permanentVehicles = fleetData['permanent_vehicles'] ?? [];
          temporaryVehicles = fleetData['temporary_vehicles'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showAddVehicleDialog() {
    final vehicleNumberController = TextEditingController();
    final vehicleTypeController = TextEditingController();
    final capacityController = TextEditingController();
    String selectedType = 'permanent';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Vehicle', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: vehicleNumberController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.confirmation_number, color: Color(0xFF2E7D32)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: vehicleTypeController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.category, color: Color(0xFF2E7D32)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Capacity (tons)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.scale, color: Color(0xFF2E7D32)),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.type_specimen, color: Color(0xFF2E7D32)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'permanent', child: Text('Permanent')),
                    DropdownMenuItem(value: 'temporary', child: Text('Temporary')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (vehicleNumberController.text.isNotEmpty &&
                    vehicleTypeController.text.isNotEmpty &&
                    capacityController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _addVehicle(
                    vehicleNumberController.text,
                    vehicleTypeController.text,
                    double.parse(capacityController.text),
                    selectedType,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addVehicle(String vehicleNumber, String vehicleType, double capacity, String type) async {
    try {
      final response = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'vehicle_number': vehicleNumber,
          'vehicle_type': vehicleType,
          'capacity': capacity,
          'type': type,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Vehicle added successfully');
        _fetchVehicles();
      } else {
        _showSnackBar('Failed to add vehicle', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    Widget page;
    switch (index) {
      case 0:
        page = TransporterDashboard(token: widget.token);
        break;
      case 1:
        page = OrderStatusPage(token: widget.token);
        break;
      case 2:
        page = OrderHistoryPage(token: widget.token);
        break;
      case 4:
        page = ProfilePage(token: widget.token);
        break;
      default:
        return;
    }
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        title: Text('Vehicles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _showAddVehicleDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchVehicles,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _fetchVehicles,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
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
                          child: Icon(Icons.local_shipping, color: Color(0xFF2E7D32), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text('Permanent Vehicles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    SizedBox(height: 12),
                    permanentVehicles.isEmpty
                        ? _buildEmptyState('No permanent vehicles')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: permanentVehicles.length,
                            itemBuilder: (context, index) => _buildVehicleCard(permanentVehicles[index], true),
                          ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.directions_car, color: Color(0xFF4CAF50), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text('Temporary Vehicles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    SizedBox(height: 12),
                    temporaryVehicles.isEmpty
                        ? _buildEmptyState('No temporary vehicles')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: temporaryVehicles.length,
                            itemBuilder: (context, index) => _buildVehicleCard(temporaryVehicles[index], false),
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleDialog,
        backgroundColor: Color(0xFF2E7D32),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Add Vehicle', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(dynamic vehicle, bool isPermanent) {
    final isAvailable = vehicle['is_available'] ?? false;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isPermanent ? Color(0xFF2E7D32) : Color(0xFF4CAF50)).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isPermanent ? Color(0xFF2E7D32) : Color(0xFF4CAF50)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPermanent ? Icons.local_shipping : Icons.directions_car,
              color: isPermanent ? Color(0xFF2E7D32) : Color(0xFF4CAF50),
              size: 28,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle['vehicle_number'] ?? 'N/A',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                SizedBox(height: 4),
                Text(
                  '${vehicle['vehicle_type']?.toUpperCase() ?? 'N/A'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                SizedBox(height: 2),
                Text(
                  'Capacity: ${vehicle['capacity'] ?? 0} tons',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAvailable ? Color(0xFF4CAF50) : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAvailable ? 'Available' : 'In Use',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(message, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
