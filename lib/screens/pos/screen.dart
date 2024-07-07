import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:scanner/router/bottom_tabs.dart';
import 'package:scanner/screens/pos/tabs/amount/amount.dart';
import 'package:scanner/screens/pos/tabs/items.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/state/amount/selectors.dart';
import 'package:scanner/state/products/logic.dart';
import 'package:scanner/state/products/selectors.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/widget/nfc_overlay.dart';
import 'package:scanner/widget/qr/qr.dart';
import 'package:scanner/widget/self_close_modal.dart';

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

    _productsLogic = ProductsLogic(
      context,
      '',
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

  void handleDisplayQR(
      BuildContext context, String amount, String description) async {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final config = context.read<ScanState>().config;
    if (config == null) {
      return;
    }

    final deepLinkUrl = dotenv.env['WALLET_DEEPLINK_URL'];
    if (deepLinkUrl == null) {
      return;
    }

    _scanLogic.listenToBalance();

    await showModalBottomSheet<void>(
      context: context,
      builder: (modalContext) {
        final vendorAddress = modalContext.watch<ScanState>().vendorAddress;
        final vendorBalance = modalContext.watch<ScanState>().vendorBalance;

        String params =
            '?address=$vendorAddress&alias=${config.community.alias}';

        params += '&amount=$amount';
        params += '&message=$description';

        final compressedParams = compress(params);

        final deepLink =
            '$deepLinkUrl/#/?alias=${config.community.alias}&receiveParams=$compressedParams';

        return Container(
          height: height,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Scan to pay',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              QR(
                data: deepLink,
                size: width - 120,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$amount ${config.token.symbol}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    _scanLogic.stopListenToBalance();
  }

  void handleScan(
      BuildContext context, String amount, String description) async {
    final width = MediaQuery.of(context).size.width;

    final serialNumber = await _scanLogic.readTag();
    if (serialNumber == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final config = context.read<ScanState>().config;
    if (config == null) {
      return;
    }

    final message = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (modalContext) => SelfCloseWidget(
        runOnOpen: () =>
            _scanLogic.purchase(serialNumber, amount, description: description),
        child: Container(
          height: 300,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Purchasing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$amount ${config.token.symbol}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // final message = await _scanLogic.purchase(amount, description: description);

    if (message == null) {
      return;
    }

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
    final receiveText = ready ? 'Receive' : 'Receiving';

    final config = context.select((ScanState s) => s.config);

    if (config == null) {
      return const SizedBox();
    }

    final amount = context.select(selectFormattedAmount);
    final cartAmount = context.select(selectCartAmount);
    final cardDescription = context.select(selectCartDescription);

    final currentTab = _currentTab;

    final amountDisabled = (currentTab == 0 ? cartAmount : amount) == '0.00';

    final description =
        currentTab == 0 ? cardDescription : 'Manual amount: $amount';

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
          floatingActionButton: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'qr',
                foregroundColor: ready && !amountDisabled
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                backgroundColor:
                    ready && !amountDisabled ? Colors.blue : Colors.grey,
                onPressed: ready && !amountDisabled
                    ? () => handleDisplayQR(context,
                        currentTab == 0 ? cartAmount : amount, description)
                    : null,
                child: ready
                    ? const Icon(
                        Icons.qr_code,
                        color: Colors.white,
                      )
                    : SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.5),
                          strokeWidth: 2,
                        ),
                      ),
              ),
              const SizedBox(width: 32),
              FloatingActionButton.extended(
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
                    ? () => handleScan(context,
                        currentTab == 0 ? cartAmount : amount, description)
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          bottomNavigationBar: CustomBottomAppBar(
            logic: _scanLogic,
            productsLogic: _productsLogic,
          ),
        ),
        NfcOverlay(
          onCancel: handleCancelScan,
        ),
      ],
    );
  }
}
