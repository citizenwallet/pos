import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/config/config.dart';
import 'package:scanner/services/config/service.dart';
import 'package:scanner/services/nfc/default.dart';
import 'package:scanner/services/nfc/service.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/services/web3/service.dart';
import 'package:scanner/services/web3/transfer_data.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/profile/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/currency.dart';
import 'package:scanner/utils/qr.dart';
import 'package:scanner/utils/random.dart';
import 'package:web3dart/web3dart.dart';

class ScanLogic extends WidgetsBindingObserver {
  static final ScanLogic _instance = ScanLogic._internal();

  factory ScanLogic() {
    return _instance;
  }

  ScanLogic._internal();

  late ScanState _state;
  late ProfileLogic _profileLogic;
  // final NFCService _nfc = CPayNFCService();
  final NFCService _nfc = DefaultNFCService();
  final PreferencesService _preferences = PreferencesService();

  final ConfigService _config = ConfigService();

  late Web3Service _web3;

  void init(BuildContext context) {
    _state = context.read<ScanState>();
    _profileLogic = ProfileLogic(context);
  }

  Future<Config?> load({String? alias, bool filtered = true}) async {
    try {
      _state.loadScanner();

      _state.scannerDirection = _nfc.direction;

      _web3 = Web3Service();

      bool defaultAliasFilter(Config c) {
        return c.cards != null;
      }
      List<String> activeAliases = _preferences.getActiveAliases();
      String? selectedAlias = alias ?? _preferences.getLastAlias();
      List<Config> configs;
      if (filtered) {
        if (activeAliases.isEmpty) {
          configs = 
            (await _config.getConfigs()).where((c) => defaultAliasFilter(c)).toList();
          activeAliases = configs.map((c) => c.community.alias).toList();
          _preferences.setActiveAliases(activeAliases);
        } else {
          configs =
            (await _config.getConfigs()).where((c) => activeAliases.contains(c.community.alias)).toList();
        }
        _state.setActiveAliases(activeAliases);
        if (selectedAlias == null || !activeAliases.contains(selectedAlias!)) {
          selectedAlias = configs.first.community.alias;
        }
      } else {
        configs = await _config.getConfigs();
        selectedAlias ??= configs.first.community.alias;
      }
      if (configs.isEmpty) {
         throw Exception('No active configs');
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
        config.ipfs.url,
        config.erc4337.rpcUrl,
        config.indexer.url,
        config.indexer.ipfsUrl,
        config.erc4337.paymasterRPCUrl,
        config.erc4337.paymasterAddress!,
        config.cards!.cardFactoryAddress,
        config.erc4337.accountFactoryAddress,
        config.erc4337.entrypointAddress,
        config.token.address,
        config.profile.address,
      );

      _profileLogic.resetAll();

      _state.setVendorAddress(_web3.account.hexEip55);

      _profileLogic.loadProfile(account: _web3.account.hexEip55);

      _state.setConfig(config);
      _state.setConfigs(await _config.getConfigs());

      final redeemAmount = _preferences.getRedeemAmount(config.token.address);

      _state.updateRedeemAmount(redeemAmount);
      updateVendorBalance();

      await _preferences.setLastAlias(selectedAlias);

      _state.scannerReady();
      return config;
    } catch (_) {}

    _state.scannerNotReady();

    return null;
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

  Future<String?> readTag({
    String message = 'Scan',
    String successMessage = 'Scanned successfully',
  }) async {
    try {
      _state.setNfcReading(true);

      final serialNumber = await _nfc.readSerialNumber(
        message: message,
        successMessage: successMessage,
      );

      _state.setNfcReading(false);

      return serialNumber;
    } catch (_) {}

    _state.setNfcReading(false);
    return null;
  }

  Timer? resetStatusTimer;
  String runningRedeemAction = '';

  Future<void> redeem(
    String serialNumber,
    String amount, {
    String? description,
  }) async {
    try {
      _profileLogic.resetAll();

      final currentRedeemAction = generateRandomId();
      runningRedeemAction = currentRedeemAction;

      resetStatusTimer?.cancel();

      final config = _state.config;
      if (config == null) {
        throw Exception('No config');
      }

      // final amount = _preferences.getRedeemAmount(config.token.address);

      if (runningRedeemAction == currentRedeemAction) {
        _state.updateStatus(ScanStateType.readingNFC);
      }

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      _profileLogic.loadProfile(account: address.hexEip55);

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
        description ?? 'Redeem',
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

  Future<String> purchase(String serialNumber, String amount,
      {String? description}) async {
    try {
      _state.updateStatus(ScanStateType.readingNFC);

      final config = _state.config;
      if (config == null) {
        throw Exception('No config');
      }

      final symbol = config.token.symbol;
      final decimals = config.token.decimals;

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      final balance = await _web3.getBalance(address.hexEip55);
      if (balance == BigInt.zero) {
        throw Exception('Insufficient balance');
      }

      final bigAmount = toUnit(amount, decimals: decimals);
      if (bigAmount > balance) {
        final currentBalance = fromUnit(
          balance,
          decimals: decimals,
        );
        throw Exception('Cost: $amount, Balance: $currentBalance');
      }

      final withdrawCallData = _web3.withdrawCallData(
        cardHash,
        toUnit(amount, decimals: decimals),
      );

      _state.updateStatus(ScanStateType.redeeming);

      final (_, userop) = await _web3.prepareUserop(
          [_web3.cardManagerAddress.hexEip55], [withdrawCallData]);

      final data = TransferData(
        description ?? 'Purchased for $amount',
      );

      final txHash = await _web3.submitUserop(userop, data: data);
      if (txHash == null) {
        throw Exception('failed to withdraw');
      }

      _state.updateStatus(ScanStateType.verifying);

      _nfc.printReceipt(
        amount: amount,
        symbol: symbol,
        description: description,
        link: '${config.scan.url}/tx/$txHash',
      );

      await _web3.waitForTxSuccess(txHash);

      _state.updateStatus(ScanStateType.ready);
      return 'Purchase confirmed';
    } catch (e) {
      if (e is Exception) {
        _state.updateStatus(ScanStateType.ready);
        return e.toString();
      }
    }

    _state.updateStatus(ScanStateType.ready);
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
