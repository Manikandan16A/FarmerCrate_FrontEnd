import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryUploader {
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final cloudName = 'dcwpr28uf';
      final apiKey = '334646742262894';
      final apiSecret = 'QlFJbjla0epfpzpTib6R0STIEFg';
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // For signed upload, create the signature
      final paramsToSign = 'timestamp=$timestamp';
      final signature = sha1.convert(utf8.encode(paramsToSign + apiSecret)).toString();

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final resJson = jsonDecode(resStr);
        return resJson['secure_url'];
      } else {
        // Log the error for debugging
        final errorResponse = await response.stream.bytesToString();
        print('Cloudinary upload failed with status: ${response.statusCode}');
        print('Error response: $errorResponse');
        return null;
      }
    } catch (e) {
      // Log the exception for debugging
      print('Exception during Cloudinary upload: $e');
      return null;
    }
  }
} 