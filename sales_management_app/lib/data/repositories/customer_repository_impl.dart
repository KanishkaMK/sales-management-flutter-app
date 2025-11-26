
import 'package:sales_management_app/data/datasources/api_client.dart';
import 'package:sales_management_app/data/datasources/local_storage.dart';
import 'package:sales_management_app/domain/entities/customer.dart';
import 'package:sales_management_app/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final ApiClient apiClient;
  final LocalStorage localStorage;

  CustomerRepositoryImpl({required this.apiClient, required this.localStorage});

  @override
  Future<List<Customer>> getCustomers() async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.get('/api/customers', token: token);
      
      if (response is List) {
        return response.map((item) => Customer.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.post(
        '/api/customers', 
        customer.toJson(),
        token: token
      );
      
      return customer.copyWith(id: response['id']);
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.put(
        '/api/customers/${customer.id}', 
        customer.toJson(),
        token: token
      );
      
      return customer;
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  @override
  Future<void> deleteCustomer(int id) async {
    try {
      final token = await localStorage.getToken();
      await apiClient.delete(
        '/api/customers/$id', 
        token: token
      );
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDropdowns() async {
    try {
      final token = await localStorage.getToken();
      final response = await apiClient.get('/api/dropdowns', token: token);
      return response['data'] ?? {};
    } catch (e) {
      // Return demo data if API fails
      return {
        'areas': [
          {'ID': 1, 'Name': 'North'},
          {'ID': 2, 'Name': 'South'},
          {'ID': 3, 'Name': 'East'},
          {'ID': 4, 'Name': 'West'},
        ],
        'categories': [
          {'ID': 1, 'Name': 'Regular'},
          {'ID': 2, 'Name': 'Premium'},
          {'ID': 3, 'Name': 'Wholesale'},
        ],
      };
    }
  }
}