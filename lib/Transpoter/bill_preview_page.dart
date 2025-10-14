import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart' as barcode;
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import '../utils/cloudinary_upload.dart';

class BillPreviewPage extends StatefulWidget {
  final dynamic order;
  final String? token;

  const BillPreviewPage({super.key, required this.order, this.token});

  @override
  State<BillPreviewPage> createState() => _BillPreviewPageState();
}

class _BillPreviewPageState extends State<BillPreviewPage> {
  final GlobalKey _billKey = GlobalKey();
  bool _billGenerated = false;
  bool _isProcessing = false;
  bool _billAlreadyExists = false;

  @override
  void initState() {
    super.initState();
    _checkIfBillExists();
  }

  void _checkIfBillExists() {
    final billUrl = widget.order['bill_url'];
    if (billUrl != null && billUrl.toString().isNotEmpty) {
      setState(() {
        _billAlreadyExists = true;
        _billGenerated = true;
      });
    }
  }

  void _generateBill() {
    print('\n=== GENERATE BILL CLICKED ===');
    
    final product = widget.order['product'];
    final customer = widget.order['customer'];
    final orderDate = widget.order['order_date'] != null ? DateTime.parse(widget.order['order_date']) : DateTime.now();
    final invoiceDate = DateTime.now();
    final priceValue = widget.order['total_price'];
    final price = priceValue is String ? double.tryParse(priceValue) ?? 0.0 : (priceValue ?? 0).toDouble();
    final quantity = widget.order['quantity'] ?? 1;
    final deliveryChargeValue = widget.order['transport_charge'];
    final deliveryCharge = deliveryChargeValue is String ? double.tryParse(deliveryChargeValue) ?? 0.0 : (deliveryChargeValue ?? 0).toDouble();
    final adminCommissionValue = widget.order['admin_commission'];
    final adminCommission = adminCommissionValue is String ? double.tryParse(adminCommissionValue) ?? 0.0 : (adminCommissionValue ?? 0).toDouble();
    final totalWithTax = price + deliveryCharge + adminCommission;

    print('=== BILL DETAILS ===');
    print('Order ID: ${widget.order['order_id']}');
    print('Tax Invoice #: FC-${widget.order['order_id']}-${invoiceDate.year}');
    print('Order Date: ${DateFormat('dd-MM-yyyy').format(orderDate)}');
    print('Invoice Date: ${DateFormat('dd-MM-yyyy').format(invoiceDate)}');
    print('---');
    print('Customer Name: ${customer?['name']}');
    print('Phone: ${customer?['mobile_number']}');
    print('Billing Address: ${widget.order['delivery_address']}');
    print('Shipping Address: ${widget.order['delivery_address']}');
    print('---');
    print('Product: ${product?['name']}');
    print('Quantity: $quantity');
    print('Price: ₹$price');
    print('Delivery Charge: ₹$deliveryCharge');
    print('Platform Charge: ₹$adminCommission');
    print('---');
    print('Total Qty: $quantity');
    print('Price (₹): ${price.toStringAsFixed(2)}');
    print('Delivery Charge (₹): ${deliveryCharge.toStringAsFixed(2)}');
    print('Platform Charge (₹): ${adminCommission.toStringAsFixed(2)}');
    print('Grand Total: ₹${totalWithTax.toStringAsFixed(2)}');
    print('===================');
    print('[SUCCESS] Bill generated! Showing action buttons.');
    print('=== GENERATE BILL COMPLETED ===\n');

    setState(() => _billGenerated = true);
  }

