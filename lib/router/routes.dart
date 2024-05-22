import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanner/screens/pos/screen.dart';
import 'package:scanner/screens/scan/screen.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  List<NavigatorObserver> observers,
) =>
    GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      navigatorKey: rootNavigatorKey,
      observers: observers,
      routes: [
        GoRoute(
          name: 'Faucet',
          path: '/',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            name: state.name,
            child: const ScanScreen(),
          ),
        ),
        GoRoute(
          name: 'POS',
          path: '/pos',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            name: state.name,
            child: const POSScreen(),
          ),
        ),
      ],
    );
