part of 'customer_bloc.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  final Map<String, dynamic>? dropdowns;
  final bool isLoading;

  const CustomerLoaded(this.customers, {this.dropdowns, this.isLoading = false});

  @override
  List<Object> get props => [customers, isLoading];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object> get props => [message];
}

class CustomerOperationSuccess extends CustomerState {
  final String message;

  const CustomerOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}