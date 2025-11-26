import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sales_management_app/domain/entities/product.dart';
import 'package:sales_management_app/domain/repositories/product_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;

  ProductBloc({required this.productRepository}) : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<AddProductEvent>(_onAddProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<LoadProductDropdownsEvent>(_onLoadDropdowns);
  }

  void _onLoadProducts(LoadProductsEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await productRepository.getProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onAddProduct(AddProductEvent event, Emitter<ProductState> emit) async {
    try {
      await productRepository.createProduct(event.product);
      final products = await productRepository.getProducts();
      emit(ProductLoaded(products));
      emit(ProductOperationSuccess('Product added successfully'));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onUpdateProduct(UpdateProductEvent event, Emitter<ProductState> emit) async {
    try {
      await productRepository.updateProduct(event.product);
      final products = await productRepository.getProducts();
      emit(ProductLoaded(products));
      emit(ProductOperationSuccess('Product updated successfully'));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onDeleteProduct(DeleteProductEvent event, Emitter<ProductState> emit) async {
    try {
      await productRepository.deleteProduct(event.productId);
      final products = await productRepository.getProducts();
      emit(ProductLoaded(products));
      emit(ProductOperationSuccess('Product deleted successfully'));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onLoadDropdowns(LoadProductDropdownsEvent event, Emitter<ProductState> emit) async {
    try {
      final dropdowns = await productRepository.getProductDropdowns();
      if (state is ProductLoaded) {
        final currentState = state as ProductLoaded;
        emit(ProductLoaded(currentState.products, dropdowns: dropdowns));
      }
    } catch (e) {
      // Don't emit error for dropdowns
    }
  }
}