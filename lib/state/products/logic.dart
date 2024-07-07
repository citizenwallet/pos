import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/state/products/state.dart';

class ProductsLogic {
  final ProductsState _state;
  String token;

  final PreferencesService _prefs = PreferencesService();

  ProductsLogic(
    BuildContext context,
    this.token,
  ) : _state = context.read<ProductsState>();

  updateToken(String token) {
    this.token = token;

    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      _state.clearProducts();

      final stringProducts = _prefs.getProducts(token);
      if (stringProducts == null) {
        return;
      }

      final parsedProducts = jsonDecode(stringProducts);

      final products = List<Product>.from(
        parsedProducts.map((product) => Product.fromJson(product)),
      );

      _state.replaceProducts(products);
    } catch (_) {}
  }

  void addProduct() {
    try {
      _state.addProduct();

      saveProducts();
    } catch (_) {}
  }

  void removeProduct(String id) {
    try {
      _state.removeProduct(id);

      saveProducts();
    } catch (_) {}
  }

  void updateProduct(Product product) {
    try {
      _state.updateProduct(product);

      saveProducts();
    } catch (_) {}
  }

  void clearProducts() {
    try {
      _state.clearProducts();

      saveProducts();
    } catch (_) {}
  }

  void clearForm() {
    try {
      _state.clearForm();
    } catch (_) {}
  }

  void saveProducts() {
    final products = _state.products;

    _prefs.setProducts(token, jsonEncode(products));
  }

  void addToCart(String id) {
    try {
      _state.addToCart(id);
    } catch (_) {}
  }

  void removeFromCart(String id) {
    try {
      _state.removeFromCart(id);
    } catch (_) {}
  }
}
