import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management_app/data/datasources/api_client.dart';
import 'package:sales_management_app/domain/entities/product.dart';
import 'package:sales_management_app/presentation/bloc/product/product_bloc.dart';
import 'package:sales_management_app/presentation/widgets/product_form_dialog.dart';

class ProductMasterPage extends StatefulWidget {
  const ProductMasterPage({Key? key}) : super(key: key);

  @override
  State<ProductMasterPage> createState() => _ProductMasterPageState();
}

class _ProductMasterPageState extends State<ProductMasterPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(LoadProductsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ProductFormDialog(),
              );
            },
          ),
        ],
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is ProductOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductLoaded) {
              final products = state.products;
              return _buildProductList(products);
            } else if (state is ProductError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('No products found'));
          },
        ),
      ),
    );
  }

 

  Widget _buildProductList(List<Product> products) {
  if (products.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Products Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text('Tap the + button to add your first product'),
        ],
      ),
    );
  }

  return ListView.builder(
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index];
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _buildProductImage(product), // Use the new method
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      product.categoryName ?? 'No Category',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.orange[100],
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      product.brandName ?? 'No Brand',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue[100],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Purchase: \$${product.purchaseRate.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Sales: \$${product.salesRate.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Show image count if available
              if (product.imagePaths.isNotEmpty)
                Text(
                  '${product.imagePaths.length} image(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  builder: (context) => ProductFormDialog(product: product),
                );
              } else if (value == 'delete') {
                _showDeleteDialog(context, product);
              }
            },
          ),
        ),
      );
    },
  );
}

//  method to build product image widget
Widget _buildProductImage(Product product) {
  if (product.imagePaths.isNotEmpty) {
    // Display first image
    return CircleAvatar(
      backgroundImage: NetworkImage(
        '${ApiClient.baseUrl}/${product.imagePaths.first}',
      ),
      radius: 24,
      onBackgroundImageError: (exception, stackTrace) {
        // Fallback if image fails to load
        print('Image load error: $exception');
      },
    );
  } else {
    return CircleAvatar(
      backgroundColor: Colors.green[100],
      child: const Icon(Icons.inventory_2, color: Colors.green),
    );
  }
}

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProductEvent(product.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}