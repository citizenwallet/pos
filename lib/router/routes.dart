import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanner/screens/faucet/tabs/amount/manage.dart';
import 'package:scanner/screens/kiosk/profile_edit.dart';
import 'package:scanner/screens/kiosk/screen.dart';
import 'package:scanner/screens/pos/screen.dart';
import 'package:scanner/screens/pos/tabs/amount/manage.dart';
import 'package:scanner/screens/faucet/screen.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  List<NavigatorObserver> observers, {
  String initialLocation = '/',
}) =>
    GoRouter(
      initialLocation: initialLocation,
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
            child: const FaucetScreen(),
          ),
        ),
        GoRoute(
          name: "Manage Rewards",
          path: '/rewards/manage',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ManageRewardsScreen(),
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
        GoRoute(
          name: "Manage Products",
          path: '/pos/manage',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ManageProductsScreen(),
        ),
        GoRoute(
          name: 'Kiosk',
          path: '/kiosk',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            name: state.name,
            child: const KioskScreen(),
          ),
        ),
        GoRoute(
          name: "Profile",
          path: '/kiosk/profile',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    );
