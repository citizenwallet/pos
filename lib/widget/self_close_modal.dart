import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SelfCloseWidget extends StatefulWidget {
  final Widget child;
  final Future<String> Function() runOnOpen;

  const SelfCloseWidget({
    super.key,
    required this.child,
    required this.runOnOpen,
  });

  @override
  State<SelfCloseWidget> createState() => _SelfCloseWidgetState();
}

class _SelfCloseWidgetState extends State<SelfCloseWidget> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onLoad();
    });
  }

  void onLoad() async {
    final response = await widget.runOnOpen();

    if (!mounted) {
      return;
    }

    GoRouter.of(context).pop(response);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
