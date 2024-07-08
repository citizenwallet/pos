import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/amount/state.dart';
import 'package:scanner/state/app/state.dart';
import 'package:scanner/state/products/state.dart';
import 'package:scanner/state/profile/state.dart';
import 'package:scanner/state/rewards/state.dart';
import 'package:scanner/state/scan/state.dart';

Widget provideAppState(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductsState(),
        ),
        ChangeNotifierProvider(
          create: (_) => RewardsState(),
        ),
        ChangeNotifierProvider(
          create: (_) => ScanState(),
        ),
        ChangeNotifierProvider(
          create: (_) => AmountState(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileState(),
        ),
      ],
      child: child,
    );
