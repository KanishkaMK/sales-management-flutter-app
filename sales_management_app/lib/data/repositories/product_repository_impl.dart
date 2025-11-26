
import 'dart:io';
import 'package:sales_management_app/data/datasources/api_client.dart';
import 'package:sales_management_app/data/datasources/local_storage.dart';
import 'package:sales_management_app/data/datasources/image_upload_service.dart';
import 'package:sales_management_app/domain/entities/product.dart';
import 'package:sales_management_app/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiClient apiClient;
  final LocalStorage localStorage;
  final ImageUploadService imageUploadService;

  ProductRepositoryImpl({
    required this.apiClient, 
    required this.localStorage,
    required this.imageUploadService,
  });

  @override
  Future<List<Product>> getProducts() async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.get('/api/products', token: token);
      
      if (response is List) {
        // Load images for each product
        final products = await Future.wait(
          response.map((item) async {
            final product = Product.fromJson(item);
            final images = await imageUploadService.getProductImages(product.id);
            return product.copyWith(imagePaths: images);
          })
        );
        return products;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  @override
  Future<Product> createProduct(Product product) async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.post(
        '/api/products', 
        product.toJson(),
        token: token
      );
      
      final newProduct = product.copyWith(id: response['id']);
      
      // Upload images if any
      if (product.imagePaths.isNotEmpty) { // imagePaths is never null
        // Handle image uploads here if needed
        // You can save image references after product is created
        for (final imagePath in product.imagePaths) {
          await imageUploadService.saveProductImageReference(newProduct.id, imagePath);
        }
      }
      
      return newProduct;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<Product> updateProduct(Product product) async {
    try {
      final token = await localStorage.getToken();
      await apiClient.put(
        '/api/products/${product.id}', 
        product.toJson(),
        token: token
      );
      
      return product;
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      final token = await localStorage.getToken();
      await apiClient.delete(
        '/api/products/$id', 
        token: token
      );
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getProductDropdowns() async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.get('/api/product-dropdowns', token: token);
      return response['data'] ?? {};
    } catch (e) {
      // Return demo data if API fails
      return {
        'categories': [
          {'ID': 1, 'Name': 'Electronics'},
          {'ID': 2, 'Name': 'Clothing'},
          {'ID': 3, 'Name': 'Food'},
          {'ID': 4, 'Name': 'Books'},
        ],
        'brands': [
          {'ID': 1, 'Name': 'Samsung'},
          {'ID': 2, 'Name': 'Nike'},
          {'ID': 3, 'Name': 'Apple'},
          {'ID': 4, 'Name': 'Adidas'},
        ],
      };
    }
  }

  @override
  Future<String> uploadProductImage(String imagePath) async {
    final file = File(imagePath);
    final result = await imageUploadService.uploadProductImage(file);
    
    if (result['success'] == true) {
      return result['imagePath'] ?? 'uploads/default_product.jpg';
    } else {
      throw Exception('Failed to upload image: ${result['error']}');
    }
  }

  // New method to handle multiple image uploads
  @override
  Future<List<String>> uploadProductImages(List<File> imageFiles) async {
    final uploadedPaths = <String>[];
    
    for (final imageFile in imageFiles) {
      try {
        final result = await imageUploadService.uploadProductImage(imageFile);
        if (result['success'] == true && result['imagePath'] != null) {
          uploadedPaths.add(result['imagePath']!);
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
    
    return uploadedPaths;
  }
}