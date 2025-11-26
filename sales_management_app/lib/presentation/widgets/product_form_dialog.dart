import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sales_management_app/data/repositories/product_repository_impl.dart';
import 'package:sales_management_app/domain/entities/product.dart';
import 'package:sales_management_app/presentation/bloc/product/product_bloc.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purchaseRateController = TextEditingController();
  final _salesRateController = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedBrandId;
  
  List<dynamic> _categories = [];
  List<dynamic> _brands = [];
  bool _isLoading = true;

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _purchaseRateController.text = widget.product!.purchaseRate.toString();
      _salesRateController.text = widget.product!.salesRate.toString();
      _selectedCategoryId = widget.product!.categoryId;
      _selectedBrandId = widget.product!.brandId;
    }
    
    _loadDropdownsDirectly();
  }

  void _loadDropdownsDirectly() async {
    try {
      final repository = RepositoryProvider.of<ProductRepositoryImpl>(context);
      final dropdowns = await repository.getProductDropdowns();
      
      setState(() {
        _categories = dropdowns['categories'] ?? [];
        _brands = dropdowns['brands'] ?? [];
        _isLoading = false;
        
        // Set defaults if not set
        if (widget.product == null) {
          _selectedCategoryId = _categories.isNotEmpty ? _categories[0]['ID'] : null;
          _selectedBrandId = _brands.isNotEmpty ? _brands[0]['ID'] : null;
        }
      });
    } catch (e) {
      print('Error loading product dropdowns: $e');
      setState(() {
        _isLoading = false;
        // Use demo data
        _categories = [
          {'ID': 1, 'Name': 'Electronics'},
          {'ID': 2, 'Name': 'Clothing'},
          {'ID': 3, 'Name': 'Food'},
          {'ID': 4, 'Name': 'Books'},
        ];
        _brands = [
          {'ID': 1, 'Name': 'Samsung'},
          {'ID': 2, 'Name': 'Nike'},
          {'ID': 3, 'Name': 'Apple'},
          {'ID': 4, 'Name': 'Adidas'},
        ];
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xfile) => File(xfile.path)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImagePreview() {
    if (_selectedImages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No images selected', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Images" to select product photos',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Images (${_selectedImages.length})', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_selectedImages.length, (index) {
            return Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: DecorationImage(
                      image: FileImage(_selectedImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: IconButton(
                    icon: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                    onPressed: () => _removeImage(index),
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  


  
Future<void> _uploadImagesAndSaveProduct(Product product) async {
  if (_selectedImages.isEmpty) {
    // No images to upload, just save the product with empty imagePaths
    final productToSave = product.copyWith(imagePaths: []);
    if (widget.product == null) {
      context.read<ProductBloc>().add(AddProductEvent(productToSave));
    } else {
      context.read<ProductBloc>().add(UpdateProductEvent(productToSave));
    }
    Navigator.pop(context);
    return;
  }

  setState(() {
    _isUploadingImages = true;
  });

  try {
    final repository = RepositoryProvider.of<ProductRepositoryImpl>(context);
    final uploadedImagePaths = await repository.uploadProductImages(_selectedImages);
    
    // Create product with image paths
    final productWithImages = product.copyWith(imagePaths: uploadedImagePaths);
    
    if (widget.product == null) {
      context.read<ProductBloc>().add(AddProductEvent(productWithImages));
    } else {
      context.read<ProductBloc>().add(UpdateProductEvent(productWithImages));
    }
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product saved with ${uploadedImagePaths.length} images!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error uploading images: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isUploadingImages = false;
    });
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _purchaseRateController.dispose();
    _salesRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: _buildContent(),
      actions: [
        TextButton(
          onPressed: _isLoading || _isUploadingImages ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || _isUploadingImages) ? null : _saveProduct,
          child: _isUploadingImages 
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading...'),
                  ],
                )
              : const Text('Save'),
        ),
      ],
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
                'Loading product data...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image upload section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Images', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildImagePreview(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),

          // Product form
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _categories.map<DropdownMenuItem<int>>((category) {
                    return DropdownMenuItem<int>(
                      value: category['ID'],
                      child: Text(category['Name']?.toString() ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (value) {
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
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedBrandId,
                  decoration: const InputDecoration(
                    labelText: 'Brand *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _brands.map<DropdownMenuItem<int>>((brand) {
                    return DropdownMenuItem<int>(
                      value: brand['ID'],
                      child: Text(brand['Name']?.toString() ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBrandId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select brand';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purchaseRateController,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Rate *',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter purchase rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _salesRateController,
                  decoration: const InputDecoration(
                    labelText: 'Sales Rate *',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter sales rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select category')),
        );
        return;
      }

      if (_selectedBrandId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select brand')),
        );
        return;
      }

      final product = Product(
        id: widget.product?.id ?? 0,
        name: _nameController.text,
        categoryId: _selectedCategoryId!,
        brandId: _selectedBrandId!,
        purchaseRate: double.parse(_purchaseRateController.text),
        salesRate: double.parse(_salesRateController.text),
        imagePaths: const [], // Will be updated with uploaded images
      );

      _uploadImagesAndSaveProduct(product);
    }
  }
}