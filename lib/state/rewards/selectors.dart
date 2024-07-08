import 'package:scanner/state/rewards/state.dart';

String selectCartAmount(RewardsState state) {
  final Map<String, Reward> mappedRewards = {};

  final rewards = state.rewards.fold(mappedRewards, (v, p) => v..[p.id] = p);
  final cart = state.cart;

  return cart.fold<double>(
    0,
    (previousValue, itemId) {
      final element = rewards[itemId];
      if (element == null) {
        return previousValue;
      }
      return previousValue + double.parse(element.price);
    },
  ).toStringAsFixed(2);
}

String selectCartDescription(RewardsState state) {
  final Map<String, Reward> mappedRewards = {};

  final rewards = state.rewards.fold(mappedRewards, (v, p) => v..[p.id] = p);
  final cart = state.cart;

  return cart.fold<String>(
    'Rewards: ',
    (previousValue, itemId) {
      final element = rewards[itemId];
      if (element == null) {
        return previousValue;
      }
      return previousValue + element.name + ' ';
    },
  );
}
