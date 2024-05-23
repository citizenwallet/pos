import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String price;
  final String image;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  // from json
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      image: json['image'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
    };
  }
}

class ProductsState with ChangeNotifier {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  List<Product> products = [];

  void replaceProducts(List<Product> newProducts) {
    products = [...newProducts];
    notifyListeners();
  }

  void addProduct() {
    final product = Product(
      id: DateTime.now().toString(),
      name: nameController.text,
      price: priceController.text.replaceAll(",", "."),
      image: 'assets/product.png',
    );

    products.add(product);

    nameController.clear();
    priceController.clear();
    notifyListeners();
  }

  void removeProduct(String id) {
    products.removeWhere((element) => element.id == id);
    cart.removeWhere((element) => element == id);
    notifyListeners();
  }

  void updateProduct(Product product) {
    final index = products.indexWhere((element) => element.id == product.id);
    products[index] = product;
    notifyListeners();
  }

  void clearProducts() {
    products.clear();
    notifyListeners();
  }

  void clearForm() {
    nameController.clear();
    priceController.clear();
  }

  List<String> cart = [];

  void addToCart(String id) {
    cart.add(id);
    notifyListeners();
  }

  void removeFromCart(String id) {
    int index = cart.indexOf(id);
    if (index != -1) {
      cart.removeAt(index);
    }
    notifyListeners();
  }
}
