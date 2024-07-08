import 'package:flutter/material.dart';

class Reward {
  final String id;
  final String name;
  final String price;
  final String image;

  const Reward({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  // from json
  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
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

class RewardsState with ChangeNotifier {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  List<Reward> rewards = [];

  void replaceRewards(List<Reward> newRewards) {
    rewards = [...newRewards];
    notifyListeners();
  }

  void addReward() {
    final product = Reward(
      id: DateTime.now().toString(),
      name: nameController.text,
      price: priceController.text.replaceAll(",", "."),
      image: 'assets/product.png',
    );

    rewards.add(product);

    nameController.clear();
    priceController.clear();
    notifyListeners();
  }

  void removeReward(String id) {
    rewards.removeWhere((element) => element.id == id);
    cart.removeWhere((element) => element == id);
    notifyListeners();
  }

  void updateReward(Reward product) {
    final index = rewards.indexWhere((element) => element.id == product.id);
    rewards[index] = product;
    notifyListeners();
  }

  void clearRewards() {
    rewards.clear();
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