  Future<pw.Document> _createPdf() async {
    final product = widget.order['product'];
    final customer = widget.order['customer'];
    final orderDate = widget.order['order_date'] != null ? DateTime.parse(widget.order['order_date']) : DateTime.now();
    final invoiceDate = DateTime.now();
    final priceValue = widget.order['total_price'];
    final price = priceValue is String ? double.tryParse(priceValue) ?? 0.0 : (priceValue ?? 0).toDouble();
    final quantity = widget.order['quantity'] ?? 1;
    final deliveryChargeValue = widget.order['transport_charge'];
    final deliveryCharge = deliveryChargeValue is String ? double.tryParse(deliveryChargeValue) ?? 0.0 : (deliveryChargeValue ?? 0).toDouble();
    final adminCommissionValue = widget.order['admin_commission'];
    final adminCommission = adminCommissionValue is String ? double.tryParse(adminCommissionValue) ?? 0.0 : (adminCommissionValue ?? 0).toDouble();
    final totalWithTax = price + deliveryCharge + adminCommission;

    final greenColor = PdfColor.fromHex('#2E7D32');
    final lightGreen = PdfColor.fromHex('#E8F5E9');
    final greyColor = PdfColor.fromHex('#757575');

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            padding: pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text('FarmerCrate', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: greenColor))),
                pw.SizedBox(height: 8),
                pw.Center(child: pw.Text('Contact us: +91 9551084651 || farmercrate@gmail.com', style: pw.TextStyle(fontSize: 12, color: greyColor))),
                pw.SizedBox(height: 8),
                pw.Center(child: pw.Text('FarmerCrate Retail Private Limited', style: pw.TextStyle(fontSize: 11, color: greyColor))),
                pw.Divider(height: 32, thickness: 2),
                pw.Text('Tax Invoice #: FC-${widget.order['order_id']}-${invoiceDate.year}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Text('Order Date: ${DateFormat('dd-MM-yyyy').format(orderDate)}', style: pw.TextStyle(fontSize: 12)),
                pw.Text('Invoice Date: ${DateFormat('dd-MM-yyyy').format(invoiceDate)}', style: pw.TextStyle(fontSize: 12)),
                pw.Divider(height: 32),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Billing Address', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: greenColor)),
                          pw.SizedBox(height: 8),
                          pw.Text(customer?['name'] ?? 'N/A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text(widget.order['delivery_address'] ?? 'N/A', style: pw.TextStyle(fontSize: 11, color: greyColor)),
                          pw.Text('Phone: ${customer?['mobile_number'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 11, color: greyColor)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Shipping Address', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: greenColor)),
                          pw.SizedBox(height: 8),
                          pw.Text(customer?['name'] ?? 'N/A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text(widget.order['delivery_address'] ?? 'N/A', style: pw.TextStyle(fontSize: 11, color: greyColor)),
                          pw.Text('Phone: ${customer?['mobile_number'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 11, color: greyColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 32),
                pw.Text('Product Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: greenColor)),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1.5),
                    3: pw.FlexColumnWidth(1.5),
                    4: pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: lightGreen),
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Product', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: greenColor))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: greenColor))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Price (Rs.)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: greenColor))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Delivery (Rs.)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: greenColor))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Platform (Rs.)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: greenColor))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(product?['name'] ?? 'N/A', style: pw.TextStyle(fontSize: 11))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('$quantity', style: pw.TextStyle(fontSize: 11))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(price.toStringAsFixed(2), style: pw.TextStyle(fontSize: 11))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(deliveryCharge.toStringAsFixed(2), style: pw.TextStyle(fontSize: 11))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(adminCommission.toStringAsFixed(2), style: pw.TextStyle(fontSize: 11))),
                      ],
                    ),
                  ],
                ),
                pw.Divider(height: 32),
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: lightGreen,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Qty:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)), pw.Text('$quantity', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))]),
                      pw.SizedBox(height: 4),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Price (Rs.):', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)), pw.Text(price.toStringAsFixed(2), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))]),
                      pw.SizedBox(height: 4),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Delivery Charge (Rs.):', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)), pw.Text(deliveryCharge.toStringAsFixed(2), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))]),
                      pw.SizedBox(height: 4),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Platform Charge (Rs.):', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)), pw.Text(adminCommission.toStringAsFixed(2), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))]),
                      pw.Divider(height: 16),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: greenColor)), pw.Text('Rs. ${totalWithTax.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: greenColor))]),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: barcode.Barcode.qrCode(),
                    data: '${widget.order['order_id']}',
                    width: 120,
                    height: 120,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(child: pw.Text('Keep this invoice for warranty purposes.', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: greyColor))),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  Future<void> _printBill() async {
    setState(() => _isProcessing = true);
    try {
      final boundary = _billKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/bill_${widget.order['order_id']}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      final billUrl = await CloudinaryUploader.uploadImage(file);
      
      if (billUrl != null) {
        await _saveBillUrlToDatabase(billUrl);
        
        final imageBytes = await file.readAsBytes();
        final img = pw.MemoryImage(imageBytes);
        
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(img, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
        
        await file.delete();
        
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
        _showSuccessSnackBar('Bill saved to database and printed successfully!');
      } else {
        _showErrorSnackBar('Failed to save bill to database');
      }
    } catch (e) {
      _showErrorSnackBar('Print failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isProcessing = true);
    try {
      final pdf = await _createPdf();
      final pdfBytes = await pdf.save();
      final filePath = '/storage/emulated/0/Download/Bill_FC-${widget.order['order_id']}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      print('[DOWNLOAD] PDF saved to: $filePath');
      _showSuccessSnackBar('PDF downloaded to Downloads folder!');
    } catch (e) {
      print('[DOWNLOAD ERROR] $e');
      _showErrorSnackBar('Download failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _uploadToCloudinary() async {
    setState(() => _isProcessing = true);
    try {
      final boundary = _billKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/bill_${widget.order['order_id']}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      final billUrl = await CloudinaryUploader.uploadImage(file);
      
      if (billUrl != null) {
        await _saveBillUrlToDatabase(billUrl);
        await file.delete();
      } else {
        _showErrorSnackBar('Upload failed');
      }
    } catch (e) {
      _showErrorSnackBar('Upload failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveBillUrlToDatabase(String billUrl) async {
    final response = await http.put(
      Uri.parse('https://farmercrate.onrender.com/api/orders/${widget.order['order_id']}/bill'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'bill_url': billUrl}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _showSuccessSnackBar('Bill URL saved!');
    } else {
      _showErrorSnackBar('Failed to save URL');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFF4CAF50)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFFE53935)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.order['product'];
    final customer = widget.order['customer'];
    final orderDate = widget.order['order_date'] != null ? DateTime.parse(widget.order['order_date']) : DateTime.now();
    final invoiceDate = DateTime.now();
    final priceValue = widget.order['total_price'];
    final price = priceValue is String ? double.tryParse(priceValue) ?? 0.0 : (priceValue ?? 0).toDouble();
    final quantity = widget.order['quantity'] ?? 1;
    final deliveryChargeValue = widget.order['transport_charge'];
    final deliveryCharge = deliveryChargeValue is String ? double.tryParse(deliveryChargeValue) ?? 0.0 : (deliveryChargeValue ?? 0).toDouble();
    final adminCommissionValue = widget.order['admin_commission'];
    final adminCommission = adminCommissionValue is String ? double.tryParse(adminCommissionValue) ?? 0.0 : (adminCommissionValue ?? 0).toDouble();
    final totalWithTax = price + deliveryCharge + adminCommission;

    return Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        title: Text('Bill Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            RepaintBoundary(
              key: _billKey,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('FarmerCrate', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                    SizedBox(height: 8),
                    Center(child: Text('Contact us: +91 9551084651 || farmercrate@gmail.com', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                    SizedBox(height: 8),
                    Center(child: Text('FarmerCrate Retail Private Limited', style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
                    Divider(height: 32, thickness: 2),
                    Text('Tax Invoice #: FC-${widget.order['order_id']}-${invoiceDate.year}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Text('Order Date: ${DateFormat('dd-MM-yyyy').format(orderDate)}', style: TextStyle(fontSize: 12)),
                    Text('Invoice Date: ${DateFormat('dd-MM-yyyy').format(invoiceDate)}', style: TextStyle(fontSize: 12)),
                    Divider(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Billing Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                              SizedBox(height: 8),
                              Text(customer?['name'] ?? 'N/A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(widget.order['delivery_address'] ?? 'N/A', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                              Text('Phone: ${customer?['mobile_number'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Shipping Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                              SizedBox(height: 8),
                              Text(customer?['name'] ?? 'N/A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(widget.order['delivery_address'] ?? 'N/A', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                              Text('Phone: ${customer?['mobile_number'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 32),
                    Text('Product Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                      columnWidths: {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.5),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Color(0xFF2E7D32).withOpacity(0.1)),
                          children: [
                            Padding(padding: EdgeInsets.all(8), child: Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Delivery (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Platform (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(padding: EdgeInsets.all(8), child: Text(product?['name'] ?? 'N/A', style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('$quantity', style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text(price.toStringAsFixed(2), style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text(deliveryCharge.toStringAsFixed(2), style: TextStyle(fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text(adminCommission.toStringAsFixed(2), style: TextStyle(fontSize: 11))),
                          ],
                        ),
                      ],
                    ),
                    Divider(height: 32),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Qty:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text('$quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
                          SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Price (₹):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text(price.toStringAsFixed(2), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
                          SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery Charge (₹):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text(deliveryCharge.toStringAsFixed(2), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
                          SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Platform Charge (₹):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text(adminCommission.toStringAsFixed(2), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
                          Divider(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))), Text('₹ ${totalWithTax.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))]),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            color: Colors.white,
                            child: QrImageView(
                              data: '${widget.order['order_id']}',
                              version: QrVersions.auto,
                              size: 120,
                              backgroundColor: Colors.white,
                              errorStateBuilder: (context, error) => Center(child: Text('QR Error', style: TextStyle(fontSize: 10))),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Keep this invoice for warranty purposes.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            if (_billAlreadyExists)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(child: Text('Bill already generated for this order', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            if (!_billAlreadyExists) ...[
              if (!_billGenerated)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _generateBill,
                    icon: Icon(Icons.receipt_long, color: Colors.white),
                    label: Text('Generate Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              if (_billGenerated) ...[
                if (_isProcessing) CircularProgressIndicator(color: Color(0xFF4CAF50)),
                if (!_isProcessing)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _printBill,
                      icon: Icon(Icons.print, color: Colors.white),
                      label: Text('Print Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
              ],
            ],
          ],
          ),
      ),
    );
  }
}
