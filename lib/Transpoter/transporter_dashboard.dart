import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'adddeliveryperson.dart';
import 'order_status_page.dart' show OrderStatusPage;
import 'order_history_page.dart';
import 'vehicle_page.dart';
import 'profile_page.dart';

class TransporterDashboard extends StatefulWidget {
  final String? token;

  const TransporterDashboard({super.key, this.token});

  @override
  State<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends State<TransporterDashboard> {
  List<dynamic> deliveryPersons = [];
  List<dynamic> sourceOrders = [];
  List<dynamic> destinationOrders = [];
  List<dynamic> permanentVehicles = [];
  List<dynamic> temporaryVehicles = [];
  bool isLoadingPersons = true;
  bool isLoadingOrders = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryPersons();
    _fetchAllocatedOrders();
    _fetchVehicles();
    _showNewOrderNotification();
  }

  void _showNewOrderNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sourceOrders.isNotEmpty || destinationOrders.isNotEmpty) {
        final totalOrders = sourceOrders.length + destinationOrders.length;
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
                  child: Icon(Icons.notifications_active, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$totalOrders new order${totalOrders > 1 ? 's' : ''} waiting for assignment',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            elevation: 6,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _fetchDeliveryPersons() async {
    setState(() => isLoadingPersons = true);
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/transporters/delivery-persons'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          deliveryPersons = data['data'] ?? [];
          isLoadingPersons = false;
        });
      } else {
        setState(() => isLoadingPersons = false);
        _showSnackBar('Failed to load delivery persons', isError: true);
      }
    } catch (e) {
      setState(() => isLoadingPersons = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _fetchAllocatedOrders() async {
    setState(() => isLoadingOrders = true);
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/orders/transporter/allocated'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('Orders API Status: ${response.statusCode}');
      print('Orders API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allOrders = data['data'] ?? [];
        print('Total Orders: ${allOrders.length}');
        print('All Orders: $allOrders');
        
        final srcOrders = allOrders.where((order) => 
          order['transporter_role'] == 'PICKUP_SHIPPING' && 
          order['current_status'] == 'PLACED'
        ).toList();
        final destOrders = allOrders.where((order) => 
          order['transporter_role'] == 'DELIVERY' && 
          order['current_status'] == 'RECEIVED'
        ).toList();
        
        print('Source Orders Count: ${srcOrders.length}');
        print('Destination Orders Count: ${destOrders.length}');
        
        setState(() {
          sourceOrders = srcOrders;
          destinationOrders = destOrders;
          isLoadingOrders = false;
        });
        
        _showNewOrderNotification();
      } else {
        setState(() => isLoadingOrders = false);
        _showSnackBar('Failed to load allocated orders', isError: true);
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => isLoadingOrders = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _fetchVehicles() async {
    try {
      print('=== Fetching Vehicles ===');
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/vehicles'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('Vehicle API Status Code: ${response.statusCode}');
      print('Vehicle API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Data: $data');
        final fleetData = data['data'];
        print('Fleet Data: $fleetData');
        final permVehicles = fleetData['permanent_vehicles'] ?? [];
        final tempVehicles = fleetData['temporary_vehicles'] ?? [];
        print('Permanent Vehicles Count: ${permVehicles.length}');
        print('Permanent Vehicles: $permVehicles');
        print('Temporary Vehicles Count: ${tempVehicles.length}');
        print('Temporary Vehicles: $tempVehicles');
        setState(() {
          permanentVehicles = permVehicles;
          temporaryVehicles = tempVehicles;
        });
        print('State Updated - Permanent: ${permanentVehicles.length}, Temporary: ${temporaryVehicles.length}');
      } else {
        print('Failed to fetch vehicles: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error fetching vehicles: $e');
      print('Stack Trace: $stackTrace');
    }
  }

  Future<void> _assignVehicle(int orderId, String orderType) async {
    await _fetchVehicles();
    
    int? selectedVehicleId;
    String? selectedVehicleType;
    int? selectedDeliveryPersonId;
    final isSourceOrder = orderType == 'source';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isSourceOrder ? 'Assign Vehicle & Delivery Person' : 'Assign Delivery Person', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSourceOrder) ...[
                Text('Select Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32))),
                SizedBox(height: 12),
                if (permanentVehicles.isNotEmpty) ...[
                  Text('Permanent Vehicles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[700])),
                  SizedBox(height: 8),
                  ...permanentVehicles.map((vehicle) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: selectedVehicleId == vehicle['vehicle_id'] ? Color(0xFF2E7D32) : Colors.grey[300]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: selectedVehicleId == vehicle['vehicle_id'] ? Color(0xFF2E7D32).withOpacity(0.05) : Colors.white,
                    ),
                    child: InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedVehicleId = vehicle['vehicle_id'];
                          selectedVehicleType = 'permanent';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xFF2E7D32).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.local_shipping, color: Color(0xFF2E7D32), size: 28),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vehicle['vehicle_number'] ?? 'N/A', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                                  SizedBox(height: 4),
                                  Text('${vehicle['vehicle_type']?.toUpperCase() ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                  SizedBox(height: 2),
                                  Text('Capacity: ${vehicle['capacity'] ?? 0} tons', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            if (selectedVehicleId == vehicle['vehicle_id'])
                              Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
                          ],
                        ),
                      ),
                    ),
                  )),
                ],
                if (temporaryVehicles.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text('Temporary Vehicles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[700])),
                  SizedBox(height: 8),
                  ...temporaryVehicles.map((vehicle) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: selectedVehicleId == vehicle['vehicle_id'] ? Color(0xFF4CAF50) : Colors.grey[300]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: selectedVehicleId == vehicle['vehicle_id'] ? Color(0xFF4CAF50).withOpacity(0.05) : Colors.white,
                    ),
                    child: InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedVehicleId = vehicle['vehicle_id'];
                          selectedVehicleType = 'temporary';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.directions_car, color: Color(0xFF4CAF50), size: 28),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vehicle['vehicle_number'] ?? 'N/A', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                                  SizedBox(height: 4),
                                  Text('${vehicle['vehicle_type']?.toUpperCase() ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                  SizedBox(height: 2),
                                  Text('Capacity: ${vehicle['capacity'] ?? 0} tons', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            if (selectedVehicleId == vehicle['vehicle_id'])
                              Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                          ],
                        ),
                      ),
                    ),
                  )),
                ],
                if (permanentVehicles.isEmpty && temporaryVehicles.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('No vehicles available', style: TextStyle(color: Colors.grey[600]))),
                  ),
                Divider(height: 32),
                ],
                if (!isSourceOrder)
                  SizedBox(height: 8),
                Text('Select Delivery Person', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32))),
                SizedBox(height: 8),
                if (deliveryPersons.isNotEmpty) ...[
                  ...deliveryPersons.map((person) => RadioListTile<int>(
                    value: person['delivery_person_id'],
                    groupValue: selectedDeliveryPersonId,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDeliveryPersonId = value;
                      });
                    },
                    title: Text(person['name'] ?? 'N/A', style: TextStyle(fontSize: 14)),
                    subtitle: Text('${person['mobile_number'] ?? 'N/A'} - ${person['vehicle_type'] ?? 'N/A'}', style: TextStyle(fontSize: 12)),
                    secondary: Icon(Icons.person, color: Color(0xFF2E7D32), size: 20),
                  )),
                ],
                if (deliveryPersons.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No delivery persons found', style: TextStyle(color: Colors.grey)),
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
              onPressed: (isSourceOrder 
                  ? (selectedVehicleId != null && selectedDeliveryPersonId != null)
                  : (selectedDeliveryPersonId != null))
                  ? () {
                      Navigator.pop(context);
                      if (isSourceOrder) {
                        _confirmBothAssignments(orderId, selectedVehicleId!, selectedVehicleType!, selectedDeliveryPersonId!);
                      } else {
                        _confirmDeliveryPersonOnly(orderId, selectedDeliveryPersonId!);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeliveryPersonOnly(int orderId, int deliveryPersonId) async {
    try {
      final personPayload = {
        'order_id': orderId,
        'delivery_person_id': deliveryPersonId,
      };
      print('\n========== DESTINATION TRANSPORTER ASSIGNMENT ==========');
      print('Delivery Person Assignment Payload: $personPayload');
      
      final personResponse = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/transporters/assign-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(personPayload),
      );

      print('Person Response Status: ${personResponse.statusCode}');
      print('Person Response Body: ${personResponse.body}');

      if (personResponse.statusCode == 200 || personResponse.statusCode == 201) {
        final personData = jsonDecode(personResponse.body);
        final assignedPerson = deliveryPersons.firstWhere(
            (p) => p['delivery_person_id'] == deliveryPersonId, orElse: () => {});
        
        print('Order ID: $orderId');
        print('--- Delivery Person Details ---');
        print('Delivery Person ID: $deliveryPersonId');
        print('Name: ${assignedPerson['name'] ?? 'N/A'}');
        print('Mobile: ${assignedPerson['mobile_number'] ?? 'N/A'}');
        print('Vehicle Type: ${assignedPerson['vehicle_type'] ?? 'N/A'}');
        print('Orders Assigned: ${personData['data']?['orders_assigned'] ?? 'N/A'}');
        print('Assignment Status: ${personData['data']?['status'] ?? 'N/A'}');
        
        // Update order status to IN_TRANSIT
        print('\n--- Updating Order Status to IN_TRANSIT ---');
        final statusResponse = await http.put(
          Uri.parse('https://farmercrate.onrender.com/api/orders/status'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode({'order_id': orderId, 'status': 'IN_TRANSIT'}),
        );
        
        print('Status Update Response: ${statusResponse.statusCode}');
        print('Status Update Body: ${statusResponse.body}');
        
        if (statusResponse.statusCode == 200) {
          print('✅ Order status updated to IN_TRANSIT');
          print('==========================================\n');
          _showSnackBar('Delivery person assigned and order status updated to IN_TRANSIT!');
        } else {
          print('⚠️ Failed to update order status');
          print('==========================================\n');
          _showSnackBar('Delivery person assigned successfully!');
        }
        
        _fetchAllocatedOrders();
        _fetchDeliveryPersons();
      } else {
        final errorData = jsonDecode(personResponse.body);
        _showSnackBar(errorData['message'] ?? 'Failed to assign delivery person', isError: true);
      }
    } catch (e) {
      print('Assignment Error: $e');
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _confirmBothAssignments(int orderId, int vehicleId, String vehicleType, int deliveryPersonId) async {
    try {
      final vehiclePayload = {
        'order_id': orderId,
        'vehicle_id': vehicleId,
        'vehicle_type': vehicleType,
      };
      print('Vehicle Assignment Payload: $vehiclePayload');
      
      // Assign vehicle first
      final vehicleResponse = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/transporters/assign-vehicle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(vehiclePayload),
      );

      print('Vehicle Response Status: ${vehicleResponse.statusCode}');
      print('Vehicle Response Body: ${vehicleResponse.body}');

      if (vehicleResponse.statusCode != 200 && vehicleResponse.statusCode != 201) {
        final errorData = jsonDecode(vehicleResponse.body);
        _showSnackBar(errorData['message'] ?? 'Failed to assign vehicle', isError: true);
        return;
      }

      // Then assign delivery person
      final personPayload = {
        'order_id': orderId,
        'delivery_person_id': deliveryPersonId,
      };
      print('Delivery Person Assignment Payload: $personPayload');
      
      final personResponse = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/transporters/assign-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(personPayload),
      );

      print('Person Response Status: ${personResponse.statusCode}');
      print('Person Response Body: ${personResponse.body}');

      if (personResponse.statusCode == 200 || personResponse.statusCode == 201) {
        // Parse responses to get details
        final vehicleData = jsonDecode(vehicleResponse.body);
        final personData = jsonDecode(personResponse.body);
        
        // Find vehicle details
        final assignedVehicle = vehicleType == 'permanent' 
            ? permanentVehicles.firstWhere((v) => v['vehicle_id'] == vehicleId, orElse: () => {})
            : temporaryVehicles.firstWhere((v) => v['vehicle_id'] == vehicleId, orElse: () => {});
        
        // Find delivery person details
        final assignedPerson = deliveryPersons.firstWhere(
            (p) => p['delivery_person_id'] == deliveryPersonId, orElse: () => {});
        
        print('\n========== SOURCE TRANSPORTER ASSIGNMENT SUCCESSFUL ==========');
        print('Order ID: $orderId');
        print('\n--- Vehicle Details ---');
        print('Vehicle ID: $vehicleId');
        print('Vehicle Type: $vehicleType');
        print('Vehicle Number: ${assignedVehicle['vehicle_number'] ?? 'N/A'}');
        print('Vehicle Model: ${assignedVehicle['vehicle_type'] ?? 'N/A'}');
        print('Capacity: ${assignedVehicle['capacity'] ?? 'N/A'} tons');
        print('Capacity Used: ${vehicleData['data']?['capacity_used'] ?? 'N/A'}');
        print('\n--- Delivery Person Details ---');
        print('Delivery Person ID: $deliveryPersonId');
        print('Name: ${assignedPerson['name'] ?? 'N/A'}');
        print('Mobile: ${assignedPerson['mobile_number'] ?? 'N/A'}');
        print('Vehicle Type: ${assignedPerson['vehicle_type'] ?? 'N/A'}');
        print('Orders Assigned: ${personData['data']?['orders_assigned'] ?? 'N/A'}');
        print('New Status: ${personData['data']?['status'] ?? 'N/A'}');
        print('==========================================\n');
        
        _showSnackBar('Vehicle and delivery person assigned successfully!');
        _fetchAllocatedOrders();
        _fetchDeliveryPersons();
      } else {
        final errorData = jsonDecode(personResponse.body);
        _showSnackBar(errorData['message'] ?? 'Failed to assign delivery person', isError: true);
      }
    } catch (e) {
      print('Assignment Error: $e');
      _showSnackBar('Error: $e', isError: true);
    }
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

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    Widget page;
    switch (index) {
      case 1:
        page = OrderStatusPage(token: widget.token);
        break;
      case 2:
        page = OrderHistoryPage(token: widget.token);
        break;
      case 3:
        page = VehiclePage(token: widget.token);
        break;
      case 4:
        page = ProfilePage(token: widget.token);
        break;
      default:
        return;
    }
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: Colors.red, size: 24),
            ),
            SizedBox(width: 12),
            Text('Logout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to logout?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: Icon(Icons.logout, size: 18),
            label: Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        title: Text('Transporter Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderStatusPage(token: widget.token)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchDeliveryPersons();
              _fetchAllocatedOrders();
              _fetchVehicles();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.local_shipping, size: 40, color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    Text('Transporter', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    SizedBox(height: 4),
                    Text('Dashboard', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
                  ],
                ),
              ),
              SizedBox(height: 8),
              _buildDrawerItem(Icons.dashboard, 'Dashboard', 0, _selectedIndex == 0, () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              }),
              _buildDrawerItem(Icons.track_changes, 'Order Tracking', 1, _selectedIndex == 1, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => OrderStatusPage(token: widget.token)));
              }),
              _buildDrawerItem(Icons.history, 'Order History', 2, _selectedIndex == 2, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryPage(token: widget.token)));
              }),
              _buildDrawerItem(Icons.local_shipping, 'Vehicles', 3, _selectedIndex == 3, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => VehiclePage(token: widget.token)));
              }),
              _buildDrawerItem(Icons.person, 'Profile', 4, _selectedIndex == 4, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(token: widget.token)));
              }),
              Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _logout();
                  },
                  icon: Icon(Icons.logout, size: 20),
                  label: Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDeliveryPersons();
          await _fetchAllocatedOrders();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Delivery Persons', deliveryPersons.length.toString(), Icons.people),
                        _buildStatCard('Source Orders', sourceOrders.length.toString(), Icons.upload),
                        _buildStatCard('Destination Orders', destinationOrders.length.toString(), Icons.download),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF2E7D32).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.delivery_dining, color: Color(0xFF2E7D32), size: 20),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delivery Persons',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddDeliveryAgentScreen(token: widget.token)),
                            ).then((_) => _fetchDeliveryPersons());
                          },
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    isLoadingPersons
                        ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                        : deliveryPersons.isEmpty
                            ? _buildEmptyState('No delivery persons found', Icons.person_off)
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: deliveryPersons.length,
                                itemBuilder: (context, index) {
                                  final person = deliveryPersons[index];
                                  return _buildDeliveryPersonCard(person);
                                },
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
                          child: Icon(Icons.upload, color: Color(0xFF2E7D32), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Source Orders (Pickup)',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    isLoadingOrders
                        ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                        : sourceOrders.isEmpty
                            ? _buildEmptyState('No source orders', Icons.inbox)
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: sourceOrders.length,
                                itemBuilder: (context, index) {
                                  final order = sourceOrders[index];
                                  return _buildOrderCard(order, 'source');
                                },
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
                          child: Icon(Icons.download, color: Color(0xFF2E7D32), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Destination Orders (Delivery)',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    isLoadingOrders
                        ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                        : destinationOrders.isEmpty
                            ? _buildEmptyState('No destination orders', Icons.inbox)
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: destinationOrders.length,
                                itemBuilder: (context, index) {
                                  final order = destinationOrders[index];
                                  return _buildOrderCard(order, 'destination');
                                },
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          selectedItemColor: Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 13,
          unselectedFontSize: 12,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.dashboard, size: 24),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.track_changes, size: 24),
              ),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history, size: 24),
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 3 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, size: 24),
              ),
              label: 'Vehicles',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 4 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, size: 24),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPersonCard(dynamic person) {
    final isAvailable = person['is_available'] ?? false;
    final imageUrl = person['image_url'];
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF2E7D32), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
                        ),
                        child: Icon(Icons.person, color: Colors.white, size: 28),
                      );
                    })
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person['name'] ?? 'N/A',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      person['mobile_number'] ?? 'N/A',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.two_wheeler, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      person['vehicle_type'] ?? 'N/A',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.local_shipping, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      '${person['total_deliveries'] ?? 0} deliveries',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
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
              isAvailable ? 'Available' : 'Busy',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, String type) {
    final product = order['product'];
    final images = product?['images'] as List?;
    dynamic primaryImage;
    if (images != null && images.isNotEmpty) {
      try {
        primaryImage = images.firstWhere((img) => img['is_primary'] == true);
      } catch (e) {
        primaryImage = images.first;
      }
    }
    final imageUrl = primaryImage?['image_url'];
    final productName = product?['name'];
    final isSource = type == 'source';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Color(0xFF2E7D32).withOpacity(0.1),
                                child: Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 24),
                              );
                            })
                          : Container(
                              color: Color(0xFF2E7D32).withOpacity(0.1),
                              child: Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 24),
                            ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    productName ?? 'N/A',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSource ? Color(0xFF2196F3) : Color(0xFF9C27B0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isSource ? 'PICKUP' : 'DELIVERY',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFA726),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order['current_status'] ?? 'PLACED',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  order['delivery_address'] ?? 'N/A',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                  Text(
                    '${order['total_price'] ?? 0}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Qty: ${order['quantity'] ?? 0}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _assignVehicle(order['order_id'], type),
                icon: Icon(Icons.local_shipping, size: 16),
                label: Text('Assign', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Color(0xFF2E7D32).withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2E7D32) : Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : Color(0xFF2E7D32), size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Color(0xFF2E7D32) : Colors.grey[800],
          ),
        ),
        trailing: isSelected ? Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2E7D32)) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
