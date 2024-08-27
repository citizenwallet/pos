import 'package:flutter/foundation.dart';

Uint8List convertStringToUint8List(String str, {int? forcePadLength}) {
  final List<int> codeUnits =
      (forcePadLength == null ? str : str.padLeft(forcePadLength)).codeUnits;
  return Uint8List.fromList(codeUnits);
}

List<int> convertStringToListInt(String str) {
  final List<int> codeUnits = str.codeUnits;
  return codeUnits;
}

String convertUint8ListToString(Uint8List uint8list) {
  return String.fromCharCodes(uint8list);
}

String convertLinstInListToString(List<int> uint8list) {
  return String.fromCharCodes(uint8list);
}

Uint8List convertBytesToUint8List(List<int> bytes) {
  return Uint8List.fromList(bytes);
}

List<int> convertUint8ListToBytes(Uint8List bytes) {
  return bytes.toList();
}

Uint8List convertBigIntToUint8List(BigInt value) {
  // Convert BigInt to hexadecimal string
  String hexString = value.toRadixString(16);

  // Ensure even length by padding with '0' if necessary
  if (hexString.length % 2 != 0) {
    hexString = '0$hexString';
  }

  // Convert hex string to Uint8List
  List<int> bytes = [];
  for (int i = 0; i < hexString.length; i += 2) {
    bytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
  }

  return Uint8List.fromList(bytes);
}
