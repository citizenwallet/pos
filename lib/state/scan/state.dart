import 'package:flutter/material.dart';
import 'package:scanner/services/config/config.dart';

enum ScanStateType {
  loading,
  ready,
  notReady,
  readingNFC,
  redeeming,
  verifying,
  verified,
  error,
}

class ScanState with ChangeNotifier {
  String? vendorAddress;
  String vendorBalance = '0.00';

  String? redeemBalance = '0.00';

  ScanStateType status = ScanStateType.loading;
  String statusError = '';

  String redeemAmount = '0.10';

  bool get loading => status == ScanStateType.loading;
  bool get redeeming =>
      status == ScanStateType.redeeming ||
      status == ScanStateType.verifying ||
      status == ScanStateType.verified;
  bool get insufficientBalance =>
      (double.tryParse(vendorBalance) ?? 0.0) <
          (double.tryParse(redeemAmount) ?? 0.0) ||
      (double.tryParse(vendorBalance) ?? 0.0) == 0.0;
  bool get ready =>
      (status == ScanStateType.ready ||
          status == ScanStateType.verifying ||
          status == ScanStateType.verified) &&
      (double.tryParse(vendorBalance) ?? 0.0) >=
          (double.tryParse(redeemAmount) ?? 0.0);

  void loadScanner() {
    status = ScanStateType.loading;
    notifyListeners();
  }

  void scannerReady() {
    status = ScanStateType.ready;
    notifyListeners();
  }

  void scannerNotReady() {
    status = ScanStateType.notReady;
    notifyListeners();
  }

  void updateStatus(ScanStateType status) {
    this.status = status;
    notifyListeners();
  }

  void setStatusError(ScanStateType status, String error) {
    this.status = status;
    statusError = error;
    notifyListeners();
  }

  void updateRedeemAmount(String amount) {
    redeemAmount = amount;
    notifyListeners();
  }

  void setVendorAddress(String? address) {
    vendorAddress = address;
    notifyListeners();
  }

  void setVendorBalance(String balance) {
    vendorBalance = balance;
    notifyListeners();
  }

  String? nfcAddress;
  String? nfcBalance;

  bool nfcAddressLoading = false;
  bool nfcAddressError = false;

  void setNfcAddressRequest() {
    nfcAddressLoading = true;
    nfcAddressError = false;
    notifyListeners();
  }

  void setNfcAddressSuccess(String? address) {
    nfcAddress = address;
    nfcAddressLoading = false;
    nfcAddressError = false;
    notifyListeners();
  }

  void setAddressBalance(String? balance) {
    nfcBalance = balance;
    notifyListeners();
  }

  void setNfcAddressError() {
    nfcAddressError = true;
    nfcAddressLoading = false;
    notifyListeners();
  }

  Config? config;

  void setConfig(Config? newConfig) {
    config = newConfig;
    notifyListeners();
  }

  void setRedeemBalance(String balance) {
    redeemBalance = balance;
    notifyListeners();
  }

  List<Config> configs = [];
  void setConfigs(List<Config> newConfigs) {
    configs = newConfigs;
    notifyListeners();
  }
}
