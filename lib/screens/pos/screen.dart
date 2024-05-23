import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/router/bottom_tabs.dart';
import 'package:scanner/screens/pos/tabs/amount/amount.dart';
import 'package:scanner/screens/pos/tabs/items.dart';
import 'package:scanner/state/amount/selectors.dart';
import 'package:scanner/state/products/logic.dart';
import 'package:scanner/state/products/selectors.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/widget/nfc_overlay.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  POSScreenState createState() => POSScreenState();
}

class POSScreenState extends State<POSScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _currentTab = 0;

  final ScanLogic _scanLogic = ScanLogic();
  late ProductsLogic _productsLogic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: _currentTab,
      length: 2,
      vsync: this,
    );

    _tabController.addListener(handleTabChange);

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

    _productsLogic = ProductsLogic(
      context,
      config.token.address,
    );

    _productsLogic.loadProducts();
  }

  @override
  void dispose() {
    _tabController.removeListener(handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void handleTabChange() {
    setState(() {
      _currentTab = _tabController.index;
    });
  }

  void handleScan(BuildContext context, String amount) async {
    final message = await _scanLogic.purchase(amount);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  void handleCancelScan() {
    _scanLogic.cancelScan();
  }

  @override
  Widget build(BuildContext context) {
    final ready = !(context.select((ScanState s) => s.redeeming));

    final chargeText = ready ? 'Charge' : 'Charging';

    final config = context.select((ScanState s) => s.config);

    if (config == null) {
      return const SizedBox();
    }

    final amount = context.select(selectFormattedAmount);
    final cartAmount = context.select(selectCartAmount);

    final currentTab = _currentTab;

    final amountDisabled = (currentTab == 0 ? cartAmount : amount) == '0.00';

    return Stack(
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
          floatingActionButton: FloatingActionButton.extended(
            icon: ready
                ? const Icon(Icons.nfc_rounded)
                : SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.5),
                      strokeWidth: 2,
                    ),
                  ),
            label: Text(
              currentTab == 0
                  ? '$chargeText $cartAmount ${config.token.symbol}'
                  : '$chargeText $amount ${config.token.symbol}',
              style: const TextStyle(fontSize: 22),
            ),
            foregroundColor: ready && !amountDisabled
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            backgroundColor:
                ready && !amountDisabled ? Colors.blue : Colors.grey,
            onPressed: ready && !amountDisabled
                ? () =>
                    handleScan(context, currentTab == 0 ? cartAmount : amount)
                : null,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          bottomNavigationBar: CustomBottomAppBar(
            logic: _scanLogic,
          ),
        ),
        NfcOverlay(
          onCancel: handleCancelScan,
        ),
      ],
    );
  }
}
