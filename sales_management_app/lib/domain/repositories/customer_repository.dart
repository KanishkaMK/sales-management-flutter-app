import 'package:sales_management_app/domain/entities/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers();
  Future<Customer> createCustomer(Customer customer);
  Future<Customer> updateCustomer(Customer customer);
  Future<void> deleteCustomer(int id);
}