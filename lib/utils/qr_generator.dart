import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'cloudinary_upload.dart';

class QRGenerator {
  static Future<String?> generateOrderQR(Map<String, dynamic> orderData) async {
    try {
      print('Generating QR code for order data: $orderData');

      // Use only order_id for QR code (simpler and easier to scan)
      final orderId = orderData['order_id'];
      String qrData = 'order_id: $orderId';
      print('QR data string: $qrData');

      // Generate QR code image
      final qrValidationResult = QrValidator.validate(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      print('QR validation status: ${qrValidationResult.status}');

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final painter = QrPainter(
          data: qrData,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.L,
        );

        // Create image from QR painter
        final picData = await painter.toImageData(300);
        if (picData == null) {
          print('Failed to generate QR image data');
          return null;
        }

        final buffer = picData.buffer.asUint8List();
        print('QR image buffer size: ${buffer.length}');

        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final fileName = 'qr_${orderData['order_id'] ?? DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(buffer);

        print('QR image saved to: ${file.path}');

        // Upload to Cloudinary
        final cloudinaryUrl = await CloudinaryUploader.uploadImage(file);
        print('Cloudinary upload result: $cloudinaryUrl');

        // Clean up temporary file
        try {
          await file.delete();
          print('Temporary file deleted');
        } catch (e) {
          print('Failed to delete temporary file: $e');
        }

        return cloudinaryUrl;
      } else {
        print('QR validation failed: ${qrValidationResult.status}');
      }
      return null;
    } catch (e) {
      print('Error generating QR code: $e');
      return null;
    }
  }
}