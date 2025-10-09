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

  static String optimizeImageUrl(String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!imageUrl.contains('cloudinary.com')) {
      return imageUrl; // Return original URL if it's not a Cloudinary URL
    }

    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 3) {
      return imageUrl; // Return original if URL structure is unexpected
    }

    // Extract the public_id and format from the original URL
    final publicId = pathSegments[pathSegments.length - 1];
    final originalFormat = publicId.contains('.') ? publicId.split('.').last : 'jpg';
    
    // Build transformation parameters
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (quality != 'auto') transformations.add('q_$quality');
    if (format != 'auto') transformations.add('f_$format');
    
    // Add quality and format if they're set to auto
    if (quality == 'auto') transformations.add('q_auto');
    if (format == 'auto') transformations.add('f_auto');
    
    final transformationString = transformations.isNotEmpty 
        ? transformations.join(',') + '/' 
        : '';
    
    // Reconstruct the URL with transformations
    final optimizedUrl = '${uri.scheme}://${uri.host}/${pathSegments[0]}/${pathSegments[1]}/image/upload/$transformationString$publicId';
    
    return optimizedUrl;
  }
} 