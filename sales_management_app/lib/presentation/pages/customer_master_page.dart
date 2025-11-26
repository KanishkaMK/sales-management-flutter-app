import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management_app/domain/entities/customer.dart';
import 'package:sales_management_app/presentation/bloc/customer/customer_bloc.dart';
import 'package:sales_management_app/presentation/widgets/customer_form_dialog.dart';

class CustomerMasterPage extends StatefulWidget {
  const CustomerMasterPage({Key? key}) : super(key: key);

  @override
  State<CustomerMasterPage> createState() => _CustomerMasterPageState();
}

class _CustomerMasterPageState extends State<CustomerMasterPage> {
  @override
  void initState() {
    super.initState();
    // Load customers when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBloc>().add(LoadCustomersEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CustomerFormDialog(),
              );
            },
          ),
        ],
      ),
      body:  BlocListener<CustomerBloc, CustomerState>(
  listener: (context, state) {
    if (state is CustomerError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
    child:   BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CustomerLoaded) {
            final customers = state.customers;
            return _buildCustomerList(customers);
          } else if (state is CustomerError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('No customers found'));
        },
      ),
    ),);
  }

  Widget _buildCustomerList(List<Customer> customers) {
    if (customers.isEmpty) {
      return const Center(child: Text('No customers found'));
    }

    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(customer.name[0]),
            ),
            title: Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.address),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        customer.areaName ?? 'No Area',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        customer.categoryName ?? 'No Category',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[100],
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  showDialog(
                    context: context,
                    builder: (context) => CustomerFormDialog(customer: customer),
                  );
                } else if (value == 'delete') {
                  _showDeleteDialog(context, customer);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CustomerBloc>().add(DeleteCustomerEvent(customer.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}