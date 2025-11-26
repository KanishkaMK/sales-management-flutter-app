import 'package:sales_management_app/domain/entities/sales_invoice.dart';

abstract class SalesRepository {
  Future<List<SalesInvoice>> getInvoices();
  Future<SalesInvoice> createInvoice(SalesInvoice invoice);
  Future<List<dynamic>> getCustomers();
  Future<List<dynamic>> getProducts();
}