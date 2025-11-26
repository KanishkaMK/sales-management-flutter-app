import 'dart:io';
import 'package:sales_management_app/domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<Map<String, dynamic>> getProductDropdowns();
  Future<String> uploadProductImage(String imagePath);
  Future<List<String>> uploadProductImages(List<File> imageFiles); 
}