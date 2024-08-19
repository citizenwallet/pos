import 'package:flutter/material.dart';
import 'package:scanner/router/bottom_tabs.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/services/web3/contracts/profile.dart';
import 'package:scanner/state/profile/logic.dart';
import 'package:scanner/state/profile/state.dart';
import 'package:scanner/state/scan/logic.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/delay.dart';
import 'package:scanner/utils/formatters.dart';
import 'package:scanner/widget/blurry_child.dart';
import 'package:scanner/widget/progress_bar.dart';
import 'package:scanner/widget/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

class SelectTokensScreen extends StatefulWidget {
  const SelectTokensScreen({
    super.key,
  });

  @override
  SelectTokensScreenState createState() => SelectTokensScreenState();
}

class SelectTokensScreenState extends State<SelectTokensScreen> {

  ScanLogic scanLogic = ScanLogic();
  @override
  void initState() {
    super.initState();

     WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

   // _logic.startEdit();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<ScanState>();
    final configs = context.select((ScanState s) => s.configs);
    final activeAliases = context.select((ScanState s) => s.activeAliases);
    final PreferencesService preferences = PreferencesService();
    return new Scaffold(
      body: ListView.builder(
        itemCount: configs.length,
        itemBuilder: (context, index) {
          return SwitchListTile(
        // 2.
            title: Text('${configs[index].community.name}'),
        // 3.
            value: activeAliases.contains(configs[index].community.alias),
        // 4.
            onChanged: (bool value) {
              setState(() {
                final alias = configs[index].community.alias;
                var newActives = activeAliases;
                if (value) {
                  newActives.add(alias);
                } else {
                  newActives.remove(alias);
                }
                state.setActiveAliases(newActives);
                preferences.setActiveAliases(newActives);
              });
            },
          );
        }
      ),
      persistentFooterButtons: [
        BackButton(
          onPressed:
           () => { context.go('/kiosk') }
        ),
      ],
      bottomNavigationBar: CustomBottomAppBar(
        logic: scanLogic,
        locked: false,
      ),
    );
  }
}
