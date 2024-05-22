import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/amount/state.dart';

class AmountLogic {
  final AmountState _state;

  AmountLogic(BuildContext context) : _state = context.read<AmountState>();

  void clear() {
    _state.clearInputs();
  }

  void keyPress(String key) {
    if (key == '⌫') {
      _state.deleteKey();
    } else if (key == '.') {
      // Ignore '.' key, we are handling decimals internally
    } else {
      _state.normalKey(key);
    }
  }
}
