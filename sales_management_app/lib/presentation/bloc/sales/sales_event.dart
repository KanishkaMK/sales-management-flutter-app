part of 'sales_bloc.dart';

abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object> get props => [];
}

class LoadSalesDataEvent extends SalesEvent {}

// NEW EVENT: Load invoices separately
class LoadInvoicesEvent extends SalesEvent {}

class AddInvoiceItemEvent extends SalesEvent {
  final InvoiceItem item;

  const AddInvoiceItemEvent(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateInvoiceItemEvent extends SalesEvent {
  final int index;
  final InvoiceItem item;

  const UpdateInvoiceItemEvent(this.index, this.item);

  @override
  List<Object> get props => [index, item];
}

class RemoveInvoiceItemEvent extends SalesEvent {
  final int index;

  const RemoveInvoiceItemEvent(this.index);

  @override
  List<Object> get props => [index];
}

class SetCustomerEvent extends SalesEvent {
  final int customerId;
  final String customerName;
  final String customerAddress;

  const SetCustomerEvent(this.customerId, this.customerName, this.customerAddress);

  @override
  List<Object> get props => [customerId, customerName, customerAddress];
}

class CreateInvoiceEvent extends SalesEvent {
  final List<InvoiceItem> items;
  final int customerId;
  final String customerAddress;

  const CreateInvoiceEvent(this.items, this.customerId, this.customerAddress);

  @override
  List<Object> get props => [items, customerId, customerAddress];
}