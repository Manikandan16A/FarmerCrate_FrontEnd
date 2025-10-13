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
      final folder = 'farmer_crate';

      print('Starting Cloudinary upload...');
      print('File path: ${imageFile.path}');
      print('File exists: ${await imageFile.exists()}');
      print('File size: ${await imageFile.length()} bytes');

      // Create signature with folder parameter
      final paramsToSign = 'folder=$folder&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(paramsToSign)).toString();

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      print('Sending request to Cloudinary...');
      final response = await request.send();
      print('Response status: ${response.statusCode}');
      
      final resStr = await response.stream.bytesToString();
      print('Response body: $resStr');
      
      if (response.statusCode == 200) {
        final resJson = jsonDecode(resStr);
        final secureUrl = resJson['secure_url'];
        print('Upload successful! URL: $secureUrl');
        return secureUrl;
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        print('Error response: $resStr');
        return null;
      }
    } catch (e, stackTrace) {
      print('Exception during Cloudinary upload: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static String optimizeImageUrl(String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!imageUrl.contains('cloudinary.com')) {
      return imageUrl;
    }

    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 3) {
      return imageUrl;
    }

    // Build transformation parameters
    final transformations = <String>[];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (quality == 'auto') transformations.add('q_auto');
    if (format == 'auto') transformations.add('f_auto');
    
    final transformationString = transformations.isNotEmpty 
        ? transformations.join(',') + '/' 
        : '';
    
    // Find the 'upload' index and reconstruct URL
    final uploadIndex = pathSegments.indexOf('upload');
    if (uploadIndex == -1) return imageUrl;
    
    final beforeUpload = pathSegments.sublist(0, uploadIndex).join('/');
    final afterUpload = pathSegments.sublist(uploadIndex + 1).join('/');
    
    return '${uri.scheme}://${uri.host}/$beforeUpload/upload/$transformationString$afterUpload';
  }
} 