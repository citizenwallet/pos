import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/products/logic.dart';
import 'package:scanner/state/products/state.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/formatters.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  late ProductsLogic _logic;

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

    _logic = ProductsLogic(
      context,
      config.token.address,
    );

    _logic.loadProducts();
  }

  void handleAddProduct() async {
    final width = MediaQuery.of(context).size.width;

    final nameController = context.read<ProductsState>().nameController;
    final priceController = context.read<ProductsState>().priceController;

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

  void handleRemoveProduct(String id) {
    _logic.removeProduct(id);
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsState>().products;

    final config = context.select((ScanState s) => s.config);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Products",
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
                    if (products.isEmpty)
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
                    if (products.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: products.length,
                          (context, index) {
                            if (config == null) {
                              return const SizedBox();
                            }

                            final product = products[index];

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
                                      product.name,
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
                                    '${product.price} ${config.token.symbol}',
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
                                        handleRemoveProduct(product.id),
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
