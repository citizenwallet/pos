import 'dart:async';

import 'package:flutter/services.dart';
import 'package:scanner/services/nfc/service.dart';

class CPayNFCService implements NFCService {
  static const platform = MethodChannel('xyz.citizenwallet.faucet/nfc');

  Timer? _timer;

  @override
  NFCScannerDirection get direction => NFCScannerDirection.top;

  @override
  Future<void> printReceipt(
      {String? amount = '0.00',
      String? symbol = 'ETH',
      String? description = '',
      String? link = 'https://citizenwallet.xyz'}) async {
    await platform.invokeMethod('print', <String, dynamic>{
      'amount': amount,
      'symbol': symbol,
      'description': description,
      'link': link,
    });
  }

  @override
  Future<String> readSerialNumber(
      {String? message, String? successMessage}) async {
    final completer = Completer<String>();

    // interval
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final bool tagIsTouching = await platform.invokeMethod('exists');
      if (!tagIsTouching) {
        return;
      }

      final String result = await platform.invokeMethod('read');
      if (result == 'error' || result.isEmpty) {
        timer.cancel();
        if (completer.isCompleted) return;
        completer.completeError('Invalid tag');
        return;
      }

      timer.cancel();
      if (completer.isCompleted) return;
      completer.complete(result);
    });

    return completer.future;
  }

  @override
  Future<void> stop() async {
    // await NfcManager.instance.stopSession();
    _timer?.cancel();
  }
}
