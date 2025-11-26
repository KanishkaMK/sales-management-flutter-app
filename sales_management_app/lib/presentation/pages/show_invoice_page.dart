import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management_app/presentation/bloc/sales/sales_bloc.dart';

class ShowInvoicePage extends StatefulWidget {
  const ShowInvoicePage({Key? key}) : super(key: key);

  @override
  State<ShowInvoicePage> createState() => _ShowInvoicePageState();
}

class _ShowInvoicePageState extends State<ShowInvoicePage> {
  @override
  void initState() {
    super.initState();
    // Load invoices when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesBloc>().add(LoadSalesDataEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SalesBloc>().add(LoadSalesDataEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          if (state is SalesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SalesDataLoaded) {
            return _buildShowInvoicePage(state);
          } else if (state is SalesError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('No sales data available'));
        },
      ),
    );
  }

  Widget _buildShowInvoicePage(SalesDataLoaded state) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Sales Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('This page will show all sales invoices'),
          SizedBox(height: 16),
          Text('Check the backend console and database for now'),
        ],
      ),
    );
  }
}