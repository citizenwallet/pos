import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanner/router/routes.dart';
import 'package:scanner/services/config/service.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/state/app/logic.dart';
import 'package:scanner/state/app/state.dart';
import 'package:scanner/state/products/logic.dart';
import 'package:scanner/state/rewards/logic.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await PreferencesService().init();

  final config = ConfigService();

  config.init(
    dotenv.get('WALLET_CONFIG_URL'),
  );

  runApp(provideAppState(const RootScreen()));
}

class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
  });

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  late GoRouter router;

  final _rootNavigatorKey = GlobalKey<NavigatorState>();

  late ScanLogic _logic;
  late ProductsLogic _productsLogic;
  late RewardsLogic _rewardsLogic;

  @override
  void initState() {
    super.initState();

    final appLogic = AppLogic(context);

    final mode = appLogic.initialMode;

    final initialLocation = switch (mode) {
      AppMode.faucet => '/',
      AppMode.pos => '/pos',
      AppMode.unlocked => '/',
      _ => '/kiosk',
    };

    router = createRouter(
      _rootNavigatorKey,
      [],
      initialLocation: initialLocation,
    );

    _logic = ScanLogic();
    _productsLogic = ProductsLogic(context, '');
    _rewardsLogic = RewardsLogic(context, '');

    // wait for first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onLoad();

      appLogic.init();
    });
  }

  void onLoad() async {
    _logic.init(context);

    final config = await _logic.load();
    if (config == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    _productsLogic = ProductsLogic(
      context,
      config.token.address,
    );

    _productsLogic.loadProducts();

    _rewardsLogic = RewardsLogic(
      context,
      config.token.address,
    );

    _rewardsLogic.loadRewards();
  }

  @override
  void dispose() {
    router.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Terminal',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
    //   return Scaffold(
    //     appBar: AppBar(
    //       // TRY THIS: Try changing the color here to a specific color (to
    //       // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
    //       // change color while the other colors stay the same.
    //       backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    //       // Here we take the value from the MyHomePage object that was created by
    //       // the App.build method, and use it to set our appbar title.
    //       title: Text(widget.title),
    //     ),
    //     body: Center(
    //       // Center is a layout widget. It takes a single child and positions it
    //       // in the middle of the parent.
    //       child: Column(
    //         // Column is also a layout widget. It takes a list of children and
    //         // arranges them vertically. By default, it sizes itself to fit its
    //         // children horizontally, and tries to be as tall as its parent.
    //         //
    //         // Column has various properties to control how it sizes itself and
    //         // how it positions its children. Here we use mainAxisAlignment to
    //         // center the children vertically; the main axis here is the vertical
    //         // axis because Columns are vertical (the cross axis would be
    //         // horizontal).
    //         //
    //         // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
    //         // action in the IDE, or press "p" in the console), to see the
    //         // wireframe for each widget.
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: <Widget>[
    //           const Text(
    //             'You have pushed the button this many times:',
    //           ),
    //           Text(
    //             '$_counter',
    //             style: Theme.of(context).textTheme.headlineMedium,
    //           ),
    //         ],
    //       ),
    //     ),
    //     floatingActionButton: FloatingActionButton(
    //       onPressed: _incrementCounter,
    //       tooltip: 'Increment',
    //       child: const Icon(Icons.add),
    //     ), // This trailing comma makes auto-formatting nicer for build methods.
    //   );
  }
}
