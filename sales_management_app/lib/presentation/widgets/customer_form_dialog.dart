import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management_app/domain/entities/customer.dart';
import 'package:sales_management_app/presentation/bloc/customer/customer_bloc.dart';

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;

  const CustomerFormDialog({Key? key, this.customer}) : super(key: key);

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  int? _selectedAreaId;
  int? _selectedCategoryId;

  List<dynamic> _areas = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize form fields if editing existing customer
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _addressController.text = widget.customer!.address;
      _selectedAreaId = widget.customer!.areaId;
      _selectedCategoryId = widget.customer!.categoryId;
    }
    
    // Load dropdown data
    _loadDropdowns();
  }

  void _loadDropdowns() {
    print('🔄 Loading dropdowns...');
    context.read<CustomerBloc>().add(LoadDropdownsEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        print('🎯 Customer State in Dialog: ${state.runtimeType}');
      
      //  specific debugging for dropdowns
      if (state is CustomerLoaded) {
        print('📦 CustomerLoaded state detected');
        print('📊 Has dropdowns: ${state.dropdowns != null}');
        if (state.dropdowns != null) {
          print('📍 Areas count: ${state.dropdowns!['areas']?.length}');
          print('📍 Categories count: ${state.dropdowns!['categories']?.length}');
        }
      }
        
        if (state is CustomerLoaded && state.dropdowns != null) {
          print('✅ Dropdowns received: ${state.dropdowns}');
          setState(() {
            _areas = state.dropdowns!['areas'] ?? [];
            _categories = state.dropdowns!['categories'] ?? [];
            _isLoading = false;
            
            print('📊 Areas: ${_areas.length}, Categories: ${_categories.length}');
            
            // Set initial values for dropdowns if not set
            if (widget.customer != null) {
              _selectedAreaId ??= widget.customer!.areaId;
              _selectedCategoryId ??= widget.customer!.categoryId;
            } else {
              // Set default values for new customer
              _selectedAreaId ??= _areas.isNotEmpty ? _areas[0]['ID'] : null;
              _selectedCategoryId ??= _categories.isNotEmpty ? _categories[0]['ID'] : null;
            }
          });
        }
        
        if (state is CustomerOperationSuccess) {
          print('✅ Operation success: ${state.message}');
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        
        if (state is CustomerError) {
          print('❌ Error: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          // Even on error, stop loading to show the form
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: AlertDialog(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
        content: _buildContent(),
        actions: _buildActions(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading dropdown data...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildAreaDropdown(),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            if (_areas.isEmpty || _categories.isEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[800], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dropdown data not available. Please check backend connection.',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAreaDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedAreaId,
      decoration: const InputDecoration(
        labelText: 'Area *',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: _buildAreaItems(),
      onChanged: _areas.isEmpty ? null : (value) {
        setState(() {
          _selectedAreaId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select area';
        }
        return null;
      },
    );
  }

  List<DropdownMenuItem<int>> _buildAreaItems() {
    if (_areas.isEmpty) {
      return [
        const DropdownMenuItem(
          value: 0,
          child: Text('No areas available', style: TextStyle(color: Colors.grey)),
        )
      ];
    }

    return _areas.map<DropdownMenuItem<int>>((area) {
      return DropdownMenuItem<int>(
        value: area['ID'],
        child: Text(area['Name']?.toString() ?? 'Unknown Area'),
      );
    }).toList();
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: _buildCategoryItems(),
      onChanged: _categories.isEmpty ? null : (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select category';
        }
        return null;
      },
    );
  }

  List<DropdownMenuItem<int>> _buildCategoryItems() {
    if (_categories.isEmpty) {
      return [
        const DropdownMenuItem(
          value: 0,
          child: Text('No categories available', style: TextStyle(color: Colors.grey)),
        )
      ];
    }

    return _categories.map<DropdownMenuItem<int>>((category) {
      return DropdownMenuItem<int>(
        value: category['ID'],
        child: Text(category['Name']?.toString() ?? 'Unknown Category'),
      );
    }).toList();
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _saveCustomer,
        child: const Text('Save'),
      ),
    ];
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      if (_selectedAreaId == null || _selectedAreaId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select area')),
        );
        return;
      }

      if (_selectedCategoryId == null || _selectedCategoryId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select category')),
        );
        return;
      }

      final customer = Customer(
        id: widget.customer?.id ?? 0,
        name: _nameController.text,
        address: _addressController.text,
        areaId: _selectedAreaId!,
        categoryId: _selectedCategoryId!,
      );

      print('💾 Saving customer: ${customer.toJson()}');

      if (widget.customer == null) {
        context.read<CustomerBloc>().add(AddCustomerEvent(customer));
      } else {
        context.read<CustomerBloc>().add(UpdateCustomerEvent(customer));
      }
    }
  }
}