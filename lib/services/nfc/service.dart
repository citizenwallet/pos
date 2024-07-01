import 'dart:async';

enum NFCScannerDirection { top, right, bottom, left }

abstract class NFCService {
  NFCScannerDirection get direction;

  Future<String> readSerialNumber({String? message, String? successMessage});

  Future<void> stop();
}
