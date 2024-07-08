import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/rewards/logic.dart';
import 'package:scanner/state/rewards/state.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/formatters.dart';

class ManageRewardsScreen extends StatefulWidget {
  const ManageRewardsScreen({super.key});

  @override
  State<ManageRewardsScreen> createState() => _ManageRewardsScreenState();
}

class _ManageRewardsScreenState extends State<ManageRewardsScreen> {
  late RewardsLogic _logic;

  @override
  void initState() {
    super.initState();

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

    _logic = RewardsLogic(
      context,
      config.token.address,
    );

    _logic.loadRewards();
  }

  void handleAddProduct() async {
    final width = MediaQuery.of(context).size.width;

    final nameController = context.read<RewardsState>().nameController;
    final priceController = context.read<RewardsState>().priceController;

    final FocusNode amountFocusNode = FocusNode();
    final AmountFormatter amountFormatter = AmountFormatter();

    final confirm = await showModalBottomSheet<bool?>(
      context: context,
      builder: (modalContext) {
        final keyboardHeight = MediaQuery.of(modalContext).viewInsets.bottom;

        final config = modalContext.watch<ScanState>().config;

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Container(
            height: 220 + keyboardHeight,
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Product',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        modalContext.pop(true);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => amountFocusNode.requestFocus(),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefix: Text('${config?.token.symbol ?? ''} '),
                  ),
                  maxLines: 1,
                  maxLength: 25,
                  autocorrect: false,
                  enableSuggestions: false,
                  focusNode: amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [amountFormatter],
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) {
      _logic.clearForm();
      return;
    }

    _logic.addProduct();
  }

  void handleRemoveReward(String id) {
    _logic.removeReward(id);
  }

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardsState>().rewards;

    final config = context.select((ScanState s) => s.config);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Rewards",
        ),
        actions: [
          IconButton(
            onPressed: handleAddProduct,
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (rewards.isEmpty)
                      SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: handleAddProduct,
                              label: const Text(
                                'Add product',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              icon: const Icon(
                                Icons.add,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (rewards.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: rewards.length,
                          (context, index) {
                            if (config == null) {
                              return const SizedBox();
                            }

                            final reward = rewards[index];

                            return Container(
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      reward.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 16,
                                  ),
                                  Text(
                                    '${reward.price} ${config.token.symbol}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 16,
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        handleRemoveReward(reward.id),
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
