import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/state/app/state.dart';

class AppLogic {
  final AppState _state;

  final PreferencesService _prefs = PreferencesService();

  AppLogic(BuildContext context) : _state = context.read<AppState>();

  AppMode get initialMode => _prefs.getAppMode();

  void init() {
    try {
      final mode = _prefs.getAppMode();

      _state.setMode(mode);
    } catch (_) {}
  }

  void changeAppMode(AppMode mode) {
    try {
      _state.setMode(mode);

      _prefs.setAppMode(mode);
    } catch (_) {}
  }
}
