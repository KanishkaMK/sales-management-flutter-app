import 'package:sales_management_app/data/datasources/api_client.dart';
import 'package:sales_management_app/data/datasources/local_storage.dart';
import 'package:sales_management_app/domain/entities/sales_invoice.dart';
import 'package:sales_management_app/domain/repositories/sales_repository.dart';

class SalesRepositoryImpl implements SalesRepository {
  final ApiClient apiClient;
  final LocalStorage localStorage;

  SalesRepositoryImpl({required this.apiClient, required this.localStorage});

  @override
Future<SalesInvoice> createInvoice(SalesInvoice invoice) async {
  try {
    final token = await localStorage.getToken();
    print('🔄 SalesRepository: Creating invoice...');
    print('🔍 Invoice data: ${invoice.toJson()}');
    
    final response = await apiClient.post(
      '/api/sales-invoices', 
      invoice.toJson(),
      token: token
    );
    
    print('✅ SalesRepository: Invoice creation response: $response');
    
    if (response['success'] == true) {
      return invoice.copyWith(txnNo: response['txnNo']);
    } else {
      throw Exception(response['error'] ?? 'Failed to create invoice');
    }
  } catch (e) {
    print('❌ SalesRepository: Error creating invoice: $e');
    throw Exception('Failed to create invoice: $e');
  }
}

@override
Future<List<SalesInvoice>> getInvoices() async {
  try {
    final token = await localStorage.getToken();
    final response = await apiClient.get('/api/sales-invoices', token: token);
    
    if (response['success'] == true && response['data'] is List) {
      return (response['data'] as List).map((item) => SalesInvoice.fromJson(item)).toList();
    }
    return [];
  } catch (e) {
    print('❌ SalesRepository: Error loading invoices: $e');
    throw Exception('Failed to load invoices: $e');
  }
}

  @override
  Future<List<dynamic>> getCustomers() async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.get('/api/customers', token: token);
      return response is List ? response : [];
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  @override
  Future<List<dynamic>> getProducts() async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.get('/api/products', token: token);
      
      if (response is List) {
        // Process products to ensure numeric values
        return response.map((product) {
          return {
            'ID': product['ID'] ?? product['id'] ?? 0,
            'Name': product['Name'] ?? product['name'] ?? '',
            'CategoryID': product['CategoryID'] ?? product['categoryId'] ?? 0,
            'BrandID': product['BrandID'] ?? product['brandId'] ?? 0,
            'PurchaseRate': _parseDouble(product['PurchaseRate'] ?? product['purchaseRate']),
            'SalesRate': _parseDouble(product['SalesRate'] ?? product['salesRate']),
            'CategoryName': product['CategoryName'] ?? product['categoryName'],
            'BrandName': product['BrandName'] ?? product['brandName'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading products in sales repository: $e');
      throw Exception('Failed to load products: $e');
    }
  }

  // Helper method to safely parse double values from API response
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove any non-numeric characters except decimal point and minus sign
      final cleanedValue = value.toString().replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleanedValue) ?? 0.0;
    }
    return 0.0;
  }
}

// Extension for copyWith method
extension SalesInvoiceExtension on SalesInvoice {
  SalesInvoice copyWith({
    int? txnNo,
    DateTime? txnDate,
    int? customerId,
    String? address,
    double? totalQty,
    double? totalAmount,
    List<SalesDetail>? items,
  }) {
    return SalesInvoice(
      txnNo: txnNo ?? this.txnNo,
      txnDate: txnDate ?? this.txnDate,
      customerId: customerId ?? this.customerId,
      address: address ?? this.address,
      totalQty: totalQty ?? this.totalQty,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
    );
  }
}