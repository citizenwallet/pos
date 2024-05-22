import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/router/bottom_tabs.dart';
import 'package:scanner/screens/pos/tabs/amount.dart';
import 'package:scanner/screens/pos/tabs/items.dart';
import 'package:scanner/state/amount/selectors.dart';
import 'package:scanner/state/products/selectors.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: _currentTab,
      length: 2,
      vsync: this,
    );

    _tabController.addListener(handleTabChange);
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

  void handleScan() {}

  @override
  Widget build(BuildContext context) {
    final ready = true;

    final config = context.select((ScanState s) => s.config);

    if (config == null) {
      return const SizedBox();
    }

    final amount = context.select(selectFormattedAmount);
    final cartAmount = context.select(selectCartAmount);

    final currentTab = _currentTab;

    final amountDisabled = (currentTab == 0 ? cartAmount : amount) == '0.00';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          // onTap: handleTabTap,
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
      floatingActionButton: Opacity(
        opacity: ready && !amountDisabled ? 1 : 0.5,
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.nfc_rounded),
          label: Text(
            currentTab == 0
                ? 'Charge $cartAmount ${config.token.symbol}'
                : 'Charge $amount ${config.token.symbol}',
            style: const TextStyle(fontSize: 22),
          ),
          foregroundColor:
              ready && !amountDisabled ? Colors.white : Colors.black,
          backgroundColor: ready && !amountDisabled ? Colors.blue : Colors.grey,
          onPressed: ready && !amountDisabled ? handleScan : null,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomAppBar(
        logic: _scanLogic,
      ),
    );
  }
}
