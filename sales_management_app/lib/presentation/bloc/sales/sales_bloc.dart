import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sales_management_app/domain/entities/sales_invoice.dart';
import 'package:sales_management_app/domain/repositories/sales_repository.dart';

part 'sales_event.dart';
part 'sales_state.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SalesRepository salesRepository;

  SalesBloc({required this.salesRepository}) : super(SalesInitial()) {
    on<LoadSalesDataEvent>(_onLoadSalesData);
    on<AddInvoiceItemEvent>(_onAddInvoiceItem);
    on<UpdateInvoiceItemEvent>(_onUpdateInvoiceItem);
    on<RemoveInvoiceItemEvent>(_onRemoveInvoiceItem);
    on<SetCustomerEvent>(_onSetCustomer);
    on<CreateInvoiceEvent>(_onCreateInvoice);
    on<LoadInvoicesEvent>(_onLoadInvoices); //  EVENT
  }

  void _onLoadSalesData(LoadSalesDataEvent event, Emitter<SalesState> emit) async {
    emit(SalesLoading());
    try {
      print('🔄 SalesBloc: Loading sales data...');
      
      final customers = await salesRepository.getCustomers();
      final products = await salesRepository.getProducts();
      final invoices = await salesRepository.getInvoices(); //  Load invoices
      
      print('✅ SalesBloc: Loaded ${customers.length} customers, ${products.length} products, ${invoices.length} invoices');
      
      emit(SalesDataLoaded(
        customers: customers,
        products: products,
        invoices: invoices, //  Include invoices
        invoiceItems: [],
      ));
    } catch (e) {
      print('❌ SalesBloc: Error loading sales data: $e');
      emit(SalesError(e.toString()));
    }
  }

  // NEW: Load invoices separately
  void _onLoadInvoices(LoadInvoicesEvent event, Emitter<SalesState> emit) async {
    if (state is SalesDataLoaded) {
      final currentState = state as SalesDataLoaded;
      emit(SalesLoading());
      
      try {
        print('🔄 SalesBloc: Loading invoices...');
        final invoices = await salesRepository.getInvoices();
        
        print('✅ SalesBloc: Loaded ${invoices.length} invoices');
        
        emit(currentState.copyWith(invoices: invoices));
      } catch (e) {
        print('❌ SalesBloc: Error loading invoices: $e');
        emit(currentState.copyWith());
        emit(SalesError(e.toString()));
      }
    }
  }

  void _onAddInvoiceItem(AddInvoiceItemEvent event, Emitter<SalesState> emit) {
    print('🔄 SalesBloc: Processing AddInvoiceItemEvent');
    print('🔍 Event item: ${event.item.productName}');
    print('🔍 Event item details: ${event.item.toJson()}');
    
    if (state is SalesDataLoaded) {
      final currentState = state as SalesDataLoaded;
      print('🔍 Current items count: ${currentState.invoiceItems.length}');
      
      final updatedItems = List<InvoiceItem>.from(currentState.invoiceItems)..add(event.item);
      
      print('✅ Updated items count: ${updatedItems.length}');
      print('🔍 Emitting new state with updated items');
      
      emit(currentState.copyWith(invoiceItems: updatedItems));
      
      print('✅ State emitted successfully');
    } else {
      print('❌ Current state is not SalesDataLoaded: ${state.runtimeType}');
    }
  }

  void _onUpdateInvoiceItem(UpdateInvoiceItemEvent event, Emitter<SalesState> emit) {
    if (state is SalesDataLoaded) {
      final currentState = state as SalesDataLoaded;
      final updatedItems = List<InvoiceItem>.from(currentState.invoiceItems);
      updatedItems[event.index] = event.item;
      
      emit(currentState.copyWith(invoiceItems: updatedItems));
    }
  }

  void _onRemoveInvoiceItem(RemoveInvoiceItemEvent event, Emitter<SalesState> emit) {
    if (state is SalesDataLoaded) {
      final currentState = state as SalesDataLoaded;
      final updatedItems = List<InvoiceItem>.from(currentState.invoiceItems)..removeAt(event.index);
      
      emit(currentState.copyWith(invoiceItems: updatedItems));
    }
  }

  void _onSetCustomer(SetCustomerEvent event, Emitter<SalesState> emit) {
    if (state is SalesDataLoaded) {
      final currentState = state as SalesDataLoaded;
      emit(currentState.copyWith(
        selectedCustomerId: event.customerId,
        selectedCustomerName: event.customerName,
        selectedCustomerAddress: event.customerAddress,
      ));
    }
  }

  void _onCreateInvoice(CreateInvoiceEvent event, Emitter<SalesState> emit) async {
    print('🔄 SalesBloc: Creating invoice...');
    print('🔍 Event data:');
    print('   - CustomerId: ${event.customerId}');
    print('   - CustomerAddress: ${event.customerAddress}');
    print('   - Items count: ${event.items.length}');
    
    if (state is SalesDataLoaded) {
      final currentState = state as SalesDataLoaded;
      emit(SalesLoading());
      
      try {
        // Calculate totals
        final totalQty = event.items.fold(0.0, (sum, item) => sum + item.quantity);
        final totalAmount = event.items.fold(0.0, (sum, item) => sum + item.amount);
        
        print('🔍 Calculated totals:');
        print('   - TotalQty: $totalQty');
        print('   - TotalAmount: $totalAmount');
        
        // Create sales details
        final salesDetails = event.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return SalesDetail(
            id: 0,
            txnNo: 0,
            sno: index + 1,
            productId: item.productId,
            quantity: item.quantity,
            rate: item.rate,
            discount: item.discount,
            amount: item.amount,
          );
        }).toList();
        
        print('🔍 Created ${salesDetails.length} sales details');
        
        // Create sales invoice
        final invoice = SalesInvoice(
          txnNo: 0,
          txnDate: DateTime.now(),
          customerId: event.customerId,
          address: event.customerAddress,
          totalQty: totalQty,
          totalAmount: totalAmount,
          items: salesDetails,
        );
        
        print('🎯 Sending invoice to repository...');
        await salesRepository.createInvoice(invoice);
        
        print('✅ Invoice created successfully!');
        
        // Reload all data including invoices
        final customers = await salesRepository.getCustomers();
        final products = await salesRepository.getProducts();
        final invoices = await salesRepository.getInvoices(); //  Reload invoices
        
        print('✅ Reloaded data: ${invoices.length} invoices');
        
        emit(SalesDataLoaded(
          customers: customers,
          products: products,
          invoices: invoices, // Include updated invoices
          invoiceItems: [],
        ));
        
        emit(SalesOperationSuccess('Invoice created successfully!'));
        
      } catch (e) {
        print('❌ Error creating invoice: $e');
        // Return to previous state on error
        emit(SalesDataLoaded(
          customers: currentState.customers,
          products: currentState.products,
          invoices: currentState.invoices, //Include invoices
          invoiceItems: currentState.invoiceItems,
          selectedCustomerId: currentState.selectedCustomerId,
          selectedCustomerName: currentState.selectedCustomerName,
          selectedCustomerAddress: currentState.selectedCustomerAddress,
        ));
        emit(SalesError(e.toString()));
      }
    }
  }
}

// Extension for copyWith method
extension SalesDataLoadedExtension on SalesDataLoaded {
  SalesDataLoaded copyWith({
    List<dynamic>? customers,
    List<dynamic>? products,
    List<SalesInvoice>? invoices, // invoices parameter
    List<InvoiceItem>? invoiceItems,
    int? selectedCustomerId,
    String? selectedCustomerName,
    String? selectedCustomerAddress,
  }) {
    return SalesDataLoaded(
      customers: customers ?? this.customers,
      products: products ?? this.products,
      invoices: invoices ?? this.invoices, // Include invoices
      invoiceItems: invoiceItems ?? this.invoiceItems,
      selectedCustomerId: selectedCustomerId ?? this.selectedCustomerId,
      selectedCustomerName: selectedCustomerName ?? this.selectedCustomerName,
      selectedCustomerAddress: selectedCustomerAddress ?? this.selectedCustomerAddress,
    );
  }
}