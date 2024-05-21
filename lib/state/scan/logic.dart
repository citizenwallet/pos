import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:scanner/utils/random.dart';
import 'package:web3dart/web3dart.dart';

class ScanLogic extends WidgetsBindingObserver {
  final ScanState _state;
  final NFCService _nfc = NFCService();
  final PreferencesService _preferences = PreferencesService();

  final ConfigService _config = ConfigService();

  late Web3Service _web3;

  ScanLogic(BuildContext context) : _state = context.read<ScanState>();

  Future<void> init({String? alias}) async {
    try {
      _state.loadScanner();

      _web3 = Web3Service();

      String? selectedAlias = alias ?? _preferences.getLastAlias();
      if (selectedAlias == null) {
        final configs =
            (await _config.getConfigs()).where((c) => c.cards != null).toList();

        if (configs.isEmpty) {
          throw Exception('No configs');
        }

        selectedAlias = configs.first.community.alias;
      }

      final config = await _config.getConfig(selectedAlias);

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

      _state.setConfig(config);
      _state.setConfigs(await _config.getConfigs());

      final redeemAmount = _preferences.getRedeemAmount(config.token.address);

      _state.updateRedeemAmount(redeemAmount);
      updateVendorBalance();

      await _preferences.setLastAlias(selectedAlias);

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

  Future<void> updateRedeemBalance(EthereumAddress address,
      {int decimals = 6}) async {
    try {
      final balance = await _web3.getBalance(address.hexEip55);

      final formattedBalance = formatCurrency(
        double.tryParse(
              fromDoubleUnit(
                balance.toString(),
                decimals: decimals,
              ),
            ) ??
            0.0,
        '',
      );

      _state.setRedeemBalance(formattedBalance);
    } catch (_) {}
  }

  void updateRedeemAmount(String amount) {
    String cleanedAmount = amount.replaceAll(',', '.').trim();

    final parsedAmount = double.tryParse(cleanedAmount) ?? 0.0;
    if (parsedAmount < 0.0) {
      cleanedAmount = '0.0';
    }

    _preferences.setRedeemAmount(_state.config!.token.address, cleanedAmount);

    _state.updateRedeemAmount(cleanedAmount);
  }

  void copyVendorAddress() {
    try {
      final vendorAddress = _web3.account.hexEip55;

      Clipboard.setData(ClipboardData(text: vendorAddress));
    } catch (_) {}
  }

  Timer? resetStatusTimer;
  String runningRedeemAction = '';

  Future<void> redeem() async {
    try {
      final currentRedeemAction = generateRandomId();
      runningRedeemAction = currentRedeemAction;

      resetStatusTimer?.cancel();

      final config = _state.config;
      if (config == null) {
        throw Exception('No config');
      }

      final amount = _preferences.getRedeemAmount(config.token.address);

      if (runningRedeemAction == currentRedeemAction) {
        _state.updateStatus(ScanStateType.readingNFC);
      }

      final symbol = config.token.symbol;

      _state.setNfcReading(true);

      final serialNumber = await _nfc.readSerialNumber(
        message: 'Scan to redeem $symbol $amount',
        successMessage: 'Redeemed $symbol $amount',
      );

      _state.setNfcReading(false);

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      // final isRedeemed = _preferences.isRedeemed(address.hexEip55);
      // if (isRedeemed) {
      //   throw Exception('Already redeemed');
      // }

      await updateRedeemBalance(address, decimals: config.token.decimals);

      final calldata = _web3.erc20TransferCallData(
          address.hexEip55,
          toUnit(
            amount,
            decimals: config.token.decimals,
          ));

      if (runningRedeemAction == currentRedeemAction) {
        _state.updateStatus(ScanStateType.redeeming);
      }

      final (_, userop) =
          await _web3.prepareUserop([_web3.tokenAddress.hexEip55], [calldata]);

      final data = TransferData(
        'Withdraw balance',
      );

      final txHash = await _web3.submitUserop(userop, data: data);
      if (txHash == null) {
        throw Exception('Failed to redeem');
      }

      if (runningRedeemAction == currentRedeemAction) {
        _state.updateStatus(ScanStateType.verifying);
      }

      final success = await _web3.waitForTxSuccess(txHash);

      if (!success) {
        throw Exception('Failed to redeem');
      }

      if (runningRedeemAction == currentRedeemAction) {
        _state.updateStatus(ScanStateType.verified);
      }

      await updateRedeemBalance(address, decimals: config.token.decimals);
      updateVendorBalance();

      _preferences.setRedeemed(address.hexEip55);

      resetStatusTimer?.cancel();
      resetStatusTimer = Timer(const Duration(seconds: 5), () {
        _state.updateStatus(ScanStateType.ready);
      });

      runningRedeemAction = '';
      return;
    } catch (e) {
      resetStatusTimer?.cancel();
      resetStatusTimer = Timer(const Duration(seconds: 5), () {
        _state.updateStatus(ScanStateType.ready);
      });

      if (e is Exception) {
        _state.setRedeemBalance('0.00');

        _state.setStatusError(
            ScanStateType.error, e.toString().replaceFirst('Exception: ', ''));

        runningRedeemAction = '';
        return;
      }
    }

    _state.setRedeemBalance('0.00');

    _state.setStatusError(
        ScanStateType.error, 'Failed to redeem. Please try again.');

    runningRedeemAction = '';
    return;
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

      _state.setNfcReading(true);

      final serialNumber = await _nfc.readSerialNumber(
        message: message,
        successMessage: successMessage,
      );

      _state.setNfcReading(false);

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      final balance = await _web3.getBalance(address.hexEip55);

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

      _state.setNfcAddressSuccess(address.hexEip55);
      _state.setAddressBalance(formattedBalance);

      return address.hexEip55;
    } catch (_) {
      _state.setNfcAddressError();
      _state.setAddressBalance(null);
      _state.setNfcReading(false);
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
      stopListenToBalance();
    }
  }

  void stopListenToBalance() {
    _balanceTimer?.cancel();
    _balanceTimer = null;
  }

  void cancelScan() {
    _nfc.stop();
    _state.setNfcReading(false);
  }

  bool wasRunning = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (wasRunning) {
          listenToBalance();
          wasRunning = false;
        }
        break;
      default:
        if (_balanceTimer != null) {
          wasRunning = true;
        }

        _balanceTimer?.cancel();
        _balanceTimer = null;
    }
  }
}
