import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();
//  static const String baseUrl = 'http://10.0.2.2:3000'; // For Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // For iOS simulator
   static const String baseUrl = 'http://192.168.1.36:3000'; // For physical device

  ApiClient() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  Future<dynamic> post(String endpoint, dynamic data, {String? token}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          contentType: Headers.jsonContentType,
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  Future<dynamic> put(String endpoint, dynamic data, {String? token}) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      final response = await _dio.delete(
        endpoint,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }
}