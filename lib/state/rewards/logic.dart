import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/state/rewards/state.dart';

class RewardsLogic {
  final RewardsState _state;
  String token;

  final PreferencesService _prefs = PreferencesService();

  RewardsLogic(
    BuildContext context,
    this.token,
  ) : _state = context.read<RewardsState>();

  updateToken(String token) {
    this.token = token;

    loadRewards();
  }

  Future<void> loadRewards() async {
    try {
      _state.clearRewards();

      final stringRewards = _prefs.getRewards(token);
      if (stringRewards == null) {
        return;
      }

      final parsedRewards = jsonDecode(stringRewards);

      final rewards = List<Reward>.from(
        parsedRewards.map((product) => Reward.fromJson(product)),
      );

      _state.replaceRewards(rewards);
    } catch (_) {}
  }

  void addProduct() {
    try {
      _state.addReward();

      saveRewards();
    } catch (_) {}
  }

  void removeReward(String id) {
    try {
      _state.removeReward(id);

      saveRewards();
    } catch (_) {}
  }

  void updateReward(Reward reward) {
    try {
      _state.updateReward(reward);

      saveRewards();
    } catch (_) {}
  }

  void clearRewards() {
    try {
      _state.clearRewards();

      saveRewards();
    } catch (_) {}
  }

  void clearForm() {
    try {
      _state.clearForm();
    } catch (_) {}
  }

  void saveRewards() {
    final rewards = _state.rewards;

    _prefs.setRewards(token, jsonEncode(rewards));
  }

  void addToCart(String id) {
    try {
      _state.addToCart(id);
    } catch (_) {}
  }

  void removeFromCart(String id) {
    try {
      _state.removeFromCart(id);
    } catch (_) {}
  }
}
