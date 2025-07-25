import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/azure_config.dart';

class AzureService {
  /// Upload image to Azure and get segmented result
  static Future<File> processImageWithSAM2(File imageFile) async {
    // Check if Azure is configured
    if (!AzureConfig.isConfigured()) {
      throw Exception('Azure configuration is not set up. Please update azure_config.dart with your Azure details.');
    }
    
    // Check file size
    int fileSize = await imageFile.length();
    if (fileSize > AzureConfig.maxFileSize) {
      throw Exception('Image file is too large. Maximum size is ${AzureConfig.maxFileSize / (1024 * 1024)}MB');
    }
    
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AzureConfig.functionAppUrl}${AzureConfig.sam2Endpoint}'),
      );
      
      // Add headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'x-functions-key': AzureConfig.functionKey,
      });
      
      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'patient_image.jpg',
        ),
      );
      
      // Send request
      print('Sending image to Azure SAM2 service...');
      var streamedResponse = await request.send().timeout(AzureConfig.requestTimeout);
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        // Save the processed image
        final processedImageFile = File('${imageFile.parent.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await processedImageFile.writeAsBytes(response.bodyBytes);
        
        print('SAM2 processing successful');
        return processedImageFile;
      } else {
        throw Exception('Azure SAM2 processing failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error processing image with Azure SAM2: $e');
      throw Exception('Failed to process image with Azure SAM2: $e');
    }
  }
  
  /// Alternative method for JSON-based API if your Azure function returns JSON
  static Future<Map<String, dynamic>> processImageWithSAM2Json(File imageFile) async {
    try {
      // Convert image to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      
      // Create request body
      Map<String, dynamic> requestBody = {
        'image': base64Image,
        'format': 'jpg',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Send request
      var response = await http.post(
        Uri.parse('${AzureConfig.functionAppUrl}${AzureConfig.sam2Endpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'x-functions-key': AzureConfig.functionKey,
        },
        body: jsonEncode(requestBody),
      ).timeout(AzureConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        Map<String, dynamic> result = jsonDecode(response.body);
        return result;
      } else {
        throw Exception('Azure SAM2 processing failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error processing image with Azure SAM2: $e');
      throw Exception('Failed to process image with Azure SAM2: $e');
    }
  }
  
  /// Test Azure connection
  static Future<bool> testConnection() async {
    try {
      var response = await http.get(
        Uri.parse('${AzureConfig.functionAppUrl}${AzureConfig.healthEndpoint}'),
        headers: {
          'x-functions-key': AzureConfig.functionKey,
        },
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Azure connection test failed: $e');
      return false;
    }
  }
}