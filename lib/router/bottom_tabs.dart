import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanner/services/config/config.dart';
import 'package:scanner/state/app/state.dart';
import 'package:scanner/state/products/logic.dart';
import 'package:scanner/state/rewards/logic.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/widget/custom_icon_button.dart';

class CustomBottomAppBar extends StatelessWidget {
  final ScanLogic logic;
  final ProductsLogic? productsLogic;
  final RewardsLogic? rewardsLogic;

  const CustomBottomAppBar({
    super.key,
    required this.logic,
    this.productsLogic,
    this.rewardsLogic,
  });

  void handleCommunityPress(BuildContext context, Config config) async {
    await logic.load(alias: config.community.alias);
    productsLogic?.updateToken(config.token.address);
    rewardsLogic?.updateToken(config.token.address);
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context);

    final parts = currentRoute.uri.toString().split('/');
    final location = parts.length > 1 ? parts[1] : '/';

    final config = context.select((ScanState s) => s.config);
    final configs = context.select((ScanState s) => s.configs);

    final redeeming = context.watch<ScanState>().redeeming;

    final mode = context.select((AppState s) => s.mode);

    if (mode == AppMode.locked) {
      return const SizedBox();
    }

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          if (mode == AppMode.faucet || mode == AppMode.unlocked)
            CustomIconButton(
              icon: Icons.upcoming,
              label: 'Faucet',
              isSelected: location == '',
              onPressed: () {
                if (location != '') {
                  context.go('/');
                }
              },
            ),
          if (mode == AppMode.pos || mode == AppMode.unlocked)
            CustomIconButton(
              icon: Icons.shopping_cart,
              label: 'POS',
              isSelected: location == 'pos',
              onPressed: () {
                if (location != 'pos') {
                  context.go('/pos');
                }
              },
            ),
          if (mode == AppMode.faucet ||
              mode == AppMode.pos ||
              mode == AppMode.unlocked)
            Expanded(
              child: PopupMenuButton<Config>(
                onSelected: (Config item) {
                  handleCommunityPress(context, item);
                },
                enabled: !redeeming,
                offset: const Offset(0, 40),
                itemBuilder: (BuildContext context) => configs
                    .where((c) => c.cards != null
                                  || c.token.standard == "eosio")
                    .map<PopupMenuEntry<Config>>(
                      (c) => PopupMenuItem<Config>(
                        value: c,
                        child: SizedBox(
                          height: 40,
                          // width: 180,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 8),
                              config?.community.logo != null
                                  ? SvgPicture.network(
                                      c.community.logo,
                                      semanticsLabel: 'contactless payment',
                                      height: 30,
                                      width: 30,
                                      placeholderBuilder: (context) =>
                                          SvgPicture.asset(
                                        'assets/icons/community.svg',
                                        semanticsLabel: 'community icon',
                                        height: 30,
                                        width: 30,
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      'assets/icons/community.svg',
                                      semanticsLabel: 'community icon',
                                      height: 30,
                                      width: 30,
                                    ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.community.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: config?.community.alias ==
                                            c.community.alias
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: AnimatedOpacity(
                  opacity: redeeming ? 0.5 : 1,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    height: 40,
                    // width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        config?.community.logo != null
                            ? SvgPicture.network(
                                config!.community.logo,
                                semanticsLabel: 'contactless payment',
                                height: 30,
                                width: 30,
                                placeholderBuilder: (context) =>
                                    SvgPicture.asset(
                                  'assets/icons/community.svg',
                                  semanticsLabel: 'community icon',
                                  height: 30,
                                  width: 30,
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/icons/community.svg',
                                semanticsLabel: 'community icon',
                                height: 30,
                                width: 30,
                              ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            config?.community.name ?? 'No selection',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          CustomIconButton(
            icon: Icons.smartphone,
            label: 'Kiosk',
            isSelected: location == 'kiosk',
            onPressed: () {
              if (location != 'kiosk') {
                context.go('/kiosk');
              }
            },
          ),
        ],
      ),
    );
  }
}
