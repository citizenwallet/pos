import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  Future<String> readSerialNumber(
      {String? message, String? successMessage}) async {
    // Check availability
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      throw Exception('NFC is not available');
    }

    final completer = Completer<String>();

    NfcManager.instance.startSession(
      alertMessage: message ?? 'Scan to confirm',
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        final nfcMetaData = tag.data['mifare'] ?? tag.data['nfca'];
        if (nfcMetaData == null) {
          if (completer.isCompleted) return;
          completer.completeError('Invalid tag');
          return;
        }
        final List<int>? identifier = nfcMetaData['identifier'];
        if (identifier == null) {
          if (completer.isCompleted) return;
          completer.completeError('Invalid tag');
          return;
        }

        String uid = identifier
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join();

        if (completer.isCompleted) return;
        completer.complete(uid);

        await NfcManager.instance
            .stopSession(alertMessage: successMessage ?? 'Confirmed');
      },
      onError: (error) async {
        if (completer.isCompleted) return;
        completer.completeError(error); // Complete the Future with the error
      },
    );

    return completer.future;
  }

  Future<void> stop() async {
    await NfcManager.instance.stopSession();
  }
}
