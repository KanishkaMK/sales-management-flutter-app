import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sales_management_app/domain/entities/customer.dart';
import 'package:sales_management_app/domain/repositories/customer_repository.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository customerRepository;

  CustomerBloc({required this.customerRepository}) : super(CustomerInitial()) {
    on<LoadCustomersEvent>(_onLoadCustomers);
    on<AddCustomerEvent>(_onAddCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<LoadDropdownsEvent>(_onLoadDropdowns);
  }

  void _onLoadCustomers(LoadCustomersEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final customers = await customerRepository.getCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onAddCustomer(AddCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      // Show loading state
      if (state is CustomerLoaded) {
        final currentState = state as CustomerLoaded;
        emit(CustomerLoaded(currentState.customers, dropdowns: currentState.dropdowns, isLoading: true));
      }
      
      await customerRepository.createCustomer(event.customer);
      final customers = await customerRepository.getCustomers();
      
      // Return to normal state with success
      emit(CustomerLoaded(customers, dropdowns: (state as CustomerLoaded).dropdowns));
      emit(CustomerOperationSuccess('Customer added successfully'));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onUpdateCustomer(UpdateCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      // Show loading state
      if (state is CustomerLoaded) {
        final currentState = state as CustomerLoaded;
        emit(CustomerLoaded(currentState.customers, dropdowns: currentState.dropdowns, isLoading: true));
      }
      
      await customerRepository.updateCustomer(event.customer);
      final customers = await customerRepository.getCustomers();
      
      // Return to normal state with success
      emit(CustomerLoaded(customers, dropdowns: (state as CustomerLoaded).dropdowns));
      emit(CustomerOperationSuccess('Customer updated successfully'));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onDeleteCustomer(DeleteCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      // Show loading state
      if (state is CustomerLoaded) {
        final currentState = state as CustomerLoaded;
        emit(CustomerLoaded(currentState.customers, dropdowns: currentState.dropdowns, isLoading: true));
      }
      
      await customerRepository.deleteCustomer(event.customerId);
      final customers = await customerRepository.getCustomers();
      
      // Return to normal state with success
      emit(CustomerLoaded(customers, dropdowns: (state as CustomerLoaded).dropdowns));
      emit(CustomerOperationSuccess('Customer deleted successfully'));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onLoadDropdowns(LoadDropdownsEvent event, Emitter<CustomerState> emit) async {
    try {
      print('🔄 CustomerBloc: Loading dropdowns...');
      
      // If we're in CustomerLoaded state, preserve customers and show loading
      if (state is CustomerLoaded) {
        final currentState = state as CustomerLoaded;
        emit(CustomerLoaded(currentState.customers, dropdowns: currentState.dropdowns, isLoading: true));
      } else {
        // If no state yet, create initial loading state
        emit(CustomerLoading());
      }
      
      final dropdowns = await customerRepository.getDropdowns();
      print('✅ CustomerBloc: Dropdowns loaded successfully');
      print('📊 CustomerBloc: Areas: ${dropdowns['areas']?.length ?? 0}');
      print('📊 CustomerBloc: Categories: ${dropdowns['categories']?.length ?? 0}');
      
      // Emit new state with dropdowns
      if (state is CustomerLoaded) {
        final currentState = state as CustomerLoaded;
        emit(CustomerLoaded(currentState.customers, dropdowns: dropdowns));
      } else {
        emit(CustomerLoaded([], dropdowns: dropdowns));
      }
    } catch (e) {
      print('❌ CustomerBloc: Error loading dropdowns: $e');
      
      // Even on error, emit state with demo data
      final demoDropdowns = {
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
      
      if (state is CustomerLoaded) {
        final currentState = state as CustomerLoaded;
        emit(CustomerLoaded(currentState.customers, dropdowns: demoDropdowns));
      } else {
        emit(CustomerLoaded([], dropdowns: demoDropdowns));
      }
    }
  }
}