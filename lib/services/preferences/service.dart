import 'dart:convert';

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
}
