import 'package:scanner/state/products/state.dart';

String selectCartAmount(ProductsState state) {
  final Map<String, Product> mappedProducts = {};

  final products = state.products.fold(mappedProducts, (v, p) => v..[p.id] = p);
  final cart = state.cart;

  return cart.fold<double>(
    0,
    (previousValue, itemId) {
      final element = products[itemId];
      if (element == null) {
        return previousValue;
      }
      return previousValue + double.parse(element.price);
    },
  ).toStringAsFixed(2);
}

String selectCartDescription(ProductsState state) {
  final Map<String, Product> mappedProducts = {};

  final products = state.products.fold(mappedProducts, (v, p) => v..[p.id] = p);
  final cart = state.cart;

  return cart.fold<String>(
    'Cart: ',
    (previousValue, itemId) {
      final element = products[itemId];
      if (element == null) {
        return previousValue;
      }
      return previousValue + element.name + ' ';
    },
  );
}
