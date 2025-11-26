import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_management_app/domain/entities/sales_invoice.dart';
import 'package:sales_management_app/presentation/bloc/sales/sales_bloc.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({Key? key}) : super(key: key);

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _selectedCustomer = 'All';
  List<String> _customerNames = ['All'];

  @override
  void initState() {
    super.initState();
    // Load sales data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesBloc>().add(LoadSalesDataEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SalesBloc>().add(LoadSalesDataEvent());
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(),
          // Report Data
          Expanded(child: _buildReportTable()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        if (state is! SalesDataLoaded) {
          return const SizedBox.shrink();
        }

        final filteredInvoices = _getFilteredInvoices(state);
        final totalAmount = filteredInvoices.fold(
          0.0,
          (sum, invoice) => sum + invoice.totalAmount,
        );
        final totalInvoices = filteredInvoices.length;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Sales',
                  '\$${totalAmount.toStringAsFixed(2)}',
                  Colors.purple,
                  Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Invoices',
                  totalInvoices.toString(),
                  Colors.green,
                  Icons.receipt,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTable() {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        if (state is SalesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SalesError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is SalesDataLoaded) {
          final filteredInvoices = _getFilteredInvoices(state);

          if (filteredInvoices.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Header
                      _buildReportHeader(state),
                      const SizedBox(height: 16),

                      // Table
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) => Colors.grey[100],
                              ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Invoice No',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Customer Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total Amount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Items',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: filteredInvoices
                              .map((invoice) => _buildDataRow(invoice))
                              .toList(),
                        ),
                      ),

                      // Total Summary
                      _buildTotalSummary(filteredInvoices),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return _buildEmptyState();
      },
    );
  }

  Widget _buildReportHeader(SalesDataLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'From ${_dateFormat.format(_fromDate)} to ${_dateFormat.format(_toDate)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        if (_selectedCustomer != 'All') ...[
          const SizedBox(height: 4),
          Text(
            'Customer: $_selectedCustomer',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  // Update the _buildDataRow method to pass state:
  DataRow _buildDataRow(SalesInvoice invoice) {
    // Find customer name - pass state
    final customerName = _getCustomerName(
      invoice.customerId,
      context.read<SalesBloc>().state as SalesDataLoaded,
    );

    return DataRow(
      cells: [
        DataCell(Text('INV-${invoice.txnNo.toString().padLeft(5, '0')}')),
        DataCell(Text(_dateFormat.format(invoice.txnDate))),
        DataCell(
          Tooltip(
            message: invoice.address,
            child: Text(customerName, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          Text(
            '\$${invoice.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          Text(invoice.items.length.toString(), textAlign: TextAlign.center),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.visibility, size: 20),
            onPressed: () {
              _showInvoiceDetails(invoice);
            },
            tooltip: 'View Details',
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSummary(List<SalesInvoice> invoices) {
    final totalAmount = invoices.fold(
      0.0,
      (sum, invoice) => sum + invoice.totalAmount,
    );
    final totalItems = invoices.fold(
      0,
      (sum, invoice) => sum + invoice.items.length,
    );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Grand Total:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '${invoices.length} invoices • $totalItems items',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Sales Data',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sales invoices will appear here',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SalesBloc>().add(LoadSalesDataEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return BlocBuilder<SalesBloc, SalesState>(
            builder: (context, state) {
              if (state is SalesDataLoaded) {
                // Update customer list when state is loaded
                if (_customerNames.length == 1) {
                  // Only "All" is present
                  final customerSet = <String>{'All'};
                  for (var customer in state.customers) {
                    customerSet.add(customer['Name'] ?? 'Unknown');
                  }
                  _customerNames = customerSet.toList();
                }
              }

              return AlertDialog(
                title: const Text('Filter Report'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date Range
                      const Text(
                        'Date Range',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('From Date'),
                              subtitle: Text(_dateFormat.format(_fromDate)),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    _fromDate = date;
                                  });
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('To Date'),
                              subtitle: Text(_dateFormat.format(_toDate)),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    _toDate = date;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Customer Filter
                      const Text(
                        'Customer Filter',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // DropdownButtonFormField<String>(
                      //   value: _selectedCustomer,
                      //   items: _customerNames.map((customer) {
                      //     return DropdownMenuItem(
                      //       value: customer,
                      //       child: Text(customer),
                      //     );
                      //   }).toList(),
                      //   onChanged: (value) {
                      //     setDialogState(() {
                      //       _selectedCustomer = value!;
                      //     });
                      //   },
                      //   decoration: const InputDecoration(
                      //     border: OutlineInputBorder(),
                      //     hintText: 'Select Customer',
                      //   ),
                      // ),
                      DropdownButtonFormField<String>(
                        value: _selectedCustomer,
                        items: _customerNames.map((customer) {
                          return DropdownMenuItem(
                            value: customer,
                            child: Text(customer),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedCustomer = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Customer',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setDialogState(() {
                        _fromDate = DateTime.now().subtract(
                          const Duration(days: 30),
                        );
                        _toDate = DateTime.now();
                        _selectedCustomer = 'All';
                      });
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showInvoiceDetails(SalesInvoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice INV-${invoice.txnNo.toString().padLeft(5, '0')}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Invoice Header
              _buildInvoiceDetailRow(
                'Date',
                _dateFormat.format(invoice.txnDate),
              ),
              _buildInvoiceDetailRow(
                'Customer',
                _getCustomerName(
                  invoice.customerId,
                  context.read<SalesBloc>().state as SalesDataLoaded,
                ),
              ),
              _buildInvoiceDetailRow('Address', invoice.address),
              _buildInvoiceDetailRow(
                'Total Items',
                invoice.totalQty.toStringAsFixed(0),
              ),

              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Items List
              ...invoice.items
                  .map(
                    (item) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.productName ?? 'Unknown Product',
                              ),
                            ),
                            Text('${item.quantity} x \$${item.rate}'),
                            const SizedBox(width: 16),
                            Text(
                              '\$${item.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${invoice.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
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
  }

  Widget _buildInvoiceDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<SalesInvoice> _getFilteredInvoices(SalesDataLoaded state) {
    List<SalesInvoice> filteredInvoices = state.invoices;

    // Get invoices from state (you'll need to modify your BLoC to store invoices)
    // For now, we'll use a placeholder - you'll need to implement this based on your data structure
    // filteredInvoices = state.invoices;

    // Apply date filter
    filteredInvoices = filteredInvoices.where((invoice) {
      return invoice.txnDate.isAfter(
            _fromDate.subtract(const Duration(days: 1)),
          ) &&
          invoice.txnDate.isBefore(_toDate.add(const Duration(days: 1)));
    }).toList();

    // Apply customer filter
    if (_selectedCustomer != 'All') {
      filteredInvoices = filteredInvoices.where((invoice) {
        return _getCustomerName(invoice.customerId, state) == _selectedCustomer;
      }).toList();
    }

    return filteredInvoices;
  }

  String _getCustomerName(int customerId, SalesDataLoaded state) {
    try {
      final customer = state.customers.firstWhere(
        (customer) => customer['ID'] == customerId,
        orElse: () => {'Name': 'Unknown Customer'},
      );
      return customer['Name'] ?? 'Unknown Customer';
    } catch (e) {
      return 'Customer $customerId';
    }
  }
}
