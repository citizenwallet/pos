import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/config/config.dart';
import 'package:scanner/state/rewards/logic.dart';
import 'package:scanner/state/rewards/state.dart';

class ItemsTab extends StatefulWidget {
  final Config config;

  const ItemsTab({super.key, required this.config});

  @override
  ItemsTabState createState() => ItemsTabState();
}

class ItemsTabState extends State<ItemsTab> {
  late RewardsLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = RewardsLogic(context, widget.config.token.address);
  }

  void handleManageRewards() async {
    await GoRouter.of(context).push('/rewards/manage');

    _logic.loadRewards();
  }

  void handleAddToCart(String id) {
    _logic.addToCart(id);
  }

  void handleRemoveFromCart(String id) {
    _logic.removeFromCart(id);
  }

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardsState>().rewards;
    final cart = context.watch<RewardsState>().cart;

    final config = widget.config;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 60.0, bottom: 120.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      return RewardCard(
                        symbol: config.token.symbol,
                        product: rewards[index],
                        cart: cart,
                        onPressed: handleAddToCart,
                        onRemove: handleRemoveFromCart,
                      );
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: handleManageRewards,
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RewardCard extends StatelessWidget {
  final String symbol;
  final Reward product;
  final List<String> cart;
  final Function(String)? onPressed;
  final Function(String)? onRemove;

  const RewardCard({
    super.key,
    this.symbol = '',
    required this.product,
    this.cart = const [],
    this.onPressed,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final amount = cart.where((id) => id == product.id).length;

    return Stack(
      children: [
        GestureDetector(
          onTap: onPressed != null ? () => onPressed!(product.id) : null,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: amount > 0
                              ? Colors.blue.withOpacity(0.25)
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: amount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '$symbol ${product.price}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (amount > 0)
                SizedBox(
                  height: 38,
                  width: 38,
                  child: IconButton.filled(
                    onPressed: () => onRemove?.call(product.id),
                    iconSize: 16,
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(Colors.red.withOpacity(0.8)),
                    ),
                    icon: const Icon(
                      Icons.remove,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
