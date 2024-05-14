import 'package:flutter/material.dart';
import 'package:scanner/services/config/config.dart';

class ScanState with ChangeNotifier {
  String? vendorAddress;
  String vendorBalance = '0.00';

  bool loading = true;
  bool ready = false;
  bool purchasing = false;

  String purchaseAmount = '';

  void loadScanner() {
    loading = true;
    ready = false;
    notifyListeners();
  }

  void scannerReady() {
    loading = false;
    ready = true;
    notifyListeners();
  }

  void scannerNotReady() {
    loading = false;
    ready = false;
    notifyListeners();
  }

  void startPurchasing(String amount) {
    purchasing = true;
    purchaseAmount = amount;
    notifyListeners();
  }

  void stopPurchasing() {
    purchasing = false;
    purchaseAmount = '';
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
}
