import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management_app/data/repositories/sales_repository_impl.dart';
import 'package:sales_management_app/domain/entities/sales_invoice.dart';
import 'package:sales_management_app/presentation/bloc/sales/sales_bloc.dart';
import 'package:sales_management_app/presentation/widgets/product_selection_dialog.dart';

class SalesInvoicePage extends StatefulWidget {
  const SalesInvoicePage({Key? key}) : super(key: key);

  @override
  State<SalesInvoicePage> createState() => _SalesInvoicePageState();
}

class _SalesInvoicePageState extends State<SalesInvoicePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesBloc>().add(LoadSalesDataEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveInvoice,
            tooltip: 'Save Invoice',
          ),
          IconButton(
  icon: const Icon(Icons.bug_report),
  onPressed: () {
    _debugCheckInvoices();
  },
  tooltip: 'Debug Invoices',
),
        ],
      ),
      body: BlocListener<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state is SalesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is SalesOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            if (state is SalesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SalesDataLoaded) {
              return _buildInvoiceForm(state);
            } else if (state is SalesError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('Loading...'));
          },
        ),
      ),
    );
  }

  Widget _buildInvoiceForm(SalesDataLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Section
          _buildHeaderSection(state),
          const SizedBox(height: 20),
          
          // Customer Selection
          _buildCustomerSection(state),
          const SizedBox(height: 20),
          
          // Products Section
          _buildProductsSection(state),
          const SizedBox(height: 20),
          
          // Totals Section
          _buildTotalsSection(state),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(SalesDataLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice No: INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            Icon(Icons.receipt_long, color: Colors.blue[700], size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(SalesDataLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: state.selectedCustomerId,
              decoration: const InputDecoration(
                labelText: 'Select Customer *',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Select a customer'),
                ),
                ...state.customers.map<DropdownMenuItem<int?>>((customer) {
                  return DropdownMenuItem<int?>(
                    value: customer['ID'],
                    child: Text('${customer['Name']} - ${customer['Address']}'),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                if (value != null) {
                  final customer = state.customers.firstWhere(
                    (c) => c['ID'] == value,
                    orElse: () => {},
                  );
                  if (customer.isNotEmpty) {
                    context.read<SalesBloc>().add(SetCustomerEvent(
                      value,
                      customer['Name'] ?? '',
                      customer['Address'] ?? '',
                    ));
                  }
                }
              },
            ),
            if (state.selectedCustomerName != null) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(
                  state.selectedCustomerName!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(state.selectedCustomerAddress!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(SalesDataLoaded state) {
  print('🔍 Building products section - Products count: ${state.products.length}');
  
  if (state.products.isEmpty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Products',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Icon(Icons.error, size: 48, color: Colors.orange),
            const SizedBox(height: 8),
            const Text('No products available'),
            const Text('Please check if products are loaded correctly', 
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                context.read<SalesBloc>().add(LoadSalesDataEvent());
              },
              child: const Text('Reload Products'),
            ),
          ],
        ),
      ),
    );
  }
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Products',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ElevatedButton.icon(
                onPressed: () => _showProductSelectionDialog(state),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
            const SizedBox(height: 12),
            if (state.invoiceItems.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No products added'),
                    Text('Click "Add Product" to start', style: TextStyle(fontSize: 12)),
                  ],
                ),
              )
            else
              ...state.invoiceItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildProductItem(item, index, state);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(InvoiceItem item, int index, SalesDataLoaded state) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Rate: \$${item.rate.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () {
                          if (item.quantity > 1) {
                            final updatedItem = InvoiceItem(
                              productId: item.productId,
                              productName: item.productName,
                              rate: item.rate,
                              quantity: item.quantity - 1,
                              discount: item.discount,
                            );
                            context.read<SalesBloc>().add(UpdateInvoiceItemEvent(index, updatedItem));
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.quantity.toStringAsFixed(0)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          final updatedItem = InvoiceItem(
                            productId: item.productId,
                            productName: item.productName,
                            rate: item.rate,
                            quantity: item.quantity + 1,
                            discount: item.discount,
                          );
                          context.read<SalesBloc>().add(UpdateInvoiceItemEvent(index, updatedItem));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.discount > 0)
                  Text(
                    'Discount: -\$${item.discount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    context.read<SalesBloc>().add(RemoveInvoiceItemEvent(index));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSection(SalesDataLoaded state) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Invoice Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Items:'),
                Text(state.totalQuantity.toStringAsFixed(0)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:'),
                Text(
                  '\$${state.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductSelectionDialog(SalesDataLoaded state) {
  print('🔄 Opening product selection dialog...');
  print('🔍 Available products: ${state.products.length}');
  
  showDialog(
    context: context,
    builder: (context) => ProductSelectionDialog(
      products: state.products,
      onProductSelected: (item) {
        print('🎯 onProductSelected callback triggered!');
        print('🔍 Received item: ${item.productName}');
        print('🔍 Item details: ${item.toJson()}');
        
        context.read<SalesBloc>().add(AddInvoiceItemEvent(item));
        
        print('✅ AddInvoiceItemEvent dispatched');
      },
    ),
  ).then((value) {
    print('🔍 Product selection dialog closed');
  });
}

  void _saveInvoice() {
    final state = context.read<SalesBloc>().state;
    if (state is SalesDataLoaded) {
      if (state.selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
        return;
      }

      if (state.invoiceItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one product')),
        );
        return;
      }

      context.read<SalesBloc>().add(CreateInvoiceEvent(
        state.invoiceItems,
        state.selectedCustomerId!,
        state.selectedCustomerAddress!,
      ));
    }
  }


  void _debugCheckInvoices() async {
  try {
    final repository = RepositoryProvider.of<SalesRepositoryImpl>(context);
    final invoices = await repository.getInvoices();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Invoices: ${invoices.length}'),
              const SizedBox(height: 16),
              ...invoices.map((invoice) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice #${invoice.txnNo}'),
                  Text('Customer: ${invoice.customerId}'),
                  Text('Total: \$${invoice.totalAmount}'),
                  Text('Items: ${invoice.items.length}'),
                  const Divider(),
                ],
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error checking invoices: $e')),
    );
  }
}
}