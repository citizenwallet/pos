import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/router/bottom_tabs.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/profile/state.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/widget/nfc_overlay.dart';
import 'package:scanner/widget/profile_chip.dart';

enum MenuOption { amount, faucetTopUp, withdraw, readCardBalance }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanLogic _logic = ScanLogic();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(_logic);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_logic);

    super.dispose();
  }

  void handleRedeem(String description) async {
    await _logic.redeem(description: description);
  }

  void handleCancelScan() {
    _logic.cancelScan();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ScanState>().loading;

    final ready = context.watch<ScanState>().ready;

    final vendorAddress = context.watch<ScanState>().vendorAddress;
    final redeemBalance = context.watch<ScanState>().redeemBalance;
    final redeemAmount = context.watch<ScanState>().redeemAmount;

    final insufficientBalance = context.watch<ScanState>().insufficientBalance;

    final config = context.select((ScanState s) => s.config);

    final status = context.select((ScanState s) => s.status);
    final statusError = context.select((ScanState s) => s.statusError);

    final profile = context.watch<ProfileState>();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        children: [
          Scaffold(
            appBar: !loading ? AppBar() : null,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (loading)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Preparing faucet...',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!loading && vendorAddress != null)
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            color: status ==
                                                    ScanStateType.redeeming
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
                                                        ScanStateType
                                                            .redeeming ||
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
            floatingActionButton: Opacity(
              opacity: ready ? 1 : 0.5,
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.nfc_rounded),
                label: Text(
                  'Redeem $redeemAmount ${config?.token.symbol ?? ''}',
                  style: const TextStyle(fontSize: 22),
                ),
                foregroundColor: ready ? Colors.white : Colors.black,
                backgroundColor: ready ? Colors.blue : Colors.grey,
                onPressed: ready ? () => handleRedeem(profile.description) : null,
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            bottomNavigationBar: CustomBottomAppBar(
              logic: _logic,
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
