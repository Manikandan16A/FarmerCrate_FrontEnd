import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'order_detail_page.dart';

class QRScanPage extends StatefulWidget {
  final String? token;

  const QRScanPage({super.key, this.token});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  late MobileScannerController cameraController;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String qrData) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    print('=== QR Code Scanned ===');
    print('Raw QR Data: $qrData');

    try {
      final orderIdMatch = RegExp(r'order_id:\s*(\d+)').firstMatch(qrData);
      if (orderIdMatch == null) {
        _showSnackBar('Invalid QR code format', isError: true);
        setState(() => isProcessing = false);
        return;
      }
      
      final orderId = int.parse(orderIdMatch.group(1)!);
      print('Order ID: $orderId');

      final allocatedResponse = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/orders/transporter/allocated'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('Response Status: ${allocatedResponse.statusCode}');
      print('Response Body: ${allocatedResponse.body}');

      if (allocatedResponse.statusCode == 200) {
        final data = jsonDecode(allocatedResponse.body);
        final allOrders = data['data'] as List;
        print('Total Orders: ${allOrders.length}');
        
        final order = allOrders.firstWhere(
          (o) => o['order_id'] == orderId,
          orElse: () => null,
        );

        if (order == null) {
          _showSnackBar('Order #$orderId not found in your allocated orders', isError: true);
          setState(() => isProcessing = false);
          return;
        }

        print('Order Data: $order');
        final transporterRole = order['transporter_role'];
        final currentStatus = order['current_status'];
        print('\n========== QR SCANNER STATUS CHECK ==========');
        print('Transporter Role: $transporterRole');
        print('Current Status: $currentStatus');

        // Check status based on transporter role
        if (transporterRole == 'PICKUP_SHIPPING') {
          print('--- Source Transporter (PICKUP_SHIPPING) ---');
          print('Allowed Status: ASSIGNED');
          print('Current Status: $currentStatus');
          // Source transporter: only ASSIGNED status allowed
          if (currentStatus != 'ASSIGNED') {
            print('❌ Status Check Failed: Current status "$currentStatus" is not ASSIGNED');
            print('==========================================\n');
            _showSnackBar('Cannot scan QR! Order status must be ASSIGNED. Current status: $currentStatus', isError: true);
            setState(() => isProcessing = false);
            return;
          }
          print('✅ Status Check Passed: Order is ASSIGNED');
          print('Next Status: SHIPPED');
        } else if (transporterRole == 'DELIVERY') {
          print('--- Destination Transporter (DELIVERY) ---');
          print('Allowed Status: SHIPPED');
          print('Current Status: $currentStatus');
          // Destination transporter: only SHIPPED allowed for scanning
          if (currentStatus != 'SHIPPED') {
            print('❌ Status Check Failed: Current status "$currentStatus" is not SHIPPED');
            print('==========================================\n');
            _showSnackBar('Cannot scan QR! Order status must be SHIPPED. Current status: $currentStatus', isError: true);
            setState(() => isProcessing = false);
            return;
          }
          print('✅ Status Check Passed: Order status is SHIPPED');
          print('Next Status: IN_TRANSIT');
        }
        print('==========================================\n');

        setState(() => isProcessing = false);
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(
                order: order,
                token: widget.token,
                transporterRole: transporterRole,
              ),
            ),
          );
        }
      } else {
        final errorData = jsonDecode(allocatedResponse.body);
        _showSnackBar(errorData['message'] ?? 'Failed to fetch orders', isError: true);
        setState(() => isProcessing = false);
      }
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      _showSnackBar('Invalid QR code: $e', isError: true);
      setState(() => isProcessing = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Scan QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !isProcessing) {
                final qrData = barcodes.first.rawValue;
                if (qrData != null) {
                  _processQRCode(qrData);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF4CAF50), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Align QR code within frame',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
