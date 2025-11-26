class Product {
  final int id;
  final String name;
  final int categoryId;
  final int brandId;
  final double salesRate;
  final double purchaseRate;
  final String? categoryName;
  final String? brandName;
  final List<String> imagePaths; // Remove nullable and provide default value

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.brandId,
    required this.salesRate,
    required this.purchaseRate,
    this.categoryName,
    this.brandName,
    List<String>? imagePaths, // Make parameter nullable but store as non-null
  }) : imagePaths = imagePaths ?? []; // Provide empty list as default

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'CategoryID': categoryId,
      'BrandID': brandId,
      'SalesRate': salesRate,
      'PurchaseRate': purchaseRate,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['ID'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      categoryId: json['CategoryID'] ?? json['categoryId'] ?? 0,
      brandId: json['BrandID'] ?? json['brandId'] ?? 0,
      salesRate: _parseDouble(json['SalesRate'] ?? json['salesRate']),
      purchaseRate: _parseDouble(json['PurchaseRate'] ?? json['purchaseRate']),
      categoryName: json['CategoryName'] ?? json['categoryName'],
      brandName: json['BrandName'] ?? json['brandName'],
      imagePaths: List<String>.from(json['imagePaths'] ?? []), // Always provide list
    );
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove any non-numeric characters except decimal point
      final cleanedValue = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanedValue) ?? 0.0;
    }
    
    return 0.0;
  }

  Product copyWith({
    int? id,
    String? name,
    int? categoryId,
    int? brandId,
    double? salesRate,
    double? purchaseRate,
    String? categoryName,
    String? brandName,
    List<String>? imagePaths,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      salesRate: salesRate ?? this.salesRate,
      purchaseRate: purchaseRate ?? this.purchaseRate,
      categoryName: categoryName ?? this.categoryName,
      brandName: brandName ?? this.brandName,
      imagePaths: imagePaths ?? this.imagePaths, // Use the non-null list
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.categoryId == categoryId &&
        other.brandId == brandId &&
        other.salesRate == salesRate &&
        other.purchaseRate == purchaseRate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        categoryId.hashCode ^
        brandId.hashCode ^
        salesRate.hashCode ^
        purchaseRate.hashCode;
  }
}