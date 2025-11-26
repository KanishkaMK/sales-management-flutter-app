import 'package:flutter/material.dart';
import 'package:sales_management_app/domain/entities/sales_invoice.dart';

class ProductSelectionDialog extends StatefulWidget {
  final List<dynamic> products;
  final Function(InvoiceItem) onProductSelected;

  const ProductSelectionDialog({
    Key? key,
    required this.products,
    required this.onProductSelected,
  }) : super(key: key);

  @override
  State<ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog> {
  final _quantityController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');
  int? _selectedProductId;

  @override
  void initState() {
    super.initState();
    print('🔄 ProductSelectionDialog initialized with ${widget.products.length} products');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedProductId,
              decoration: const InputDecoration(
                labelText: 'Product *',
                border: OutlineInputBorder(),
              ),
              items: widget.products.map<DropdownMenuItem<int>>((product) {
                final productName = product['Name'] ?? 'Unknown';
                // Safely parse sales rate
                final salesRate = _parseDouble(product['SalesRate'] ?? 0.0);
                return DropdownMenuItem<int>(
                  value: product['ID'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName),
                      Text(
                        '\$${salesRate.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                print('🎯 Product selected: $value');
                setState(() {
                  _selectedProductId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a product';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            print('❌ Product selection cancelled');
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addProduct,
          child: const Text('Add'),
        ),
      ],
    );
  }

  // Helper method to safely parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  void _addProduct() {
  print('🔄 Add button pressed');
  print('🔍 Selected Product ID: $_selectedProductId');
  print('🔍 Quantity: ${_quantityController.text}');
  print('🔍 Discount: ${_discountController.text}');

  if (_selectedProductId == null) {
    print('❌ No product selected');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a product')),
    );
    return;
  }

  final quantity = double.tryParse(_quantityController.text) ?? 1;
  final discount = double.tryParse(_discountController.text) ?? 0;

  print('🔍 Parsed Quantity: $quantity');
  print('🔍 Parsed Discount: $discount');

  if (quantity <= 0) {
    print('❌ Invalid quantity: $quantity');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quantity must be greater than 0')),
    );
    return;
  }

  // Find selected product using loop (more explicit)
  dynamic selectedProduct;
  bool productFound = false;
  
  for (var product in widget.products) {
    if (product['ID'] == _selectedProductId) {
      selectedProduct = product;
      productFound = true;
      break;
    }
  }
  
  if (!productFound) {
    print('❌ Selected product not found in list');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected product not found')),
    );
    return;
  }

  final productName = selectedProduct['Name'] ?? 'Unknown';
  // Safely parse sales rate
  final rate = _parseDouble(selectedProduct['SalesRate'] ?? 0.0);

  print('✅ Creating InvoiceItem:');
  print('   - Product: $productName (ID: $_selectedProductId)');
  print('   - Rate: $rate');
  print('   - Quantity: $quantity');
  print('   - Discount: $discount');

  final invoiceItem = InvoiceItem(
    productId: _selectedProductId!,
    productName: productName,
    rate: rate,
    quantity: quantity,
    discount: discount,
  );

  print('🎯 Calling onProductSelected callback...');
  widget.onProductSelected(invoiceItem);
  print('✅ Callback completed, closing dialog');
  
  Navigator.pop(context);
}
}