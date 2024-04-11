import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/nfc/service.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/services/web3/service.dart';
import 'package:scanner/services/web3/transfer_data.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/currency.dart';
import 'package:scanner/utils/qr.dart';

class ScanLogic {
  final ScanState _state;
  final NFCService _nfc = NFCService();
  final PreferencesService _preferences = PreferencesService();

  late Web3Service _web3;

  ScanLogic(BuildContext context) : _state = context.read<ScanState>();

  Future<void> init() async {
    try {
      _state.loadScanner();

      _web3 = Web3Service();

      await _web3.init(
        dotenv.get(kDebugMode ? 'TESTNET_RPC_URL' : 'MAINNET_RPC_URL'),
        dotenv.get(kDebugMode ? 'BUNDLER_TESTNET_RPC_URL' : 'BUNDLER_RPC_URL'),
        dotenv.get(kDebugMode ? 'INDEXER_TESTNET_RPC_URL' : 'INDEXER_RPC_URL'),
        dotenv.get(
            kDebugMode ? 'PAYMASTER_TESTNET_RPC_URL' : 'PAYMASTER_RPC_URL'),
        dotenv.get(kDebugMode
            ? 'PAYMASTER_TESTNET_CONTRACT_ADDR'
            : 'PAYMASTER_CONTRACT_ADDR'),
        dotenv.get(
          kDebugMode
              ? 'CARD_MANAGER_TESTNET_CONTRACT_ADDR'
              : 'CARD_MANAGER_CONTRACT_ADDR',
        ),
        dotenv.get(kDebugMode
            ? 'ACCOUNT_FACTORY_TESTNET_CONTRACT_ADDR'
            : 'ACCOUNT_FACTORY_CONTRACT_ADDR'),
        dotenv.get(
          kDebugMode
              ? 'ENTRYPOINT_TESTNET_CONTRACT_ADDR'
              : 'ENTRYPOINT_CONTRACT_ADDR',
        ),
        dotenv.get(kDebugMode ? 'TOKEN_TESTNET_ADDR' : 'TOKEN_ADDR'),
      );

      _state.setVendorAddress(_web3.account.hexEip55);

      updateVendorBalance();

      _state.scannerReady();
      return;
    } catch (e, s) {
      print(e);
      print(s);
    }

    _state.scannerNotReady();
  }

  void updateVendorBalance() async {
    try {
      final balance = await _web3.getBalance(_web3.account.hexEip55);

      _state.setVendorBalance(fromUnit(balance));
    } catch (_) {}
  }

  void copyVendorAddress() {
    try {
      final vendorAddress = _web3.account.hexEip55;

      Clipboard.setData(ClipboardData(text: vendorAddress));

      updateVendorBalance(); // hack to update the balance
    } catch (_) {}
  }

  Future<String> redeem() async {
    try {
      const amount = '1.00';

      _state.startPurchasing(amount);

      final serialNumber = await _nfc.readSerialNumber(
        message: 'Scan to redeem WOLU $amount',
        successMessage: 'Redeemed WOLU $amount',
      );

      final cardHash = await _web3.getCardHash(serialNumber);

      final address = await _web3.getCardAddress(cardHash);

      final isRedeemed = _preferences.isRedeemed(address.hexEip55);
      if (isRedeemed) {
        throw Exception('Already redeemed');
      }

      final balance = await _web3.getBalance(_web3.account.hexEip55);
      if (balance == BigInt.zero) {
        throw Exception('Faucet empty');
      }

      final calldata = _web3.erc20TransferCallData(
          address.hexEip55, toUnit('1.00', decimals: 6));

      final (_, userop) =
          await _web3.prepareUserop([_web3.tokenAddress.hexEip55], [calldata]);

      final data = TransferData(
        'Withdraw balance',
      );

      final success = await _web3.submitUserop(userop, data: data);
      if (!success) {
        throw Exception('Failed to redeem');
      }

      _preferences.setRedeemed(address.hexEip55);

      _state.stopPurchasing();
      return 'Redeemed WOLU $amount';
    } catch (e) {
      print(e);
      if (e is Exception) {
        _state.stopPurchasing();
        return e.toString().replaceFirst('Exception: ', '');
      }
    }

    _state.stopPurchasing();

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

      final success = await _web3.submitUserop(userop, data: data);
      if (!success) {
        throw Exception('failed to withdraw');
      }

      return true;
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
    } catch (e, s) {
      print(e);
      print(s);
      _state.setNfcAddressError();
      _state.setAddressBalance(null);
    }

    return null;
  }
}
