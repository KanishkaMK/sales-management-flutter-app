part of 'customer_bloc.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class LoadCustomersEvent extends CustomerEvent {}

class AddCustomerEvent extends CustomerEvent {
  final Customer customer;

  const AddCustomerEvent(this.customer);

  @override
  List<Object> get props => [customer];
}

class UpdateCustomerEvent extends CustomerEvent {
  final Customer customer;

  const UpdateCustomerEvent(this.customer);

  @override
  List<Object> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final int customerId;

  const DeleteCustomerEvent(this.customerId);

  @override
  List<Object> get props => [customerId];
}

class LoadDropdownsEvent extends CustomerEvent {}