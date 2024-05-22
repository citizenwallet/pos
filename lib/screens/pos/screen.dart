import 'package:flutter/material.dart';
import 'package:scanner/router/bottom_tabs.dart';
import 'package:scanner/screens/pos/tabs/amount.dart';
import 'package:scanner/state/scan/logic.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  POSScreenState createState() => POSScreenState();
}

class POSScreenState extends State<POSScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ScanLogic _scanLogic = ScanLogic();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 1,
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void handleScan() {}

  @override
  Widget build(BuildContext context) {
    final ready = true;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Items'),
            Tab(text: 'Amount'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ItemsTab(),
          AmountTab(),
        ],
      ),
      floatingActionButton: Opacity(
        opacity: ready ? 1 : 0.5,
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.nfc_rounded),
          label: Text(
            'Charge',
            style: const TextStyle(fontSize: 22),
          ),
          foregroundColor: ready ? Colors.white : Colors.black,
          backgroundColor: ready ? Colors.blue : Colors.grey,
          onPressed: ready ? handleScan : null,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomAppBar(
        logic: _scanLogic,
      ),
    );
  }
}

class ItemsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Items Tab Content'),
    );
  }
}
