import 'package:flutter/services.dart';

class AmountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    final r = RegExp("^\\d+([\\.\\,]\\d{0,2})?\$");

    if (!r.hasMatch(text)) {
      return oldValue;
    }

    return newValue;
  }
}

String cleanNameString(String name) {
  RegExp pattern = RegExp(r"[a-zA-Z\-'\u00C0-\u00FF ]");
  return name.splitMapJoin(pattern,
      onMatch: (m) => m.group(0)!, // Keep the character if it matches
      onNonMatch: (n) => '' // Remove the character if it doesn't match
      );
}
