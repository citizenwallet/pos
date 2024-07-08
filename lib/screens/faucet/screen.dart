import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/router/bottom_tabs.dart';
import 'package:scanner/screens/faucet/tabs/amount/amount.dart';
import 'package:scanner/screens/faucet/tabs/items.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/amount/selectors.dart';
import 'package:scanner/state/profile/state.dart';
import 'package:scanner/state/rewards/logic.dart';
import 'package:scanner/state/rewards/selectors.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/widget/nfc_overlay.dart';
import 'package:scanner/widget/profile_chip.dart';
import 'package:scanner/widget/self_close_modal.dart';

enum MenuOption { amount, faucetTopUp, withdraw, readCardBalance }

class FaucetScreen extends StatefulWidget {
  const FaucetScreen({super.key});

  @override
  State<FaucetScreen> createState() => _FaucetScreenState();
}

class _FaucetScreenState extends State<FaucetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _currentTab = 0;

  final ScanLogic _logic = ScanLogic();
  late RewardsLogic _rewardsLogic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: _currentTab,
      length: 2,
      vsync: this,
    );

    _rewardsLogic = RewardsLogic(
      context,
      '',
    );

    _tabController.addListener(handleTabChange);

    WidgetsBinding.instance.addObserver(_logic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      onLoad();
    });
  }

  void onLoad() async {
    final config = context.read<ScanState>().config;
    if (config == null) {
      return;
    }

    _rewardsLogic = RewardsLogic(
      context,
      config.token.address,
    );

    _rewardsLogic.loadRewards();
  }

  @override
  void dispose() {
    _tabController.removeListener(handleTabChange);
    WidgetsBinding.instance.removeObserver(_logic);

    super.dispose();
  }

  void handleTabChange() {
    setState(() {
      _currentTab = _tabController.index;
    });
  }

  void handleRedeem(String amount, String description) async {
    final width = MediaQuery.of(context).size.width;

    final serialNumber = await _logic.readTag();
    if (serialNumber == null) {
      return;
    }

    if (!context.mounted || !super.mounted) {
      return;
    }

    final config = context.read<ScanState>().config;
    if (config == null) {
      return;
    }

    await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (modalContext) {
        final redeemBalance = modalContext.watch<ScanState>().redeemBalance;

        final insufficientBalance =
            modalContext.watch<ScanState>().insufficientBalance;

        final config = modalContext.select((ScanState s) => s.config);

        if (config == null) {
          return const SizedBox();
        }

        final status = modalContext.select((ScanState s) => s.status);
        final statusError = modalContext.select((ScanState s) => s.statusError);

        final profile = modalContext.watch<ProfileState>();

        return SelfCloseWidget(
          runOnOpen: () =>
              _logic.redeem(serialNumber, amount, description: description),
          child: Container(
            height: 300,
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...(switch (status) {
                              ScanStateType.loading => [
                                  const Text(
                                    'Loading',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 156),
                                ],
                              ScanStateType.ready => [
                                  Text(
                                    insufficientBalance
                                        ? 'Faucet empty'
                                        : 'Ready',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 156),
                                ],
                              ScanStateType.notReady => [
                                  const Text(
                                    'Not ready',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 156),
                                ],
                              ScanStateType.readingNFC => [
                                  const Text(
                                    'Reading tag...',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 156),
                                ],
                              ScanStateType.error => [
                                  const Text(
                                    'An error occurred',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusError,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 112),
                                ],
                              _ => [
                                  Text(
                                    switch (status) {
                                      ScanStateType.verifying => 'Redeemed',
                                      ScanStateType.verified => 'Confirmed',
                                      _ => 'Redeeming...',
                                    },
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 20,
                                        width: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.greenAccent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        height: 20,
                                        width: 20,
                                        decoration: BoxDecoration(
                                          color:
                                              status == ScanStateType.redeeming
                                                  ? Colors.greenAccent
                                                      .withOpacity(0)
                                                  : Colors.greenAccent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.greenAccent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        height: 20,
                                        width: 20,
                                        decoration: BoxDecoration(
                                          color: status ==
                                                      ScanStateType.redeeming ||
                                                  status ==
                                                      ScanStateType.verifying
                                              ? Colors.greenAccent
                                                  .withOpacity(0)
                                              : Colors.greenAccent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.greenAccent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: ProfileChip(
                                      name: profile.name.isEmpty
                                          ? null
                                          : profile.name,
                                      username: profile.username.isEmpty
                                          ? null
                                          : profile.username,
                                      image: profile.imageSmall.isEmpty
                                          ? null
                                          : profile.imageSmall,
                                      address: profile.account.isEmpty
                                          ? null
                                          : formatHexAddress(
                                              profile.account,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Current balance: $redeemBalance',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ]
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void handleCancelScan() {
    _logic.cancelScan();
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.watch<ScanState>().ready;

    final redeemAmount = context.watch<ScanState>().redeemAmount;

    final config = context.select((ScanState s) => s.config);

    if (config == null) {
      return const SizedBox();
    }

    const redeemText = 'Redeem';

    final amount = context.select(selectFormattedAmount);
    final cartAmount = context.select(selectCartAmount);
    final cardDescription = context.select(selectCartDescription);

    final currentTab = _currentTab;

    final amountDisabled = (currentTab == 0 ? cartAmount : amount) == '0.00';

    final description =
        currentTab == 0 ? cardDescription : 'Manual amount: $amount';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Items'),
                  Tab(text: 'Amount'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                ItemsTab(
                  config: config,
                ),
                AmountTab(
                  config: config,
                ),
              ],
            ),
            // body: Center(
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 20),
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       children: <Widget>[
            //         if (loading)
            //           const Expanded(
            //             child: Center(
            //               child: Column(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 children: [
            //                   CircularProgressIndicator(),
            //                   SizedBox(height: 16),
            //                   Text(
            //                     'Preparing faucet...',
            //                     style: TextStyle(
            //                       fontSize: 24,
            //                       fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         if (!loading && vendorAddress != null)
            //           Expanded(
            //             child: Center(
            //               child: Column(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 children: [
            //                   ...(switch (status) {
            //                     ScanStateType.loading => [
            //                         const Text(
            //                           'Loading',
            //                           style: TextStyle(
            //                             fontSize: 24,
            //                             fontWeight: FontWeight.normal,
            //                           ),
            //                         ),
            //                         const SizedBox(height: 156),
            //                       ],
            //                     ScanStateType.ready => [
            //                         Text(
            //                           insufficientBalance
            //                               ? 'Faucet empty'
            //                               : 'Ready',
            //                           style: const TextStyle(
            //                             fontSize: 24,
            //                             fontWeight: FontWeight.normal,
            //                           ),
            //                         ),
            //                         const SizedBox(height: 156),
            //                       ],
            //                     ScanStateType.notReady => [
            //                         const Text(
            //                           'Not ready',
            //                           style: TextStyle(
            //                             fontSize: 24,
            //                             fontWeight: FontWeight.normal,
            //                           ),
            //                         ),
            //                         const SizedBox(height: 156),
            //                       ],
            //                     ScanStateType.readingNFC => [
            //                         const Text(
            //                           'Reading tag...',
            //                           style: TextStyle(
            //                             fontSize: 24,
            //                             fontWeight: FontWeight.normal,
            //                           ),
            //                         ),
            //                         const SizedBox(height: 156),
            //                       ],
            //                     ScanStateType.error => [
            //                         const Text(
            //                           'An error occurred',
            //                           style: TextStyle(
            //                             fontSize: 24,
            //                             fontWeight: FontWeight.normal,
            //                           ),
            //                         ),
            //                         const SizedBox(height: 4),
            //                         Text(
            //                           statusError,
            //                           style: const TextStyle(
            //                             fontSize: 20,
            //                             fontWeight: FontWeight.normal,
            //                           ),
            //                         ),
            //                         const SizedBox(height: 112),
            //                       ],
            //                     _ => [
            //                         Text(
            //                           switch (status) {
            //                             ScanStateType.verifying => 'Redeemed',
            //                             ScanStateType.verified => 'Confirmed',
            //                             _ => 'Redeeming...',
            //                           },
            //                           style: const TextStyle(
            //                             fontSize: 24,
            //                             fontWeight: FontWeight.normal,
            //                           ),
            //                         ),
            //                         const SizedBox(height: 16),
            //                         Row(
            //                           mainAxisAlignment:
            //                               MainAxisAlignment.center,
            //                           crossAxisAlignment:
            //                               CrossAxisAlignment.center,
            //                           children: [
            //                             Container(
            //                               height: 20,
            //                               width: 20,
            //                               decoration: BoxDecoration(
            //                                 color: Colors.greenAccent,
            //                                 borderRadius:
            //                                     BorderRadius.circular(10),
            //                                 border: Border.all(
            //                                   color: Colors.greenAccent,
            //                                   width: 2,
            //                                 ),
            //                               ),
            //                             ),
            //                             const SizedBox(width: 8),
            //                             AnimatedContainer(
            //                               duration:
            //                                   const Duration(milliseconds: 500),
            //                               height: 20,
            //                               width: 20,
            //                               decoration: BoxDecoration(
            //                                 color: status ==
            //                                         ScanStateType.redeeming
            //                                     ? Colors.greenAccent
            //                                         .withOpacity(0)
            //                                     : Colors.greenAccent,
            //                                 borderRadius:
            //                                     BorderRadius.circular(10),
            //                                 border: Border.all(
            //                                   color: Colors.greenAccent,
            //                                   width: 2,
            //                                 ),
            //                               ),
            //                             ),
            //                             const SizedBox(width: 8),
            //                             AnimatedContainer(
            //                               duration:
            //                                   const Duration(milliseconds: 500),
            //                               height: 20,
            //                               width: 20,
            //                               decoration: BoxDecoration(
            //                                 color: status ==
            //                                             ScanStateType
            //                                                 .redeeming ||
            //                                         status ==
            //                                             ScanStateType.verifying
            //                                     ? Colors.greenAccent
            //                                         .withOpacity(0)
            //                                     : Colors.greenAccent,
            //                                 borderRadius:
            //                                     BorderRadius.circular(10),
            //                                 border: Border.all(
            //                                   color: Colors.greenAccent,
            //                                   width: 2,
            //                                 ),
            //                               ),
            //                             ),
            //                           ],
            //                         ),
            //                         const SizedBox(height: 16),
            //                         Padding(
            //                           padding: const EdgeInsets.symmetric(
            //                             horizontal: 20,
            //                           ),
            //                           child: ProfileChip(
            //                             name: profile.name.isEmpty
            //                                 ? null
            //                                 : profile.name,
            //                             username: profile.username.isEmpty
            //                                 ? null
            //                                 : profile.username,
            //                             image: profile.imageSmall.isEmpty
            //                                 ? null
            //                                 : profile.imageSmall,
            //                             address: profile.account.isEmpty
            //                                 ? null
            //                                 : formatHexAddress(
            //                                     profile.account,
            //                                   ),
            //                           ),
            //                         ),
            //                         const SizedBox(height: 16),
            //                         Text(
            //                           'Current balance: $redeemBalance',
            //                           style: const TextStyle(
            //                             fontSize: 24,
            //                             fontWeight: FontWeight.normal,
            //                           ),
            //                         ),
            //                       ]
            //                   }),
            //                 ],
            //               ),
            //             ),
            //           ),
            //       ],
            //     ),
            //   ),
            // ),
            floatingActionButton: Opacity(
              opacity: ready ? 1 : 0.5,
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.nfc_rounded),
                label: Text(
                  currentTab == 0
                      ? '$redeemText $cartAmount ${config.token.symbol}'
                      : '$redeemText $amount ${config.token.symbol}',
                  style: const TextStyle(fontSize: 22),
                ),
                foregroundColor:
                    ready && !amountDisabled ? Colors.white : Colors.black,
                backgroundColor:
                    ready && !amountDisabled ? Colors.blue : Colors.grey,
                onPressed: ready
                    ? () => handleRedeem(redeemAmount, description)
                    : null,
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            bottomNavigationBar: CustomBottomAppBar(
              logic: _logic,
              rewardsLogic: _rewardsLogic,
            ),
          ),
          NfcOverlay(
            onCancel: handleCancelScan,
          ),
        ],
      ),
    );
  }
}
