import 'dart:async';

import 'package:flutter/services.dart';
import 'package:scanner/services/nfc/service.dart';

class CPayNFCService implements NFCService {
  static const platform = MethodChannel('xyz.citizenwallet.faucet/nfc');

  Timer? _timer;

  @override
  NFCScannerDirection get direction => NFCScannerDirection.top;

  @override
  Future<String> readSerialNumber(
      {String? message, String? successMessage}) async {
    // Check availability
    // bool isAvailable = await NfcManager.instance.isAvailable();

    // if (!isAvailable) {
    //   throw Exception('NFC is not available');
    // }

    final completer = Completer<String>();

    // interval
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      print('tick');
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
      await platform.invokeMethod('print');
      completer.complete(result);
    });

    // NfcManager.instance.startSession(
    //   alertMessage: message ?? 'Scan to confirm',
    //   pollingOptions: {
    //     NfcPollingOption.iso14443,
    //     NfcPollingOption.iso15693,
    //     NfcPollingOption.iso18092,
    //   },
    //   onDiscovered: (NfcTag tag) async {
    //     final nfcMetaData = tag.data['mifare'] ?? tag.data['nfca'];
    //     if (nfcMetaData == null) {
    //       if (completer.isCompleted) return;
    //       completer.completeError('Invalid tag');
    //       return;
    //     }
    //     final List<int>? identifier = nfcMetaData['identifier'];
    //     if (identifier == null) {
    //       if (completer.isCompleted) return;
    //       completer.completeError('Invalid tag');
    //       return;
    //     }

    //     String uid = identifier
    //         .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    //         .join();

    //     if (completer.isCompleted) return;
    //     completer.complete(uid);

    //     await NfcManager.instance
    //         .stopSession(alertMessage: successMessage ?? 'Confirmed');
    //   },
    //   onError: (error) async {
    //     print(error);
    //     if (completer.isCompleted) return;
    //     completer.completeError(error); // Complete the Future with the error
    //   },
    // );

    // return completer.future;
    return completer.future;
  }

  @override
  Future<void> stop() async {
    // await NfcManager.instance.stopSession();
    _timer?.cancel();
  }
}
