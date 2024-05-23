import 'package:flutter/material.dart';

enum AppMode {
  faucet('Faucet-only mode'),
  pos('POS-only mode'),
  unlocked('Unlocked'),
  locked('Locked');

  const AppMode(this.label);

  final String label;
}

class AppState with ChangeNotifier {
  AppMode mode = AppMode.locked;

  void setMode(AppMode mode) {
    this.mode = mode;
    notifyListeners();
  }
}
