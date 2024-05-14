import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/config/service.dart';
import 'package:scanner/services/nfc/service.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/services/web3/service.dart';
import 'package:scanner/services/web3/transfer_data.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/currency.dart';
import 'package:scanner/utils/qr.dart';

class ScanLogic extends WidgetsBindingObserver {
  final ScanState _state;
  final NFCService _nfc = NFCService();
  final PreferencesService _preferences = PreferencesService();

  final ConfigService _config = ConfigService();

  late Web3Service _web3;

  ScanLogic(BuildContext context) : _state = context.read<ScanState>();

  Future<void> init() async {
    try {
      _state.loadScanner();

      _web3 = Web3Service();

      final config = await _config.getConfig('wallet.pay.brussels');

      if (config.cards == null) {
        throw Exception('No cards');
      }

      if (config.erc4337.paymasterAddress == null) {
        throw Exception('No paymaster');
      }

      await _web3.init(
        config.node.url,
        config.erc4337.rpcUrl,
        config.indexer.url,
        config.erc4337.paymasterRPCUrl,
        config.erc4337.paymasterAddress!,
        config.cards!.cardFactoryAddress,
        config.erc4337.accountFactoryAddress,
        config.erc4337.entrypointAddress,
        config.token.address,
      );

      _state.setVendorAddress(_web3.account.hexEip55);

      listenToBalance();

      _state.setConfig(config);
      _state.scannerReady();
      return;
    } catch (_) {}

    _state.scannerNotReady();
  }

  void updateVendorBalance() async {
    try {
      final balance = await _web3.getBalance(_web3.account.hexEip55);

      final config = _state.config;
      if (config == null) {
        throw Exception('No config');
      }

      final formattedBalance = formatCurrency(
        double.tryParse(
              fromDoubleUnit(
                balance.toString(),
                decimals: config.token.decimals,
              ),
            ) ??
            0.0,
        '',
      );

      _state.setVendorBalance(formattedBalance);
    } catch (_) {}
  }

  void copyVendorAddress() {
    try {
      final vendorAddress = _web3.account.hexEip55;

      Clipboard.setData(ClipboardData(text: vendorAddress));
    } catch (_) {}
  }

  Future<String> redeem() async {
    try {
      stopListenToBalance();

      const amount = '0.1';

      _state.startPurchasing(amount);

      final config = _state.config;
      if (config == null) {
        throw Exception('No config');
      }

      final symbol = config.token.symbol;

      final serialNumber = await _nfc.readSerialNumber(
        message: 'Scan to redeem $symbol $amount',
        successMessage: 'Redeemed $symbol $amount',
      );

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      // final isRedeemed = _preferences.isRedeemed(address.hexEip55);
      // if (isRedeemed) {
      //   throw Exception('Already redeemed');
      // }

      // final balance = await _web3.getBalance(_web3.account.hexEip55);
      // if (balance == BigInt.zero) {
      //   throw Exception('Faucet empty');
      // }

      final calldata = _web3.erc20TransferCallData(
          address.hexEip55,
          toUnit(
            amount,
            decimals: config.token.decimals,
          ));

      final (_, userop) =
          await _web3.prepareUserop([_web3.tokenAddress.hexEip55], [calldata]);

      final data = TransferData(
        'Withdraw balance',
      );

      final txHash = await _web3.submitUserop(userop, data: data);
      if (txHash == null) {
        throw Exception('Failed to redeem');
      }

      if (userop.nonce == BigInt.zero) {
        final success = await _web3.waitForTxSuccess(txHash);

        if (!success) {
          throw Exception('Failed to redeem');
        }
      }

      _preferences.setRedeemed(address.hexEip55);

      _state.stopPurchasing();

      listenToBalance();
      return 'Redeemed $symbol $amount';
    } catch (e) {
      if (e is Exception) {
        _state.stopPurchasing();
        return e.toString().replaceFirst('Exception: ', '');
      }
    }

    _state.stopPurchasing();

    listenToBalance();

    return 'Failed to purchase';
  }

  Future<bool> withdraw(String value) async {
    try {
      final (address, _) = parseQRCode(value);
      if (address == '') {
        throw Exception('invalid address');
      }

      final balance = await _web3.getBalance(_web3.account.hexEip55);
      if (balance == BigInt.zero) {
        throw Exception('no balance');
      }

      final calldata = _web3.erc20TransferCallData(address, balance);

      final (_, userop) =
          await _web3.prepareUserop([_web3.tokenAddress.hexEip55], [calldata]);

      final data = TransferData(
        'Withdraw balance',
      );

      final txHash = await _web3.submitUserop(userop, data: data);
      if (txHash == null) {
        throw Exception('failed to withdraw');
      }

      final success = await _web3.waitForTxSuccess(txHash);

      return success;
    } catch (_) {}

    return false;
  }

  Future<String?> read({String? message, String? successMessage}) async {
    try {
      _state.setNfcAddressRequest();

      final serialNumber = await _nfc.readSerialNumber(
        message: message,
        successMessage: successMessage,
      );

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      final balance = await _web3.getBalance(address.hexEip55);

      _state.setNfcAddressSuccess(address.hexEip55);
      _state.setAddressBalance(fromUnit(balance, decimals: 6));

      return address.hexEip55;
    } catch (_) {
      _state.setNfcAddressError();
      _state.setAddressBalance(null);
    }

    return null;
  }

  Timer? _balanceTimer;

  Future<void> listenToBalance() async {
    try {
      stopListenToBalance();

      updateVendorBalance();

      _balanceTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        updateVendorBalance();
      });
    } catch (_) {
      _balanceTimer?.cancel();
      _balanceTimer = null;
    }
  }

  void stopListenToBalance() {
    _balanceTimer?.cancel();
    _balanceTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        listenToBalance();
        break;
      default:
        _balanceTimer?.cancel();
        _balanceTimer = null;
    }
  }
}
