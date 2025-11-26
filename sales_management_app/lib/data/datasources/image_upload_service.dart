import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sales_management_app/data/datasources/api_client.dart';
import 'package:sales_management_app/data/datasources/local_storage.dart';

class ImageUploadService {
  final ApiClient apiClient;
  final LocalStorage localStorage;

  ImageUploadService({required this.apiClient, required this.localStorage});

  Future<Map<String, dynamic>> uploadProductImage(File imageFile) async {
    try {
      final token = await localStorage.getToken();
      String fileName = imageFile.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // Using Dio directly for multipart upload
      final dio = Dio();
      dio.options.baseUrl = ApiClient.baseUrl;
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post(
        '/api/upload-product-image',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'imagePath': response.data['imagePath']
        };
      } else {
        return {
          'success': false,
          'error': 'Upload failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Upload error: ${e.toString()}'
      };
    }
  }

  Future<bool> saveProductImageReference(int productId, String imagePath) async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.post(
        '/api/product-images',
        {
          'productId': productId,
          'imagePath': imagePath,
        },
        token: token,
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Error saving product image reference: $e');
      return false;
    }
  }

  Future<List<String>> getProductImages(int productId) async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.get(
        '/api/product-images/$productId',
        token: token,
      );
      
      if (response is List) {
        return response.map<String>((image) => image['ImagePath']?.toString() ?? '').toList();
      }
      return [];
    } catch (e) {
      print('Error fetching product images: $e');
      return [];
    }
  }
}