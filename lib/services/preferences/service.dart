import 'dart:convert';

import 'package:scanner/state/app/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static const String redeemPrefix = 'redeemed';

  late SharedPreferences _preferences;

  Future init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Future clear() async {
    await _preferences.clear();
  }

  String? get key => _preferences.getString('key');

  Future setKey(String value) async {
    await _preferences.setString('key', value);
  }

  void setRedeemed(String address) {
    _preferences.setBool('$redeemPrefix-address', true);
  }

  bool isRedeemed(String address) {
    return _preferences.getBool('$redeemPrefix-address') ?? false;
  }

  void setRedeemAmount(String token, String amount) {
    _preferences.setString('token-$token', amount);
  }

  String getRedeemAmount(String token) {
    return _preferences.getString('token-$token') ?? '1.00';
  }

  // saved configs
  Future setConfigs(dynamic value) async {
    await _preferences.setString('configs', jsonEncode(value));
  }

  dynamic getConfigs() {
    final config = _preferences.getString('configs');
    if (config == null) {
      return null;
    }

    return jsonDecode(config);
  }

  Future setLastAlias(String value) async {
    await _preferences.setString('lastAlias', value);
  }

  String? getLastAlias() {
    return _preferences.getString('lastAlias');
  }

  Future setProducts(String token, String products) {
    return _preferences.setString('products-$token', products);
  }

  String? getProducts(String token) {
    return _preferences.getString('products-$token');
  }

  Future setRewards(String token, String rewards) {
    return _preferences.setString('rewards-$token', rewards);
  }

  String? getRewards(String token) {
    return _preferences.getString('rewards-$token');
  }

  Future setAppMode(AppMode mode) {
    return _preferences.setString('app-mode', mode.name);
  }

  AppMode getAppMode() {
    final savedMode = _preferences.getString('app-mode');
    if (savedMode == null) {
      return AppMode.locked;
    }
    return AppMode.values.firstWhere(
      (AppMode m) => m.name == savedMode,
      orElse: () => AppMode.locked,
    );
  }
}
