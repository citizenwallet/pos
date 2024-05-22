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
}

class ProductsState with ChangeNotifier {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  List<Product> products = [];

  void replaceProducts(List<Product> newProducts) {
    products = newProducts;
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
}
