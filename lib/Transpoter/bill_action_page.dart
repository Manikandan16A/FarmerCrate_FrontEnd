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
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import '../utils/cloudinary_upload.dart';

class BillActionPage extends StatefulWidget {
  final dynamic order;
  final String? token;

  const BillActionPage({super.key, required this.order, this.token});

  @override
  State<BillActionPage> createState() => _BillActionPageState();
}

class _BillActionPageState extends State<BillActionPage> {
  final GlobalKey _billKey = GlobalKey();
  bool _isProcessing = false;

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

    print('=== BILL DETAILS ===');
    print('Order ID: ${widget.order['order_id']}');
    print('Product: ${product?['name']}');
    print('Customer: ${customer?['name']}');
    print('Phone: ${customer?['mobile_number']}');
    print('Address: ${widget.order['delivery_address']}');
    print('Quantity: $quantity');
    print('Price: ₹$price');
    print('Delivery Charge: ₹$deliveryCharge');
    print('Platform Charge: ₹$adminCommission');
    print('Grand Total: ₹$totalWithTax');
    print('Order Date: ${DateFormat('dd-MM-yyyy').format(orderDate)}');
    print('Invoice Date: ${DateFormat('dd-MM-yyyy').format(invoiceDate)}');
    print('===================');

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('FarmerCrate', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('Contact us: +91 9551084651 || farmercrate@gmail.com', style: pw.TextStyle(fontSize: 12))),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('FarmerCrate Retail Private Limited', style: pw.TextStyle(fontSize: 11))),
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
                        pw.Text('Billing Address', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(customer?['name'] ?? 'N/A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text(widget.order['delivery_address'] ?? 'N/A', style: pw.TextStyle(fontSize: 11)),
                        pw.Text('Phone: ${customer?['mobile_number'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Shipping Address', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(customer?['name'] ?? 'N/A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text(widget.order['delivery_address'] ?? 'N/A', style: pw.TextStyle(fontSize: 11)),
                        pw.Text('Phone: ${customer?['mobile_number'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(height: 32),
              pw.Text('Product Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Product', 'Qty', 'Price (₹)', 'Delivery (₹)', 'Platform (₹)'],
                data: [
                  [product?['name'] ?? 'N/A', '$quantity', price.toStringAsFixed(2), deliveryCharge.toStringAsFixed(2), adminCommission.toStringAsFixed(2)],
                ],
              ),
              pw.Divider(height: 32),
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  children: [
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Qty:'), pw.Text('$quantity')]),
                    pw.SizedBox(height: 4),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Price (₹):'), pw.Text(price.toStringAsFixed(2))]),
                    pw.SizedBox(height: 4),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Delivery Charge (₹):'), pw.Text(deliveryCharge.toStringAsFixed(2))]),
                    pw.SizedBox(height: 4),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Platform Charge (₹):'), pw.Text(adminCommission.toStringAsFixed(2))]),
                    pw.Divider(height: 16),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Text('₹ ${totalWithTax.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))]),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text('Keep this invoice for warranty purposes.', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  Future<void> _printBill() async {
    setState(() => _isProcessing = true);
    try {
      final pdf = await _createPdf();
      final pdfBytes = await pdf.save();
      await Printing.directPrintPdf(printer: Printer(url: ''), onLayout: (PdfPageFormat format) async => pdfBytes);
      _showSuccessSnackBar('Bill printed successfully!');
    } catch (e) {
      print('Print Error: $e');
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
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/Bill_FC-${widget.order['order_id']}-${DateTime.now().year}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      _showSuccessSnackBar('PDF downloaded to: $filePath');
    } catch (e) {
      print('Download Error: $e');
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
        print('Cloudinary URL: $billUrl');
        await _saveBillUrlToDatabase(billUrl);
        await file.delete();
      } else {
        _showErrorSnackBar('Failed to upload to Cloudinary');
      }
    } catch (e) {
      print('Upload Error: $e');
      _showErrorSnackBar('Upload failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveBillUrlToDatabase(String billUrl) async {
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/orders/${widget.order['order_id']}/bill'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'bill_url': billUrl}),
      );

      print('Save Bill URL Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar('Bill URL saved successfully!');
      } else {
        _showErrorSnackBar('Failed to save bill URL');
      }
    } catch (e) {
      print('Save URL Error: $e');
      _showErrorSnackBar('Error saving bill URL: $e');
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
        title: Text('Bill Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    Center(
                      child: Column(
                        children: [
                          Text('FarmerCrate', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          SizedBox(height: 8),
                          Text('Contact us: +91 9551084651 || farmercrate@gmail.com', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          SizedBox(height: 8),
                          Text('FarmerCrate Retail Private Limited', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
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
                            _buildTableCell('Product', isHeader: true),
                            _buildTableCell('Qty', isHeader: true),
                            _buildTableCell('Price (₹)', isHeader: true),
                            _buildTableCell('Delivery (₹)', isHeader: true),
                            _buildTableCell('Platform (₹)', isHeader: true),
                          ],
                        ),
                        TableRow(
                          children: [
                            _buildTableCell(product?['name'] ?? 'N/A'),
                            _buildTableCell('$quantity'),
                            _buildTableCell(price.toStringAsFixed(2)),
                            _buildTableCell(deliveryCharge.toStringAsFixed(2)),
                            _buildTableCell(adminCommission.toStringAsFixed(2)),
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
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Qty:'), Text('$quantity')]),
                          SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Price (₹):'), Text(price.toStringAsFixed(2))]),
                          SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery Charge (₹):'), Text(deliveryCharge.toStringAsFixed(2))]),
                          SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Platform Charge (₹):'), Text(adminCommission.toStringAsFixed(2))]),
                          Divider(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))), Text('₹ ${totalWithTax.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))]),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          QrImageView(data: '${widget.order['order_id']}', version: QrVersions.auto, size: 120, backgroundColor: Colors.white),
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
            if (_isProcessing) CircularProgressIndicator(color: Color(0xFF4CAF50)),
            if (!_isProcessing) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _printBill,
                  icon: Icon(Icons.print, color: Colors.white),
                  label: Text('Connect Printer & Print', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _downloadPdf,
                  icon: Icon(Icons.download, color: Colors.white),
                  label: Text('Download PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _uploadToCloudinary,
                  icon: Icon(Icons.cloud_upload, color: Colors.white),
                  label: Text('Upload & Save to Database', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1976D2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Text(text, style: TextStyle(fontSize: isHeader ? 12 : 11, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: isHeader ? Color(0xFF2E7D32) : Colors.black87)),
    );
  }
}
