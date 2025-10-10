import 'package:flutter/material.dart';
import 'navigation_utils.dart';
import 'payment.dart';
import '../utils/order_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'findtrans.dart';


class OrderConfirmPage extends StatefulWidget {
  final List cartItems;
  final String? token;

  const OrderConfirmPage({Key? key, required this.cartItems, this.token}) : super(key: key);

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  late TextEditingController _addressController;
  String _selectedAddress = '';
  bool _addingNewAddress = false;

  late TextEditingController _phoneController;
  String _selectedPhone = '';
  bool _editingPhone = false;
  bool _isLoading = true;

  // User profile data
  String _userName = '';
  String _userEmail = '';
  String _userZone = '';
  String _userState = '';
  String _userDistrict = '';

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _fetchUserProfile();
  }


  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (widget.token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/customers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final customer = data['data'];

        setState(() {
          _userName = customer['customer_name'] ?? customer['name'] ?? '';
          _userEmail = customer['email'] ?? '';
          _selectedPhone = customer['mobile_number'] ?? '';
          _selectedAddress = customer['address'] ?? '';
          _userZone = customer['zone'] ?? '';
          _userState = customer['state'] ?? '';
          _userDistrict = customer['district'] ?? '';

          _phoneController.text = _selectedPhone;
          _addressController.text = _selectedAddress;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get subtotal => widget.cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get gst => subtotal * 0.05;
  double get total => subtotal + gst;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        title: const Text('Order Confirmation', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green[600]),
            SizedBox(height: 16),
            Text('Loading your profile...', style: TextStyle(color: Colors.green[700])),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile information
            if (_userName.isNotEmpty) ...[
              Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[800])),
                      SizedBox(height: 8),
                      Text('Name: $_userName', style: TextStyle(fontSize: 14)),
                      Text('Email: $_userEmail', style: TextStyle(fontSize: 14)),
                      if (_userZone.isNotEmpty) Text('Zone: $_userZone', style: TextStyle(fontSize: 14)),
                      if (_userState.isNotEmpty) Text('State: $_userState', style: TextStyle(fontSize: 14)),
                      if (_userDistrict.isNotEmpty) Text('District: $_userDistrict', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
            // Default address and phone
            Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[800])),
                    Text(_selectedAddress.isNotEmpty ? _selectedAddress : 'No address found', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[800])),
                    Text(_selectedPhone.isNotEmpty ? _selectedPhone : 'No phone number found', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Button to add new address and phone
            if (!_addingNewAddress) ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _addingNewAddress = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('New Address'),
                ),
              ),
            ] else ...[
              Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Enter new address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Enter phone number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedAddress = _addressController.text;
                                _selectedPhone = _phoneController.text;
                                _addingNewAddress = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Save'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _addingNewAddress = false;
                                _fetchUserProfile();
                              });
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800])),
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: item['images'] != null && item['images'].toString().isNotEmpty
                          ? Image.network(item['images'].toString().split(',')[0], width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.image, size: 40, color: Colors.green[200]),
                      title: Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Qty: ${item['quantity']}  |  ₹${item['price']}'),
                      trailing: Text('₹${(item['price'] * item['quantity']).toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('GST Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800])),
            Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _invoiceRow('Subtotal', subtotal),
                    _invoiceRow('GST (5%)', gst),
                    Divider(),
                    _invoiceRow('Total', total, isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _createOrder,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Proceed to Payment - ₹${total.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: CustomerNavigationUtils.buildCustomerDrawer(
        parentContext: context,
        token: widget.token,
      ),
      bottomNavigationBar: CustomerNavigationUtils.buildCustomerBottomNav(
        currentIndex: 2, // Cart tab is most relevant for order confirmation
        onTap: (index) => CustomerNavigationUtils.handleNavigation(index, context, widget.token),
      ),
    );
  }

  Widget _invoiceRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
          Text('₹${value.toStringAsFixed(2)}', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isTotal ? Colors.green[700] : Colors.black)),
        ],
      ),
    );
  }

  Future<void> _createOrder() async {
    if (_selectedAddress.isEmpty || _selectedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide address and phone number')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Creating order...'),
          ],
        ),
      ),
    );

    try {
      // Use zone from user profile, fallback to extraction if not available
      final zone = _userZone.isNotEmpty ? _userZone : _extractZone(_selectedAddress);
      final pincode = _extractPincode(_selectedAddress);

      final orderData = {
        'product_id': widget.cartItems.first['product_id'] ?? widget.cartItems.first['id'],
        'quantity': widget.cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int)),
        'delivery_address': _selectedAddress,
        'customer_zone': zone,
        'customer_pincode': pincode,
        'total_price': total,
        'farmer_amount': total * 0.9,
        'admin_commission': total * 0.1,
        'transport_charge': 30.0,
        'qr_code': 'QR${DateTime.now().millisecondsSinceEpoch}',
      };

      final result = await OrderService.createOrder(orderData);

      Navigator.pop(context);

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully! QR code generated.'),
            backgroundColor: Colors.green[600],
          ),
        );

        // Navigate to delivery tracking
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryTrackingPage(
              orderId: result['data']['order_id']?.toString() ?? 'ORD${DateTime.now().millisecondsSinceEpoch}',
              customerName: _userName,
              customerAddress: _selectedAddress,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order. Please try again.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: $e')),
      );
    }
  }

  String _extractPincode(String address) {
    final regex = RegExp(r'\b\d{6}\b');
    final match = regex.firstMatch(address);
    return match?.group(0) ?? '';
  }

  String _extractZone(String address) {
    final addressLower = address.toLowerCase();
    final parts = addressLower.split(',');
    for (String part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty && !RegExp(r'^\d+').hasMatch(trimmed)) {
        return trimmed;
      }
    }
    return 'unknown';
  }
}