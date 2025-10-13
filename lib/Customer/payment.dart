import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'findtrans.dart';
import '../utils/qr_generator.dart';
import 'customerhomepage.dart';

class FarmerCratePaymentPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String token;

  const FarmerCratePaymentPage({
    Key? key,
    required this.orderData,
    required this.token,
  }) : super(key: key);

  @override
  _FarmerCratePaymentPageState createState() => _FarmerCratePaymentPageState();
}

class _FarmerCratePaymentPageState extends State<FarmerCratePaymentPage> {
  late Razorpay _razorpay;
  bool showOrderDetails = false;
  bool isCreatingOrder = false;
  bool isProcessingPayment = false;
  Map<String, dynamic>? paymentDetails;
  Map<String, dynamic>? orderData;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _zoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _zoneController.dispose();
    _pincodeController.dispose();
    _razorpay.clear(); // Clear razorpay listeners
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('Current location: ${position.latitude}, ${position.longitude}');

      // Call API with actual coordinates
      final response = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/orders/current-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lat': position.latitude, 'lng': position.longitude}),
      );

      print('Location API Status: ${response.statusCode}');
      print('Location API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');
        
        final locationData = data['data'] ?? data;
        String fullAddress = locationData['address']?.toString() ?? '';
        
        // Parse address to extract zone and pincode
        // Example: "4RXJ+9H7, K.R.Nagar, Kovilpatti, Nallatinputhur, Tamil Nadu 628503, India"
        String zone = '';
        String pincode = '';
        
        // Extract pincode (6 digits)
        RegExp pincodeRegex = RegExp(r'\b(\d{6})\b');
        Match? pincodeMatch = pincodeRegex.firstMatch(fullAddress);
        if (pincodeMatch != null) {
          pincode = pincodeMatch.group(1) ?? '';
        }
        
        // Extract zone (city name before state)
        List<String> parts = fullAddress.split(',').map((e) => e.trim()).toList();
        if (parts.length >= 3) {
          // Try to find the main city/town (usually before state name)
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].contains('Tamil Nadu') || parts[i].contains('India')) {
              if (i > 0) {
                zone = parts[i - 1];
              }
              break;
            }
          }
          // If no zone found, use the second or third part
          if (zone.isEmpty && parts.length >= 2) {
            zone = parts[1];
          }
        }
        
        setState(() {
          _addressController.text = fullAddress;
          _zoneController.text = zone;
          _pincodeController.text = pincode;
        });
        
        print('Address: ${_addressController.text}');
        print('Zone: ${_zoneController.text}');
        print('Pincode: ${_pincodeController.text}');
        
        _showSuccessSnackBar('Location details filled successfully!');
      } else {
        _showErrorSnackBar('Failed to get location details');
      }
    } catch (e) {
      print('Location error: $e');
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Future<void> _createOrder() async {
    // Validate required fields
    if (_addressController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _zoneController.text.isEmpty ||
        _pincodeController.text.isEmpty) {
      _showWarningSnackBar('Please fill all required fields');
      return;
    }

    // Validate phone number format
    if (!RegExp(r'^[0-9]{10}$').hasMatch(_phoneController.text)) {
      _showWarningSnackBar('Please enter a valid 10-digit phone number');
      return;
    }

    setState(() {
      isCreatingOrder = true;
    });

    try {
      final userAddress = _addressController.text;
      final userZone = _zoneController.text;
      final userPincode = _pincodeController.text;

      // Calculate amounts safely
      final totalPrice = widget.orderData['total_price'] ?? 0.0;
      final quantity = widget.orderData['quantity'] ?? 1;
      final unitPrice = widget.orderData['unit_price'] ?? totalPrice / quantity;

      // Calculate charges
      final basePrice = unitPrice * quantity;
      final adminCommission = basePrice * 0.03; // 3% of product price
      final deliveryCharge = basePrice * 0.10; // 10% of product price
      final calculatedTotal = basePrice + adminCommission + deliveryCharge;
      final farmerAmount = basePrice - adminCommission;

      final orderPayload = {
        'product_id': widget.orderData['product_id'],
        'quantity': quantity,
        'delivery_address': userAddress,
        'customer_zone': userZone,
        'customer_pincode': userPincode,
        'total_price': calculatedTotal,
        'farmer_amount': farmerAmount,
        'admin_commission': adminCommission,
        'transport_charge': deliveryCharge,
      };

      print('Order payload: ${jsonEncode(orderPayload)}');

      final response = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(orderPayload),
      ).timeout(Duration(seconds: 30));

      print('Order creation response status: ${response.statusCode}');
      print('Order creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          paymentDetails = data['payment_details'];
          orderData = data['order_data'];
          isCreatingOrder = false;
        });
        _openRazorpayCheckout();
      } else {
        setState(() {
          isCreatingOrder = false;
        });
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to create order';
        _showErrorSnackBar('Error: $errorMessage (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        isCreatingOrder = false;
      });
      _showErrorSnackBar('Error creating order: $e');
    }
  }

  void _openRazorpayCheckout() {
    if (paymentDetails == null) {
      _showErrorSnackBar('Payment details not available');
      return;
    }

    // Convert amount to integer (Razorpay expects amount in paise)
    final amount = (double.parse(paymentDetails!['amount'].toString()) * 100).toInt();

    var options = {
      'key': paymentDetails!['key_id'],
      'amount': amount.toString(),
      'currency': paymentDetails!['currency'] ?? 'INR',
      'order_id': paymentDetails!['razorpay_order_id'],
      'name': 'Farmer Crate',
      'description': widget.orderData['product_name'] ?? 'Fresh Organic Products',
      'prefill': {
        'contact': _phoneController.text,
        'email': 'customer@farmercrate.com', // Add email if available
      },
      'theme': {
        'color': '#2E7D32'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showErrorSnackBar('Failed to open payment gateway: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment success: ${response.paymentId}');

    // Prevent duplicate processing
    if (isProcessingPayment) {
      print('Already processing payment, ignoring duplicate call');
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      final completePayload = {
        'razorpay_order_id': paymentDetails!['razorpay_order_id'],
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'order_data': orderData,
      };

      print('Completing payment with payload: ${jsonEncode(completePayload)}');

      final completeResponse = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/orders/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(completePayload),
      ).timeout(Duration(seconds: 30));

      print('Payment completion response status: ${completeResponse.statusCode}');
      print('Payment completion response body: ${completeResponse.body}');

      if (completeResponse.statusCode == 200 || completeResponse.statusCode == 201) {
        final data = jsonDecode(completeResponse.body);

        if (data['success'] == true) {
          final orderId = data['data']['order_id'];

          // Generate and update QR code after order is created
          final qrData = {
            'order_id': orderId,
            'quantity': orderData?['quantity'],
            'total': orderData?['total_price'],
            'address': orderData?['delivery_address'],
            'zone': orderData?['customer_zone'],
            'pincode': orderData?['customer_pincode'],
          };
          final qrImageUrl = await QRGenerator.generateOrderQR(qrData);

          if (qrImageUrl != null && qrImageUrl.isNotEmpty) {
            print('Updating order $orderId with QR: $qrImageUrl');
            final qrUpdateResponse = await http.put(
              Uri.parse('https://farmercrate.onrender.com/api/orders/$orderId/qr-code'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${widget.token}',
              },
              body: jsonEncode({'qr_code': qrImageUrl}),
            );
            print('QR update status: ${qrUpdateResponse.statusCode}');
            print('QR update response: ${qrUpdateResponse.body}');
          } else {
            print('QR generation failed, skipping update');
          }

          if (mounted) {
            setState(() {
              isProcessingPayment = false;
            });

            // Show enhanced success dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.white, Color(0xFFF0F8F0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Payment Successful!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your order is placed successfully!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Waiting for farmer verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => CustomerHomePage(token: widget.token),
                              ),
                                  (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E7D32),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Go to Home',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Payment completion failed');
        }
      } else {
        final errorData = jsonDecode(completeResponse.body);
        throw Exception(errorData['message'] ?? 'Payment completion failed with status ${completeResponse.statusCode}');
      }
    } catch (e) {
      print('Payment completion error: $e');
      if (mounted) {
        setState(() {
          isProcessingPayment = false;
        });
        _showErrorSnackBar('Error completing payment: $e');
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment error: ${response.code} - ${response.message}');
    _showErrorSnackBar('Payment Failed: ${response.message ?? "Unknown error"}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showInfoSnackBar('External Wallet: ${response.walletName}');
  }

  void _showSuccessSnackBar(String message) {
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
              child: Icon(Icons.check_circle, color: Colors.white, size: 24),
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
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
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
              child: Icon(Icons.error, color: Colors.white, size: 24),
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
        backgroundColor: Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
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
              child: Icon(Icons.warning, color: Colors.white, size: 24),
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
        backgroundColor: Color(0xFFFFA726),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
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
              child: Icon(Icons.info, color: Colors.white, size: 24),
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
        backgroundColor: Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: Duration(seconds: 3),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        title: Text('Payment'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Order Summary Header
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.orderData['product_name'] ?? 'Product',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showOrderDetails = !showOrderDetails;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            Row(
                              children: [
                                Text(
                                  '₹${_calculateTotal().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  showOrderDetails ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (showOrderDetails) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _buildOrderDetailRow(
                                  'Base Price (${widget.orderData['quantity'] ?? 1} items)',
                                  '₹${_calculateBasePrice().toStringAsFixed(2)}'
                              ),
                              _buildOrderDetailRow(
                                  'Admin Commission (3%)',
                                  '₹${_calculateAdminCommission().toStringAsFixed(2)}'
                              ),
                              _buildOrderDetailRow(
                                  'Delivery Charges (10%)',
                                  '₹${_calculateDeliveryCharge().toStringAsFixed(2)}'
                              ),
                              Divider(color: Colors.white70),
                              _buildOrderDetailRow(
                                  'Total Amount',
                                  '₹${_calculateTotal().toStringAsFixed(2)}',
                                  isTotal: true
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Customer Details Form
                Padding(
                  padding: EdgeInsets.all(20),
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
                          Text(
                            'Delivery Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: isLoadingLocation ? null : _getCurrentLocation,
                          icon: isLoadingLocation
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(Icons.my_location, color: Colors.white, size: 22),
                          label: Text(
                            isLoadingLocation ? 'Getting Location...' : 'Use Current Location',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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
                            TextField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Delivery Address *',
                                hintText: 'Enter your full delivery address',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                prefixIcon: Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              maxLines: 2,
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _zoneController,
                                    decoration: InputDecoration(
                                      labelText: 'Zone *',
                                      hintText: 'City/Town',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                                      ),
                                      prefixIcon: Icon(Icons.map, color: Color(0xFF2E7D32)),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _pincodeController,
                                    decoration: InputDecoration(
                                      labelText: 'Pincode *',
                                      hintText: '6 digits',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                                      ),
                                      prefixIcon: Icon(Icons.pin_drop, color: Color(0xFF2E7D32)),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      counterText: '',
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number *',
                                hintText: '10 digit mobile number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                prefixIcon: Icon(Icons.phone, color: Color(0xFF2E7D32)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                counterText: '',
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
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
                            child: Icon(Icons.payment, color: Color(0xFF2E7D32), size: 20),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Payment Methods',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Razorpay Payment Options
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
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
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.payment,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Razorpay Secure Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Pay securely using:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPaymentMethodChip('UPI', Icons.account_balance_wallet),
                                _buildPaymentMethodChip('Cards', Icons.credit_card),
                                _buildPaymentMethodChip('Net Banking', Icons.account_balance),
                                _buildPaymentMethodChip('Wallets', Icons.wallet),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFE8F5E8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.security, color: Color(0xFF2E7D32), size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '256-bit SSL encrypted. Your payment information is safe.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Trust Indicators
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTrustIndicator(
                                  Icons.security,
                                  'SSL Encrypted',
                                  Color(0xFF4CAF50),
                                ),
                                _buildTrustIndicator(
                                  Icons.verified,
                                  'PCI Compliant',
                                  Color(0xFF4CAF50),
                                ),
                                _buildTrustIndicator(
                                  Icons.support_agent,
                                  '24/7 Support',
                                  Color(0xFF4CAF50),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Powered by Razorpay - India\'s most trusted payment gateway',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Processing Payment Overlay
          if (isProcessingPayment)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF2E7D32)),
                      SizedBox(height: 16),
                      Text(
                        'Processing Payment...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait while we complete your order',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
            onPressed: isCreatingOrder ? null : _createOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isCreatingOrder
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Pay ₹${_calculateTotal().toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Color(0xFF2E7D32)),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustIndicator(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _calculateBasePrice() {
    final quantity = widget.orderData['quantity'] ?? 1;
    final unitPrice = widget.orderData['unit_price'] ?? 0.0;
    return unitPrice * quantity;
  }

  double _calculateAdminCommission() {
    return _calculateBasePrice() * 0.03; // 3% of base price
  }

  double _calculateDeliveryCharge() {
    return _calculateBasePrice() * 0.10; // 10% of base price
  }

  double _calculateTotal() {
    return _calculateBasePrice() + _calculateAdminCommission() + _calculateDeliveryCharge();
  }
}