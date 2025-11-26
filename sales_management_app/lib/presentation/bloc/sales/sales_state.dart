part of 'sales_bloc.dart';

abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object> get props => [];
}

class SalesInitial extends SalesState {}

class SalesLoading extends SalesState {}

class SalesDataLoaded extends SalesState {
  final List<dynamic> customers;
  final List<dynamic> products;
  final List<SalesInvoice> invoices;
  final List<InvoiceItem> invoiceItems;
  final int? selectedCustomerId;
  final String? selectedCustomerName;
  final String? selectedCustomerAddress;

  const SalesDataLoaded({
    required this.customers,
    required this.products,
    required this.invoices,
    this.invoiceItems = const [],
    this.selectedCustomerId,
    this.selectedCustomerName,
    this.selectedCustomerAddress,
  });

  // ADD THESE COMPUTED PROPERTIES
  double get totalQuantity => invoiceItems.fold(0.0, (sum, item) => sum + item.quantity);
  double get totalAmount => invoiceItems.fold(0.0, (sum, item) => sum + item.amount);

  @override
  List<Object> get props => [
        customers,
        products,
        invoices,
        invoiceItems,
        selectedCustomerId ?? 0,
        selectedCustomerName ?? '',
        selectedCustomerAddress ?? '',
      ];
}

class SalesError extends SalesState {
  final String message;

  const SalesError(this.message);

  @override
  List<Object> get props => [message];
}

class SalesOperationSuccess extends SalesState {
  final String message;

  const SalesOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}