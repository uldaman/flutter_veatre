import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/importWallet.dart';
import 'package:veatre/src/ui/mainUI.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/network.dart';
import 'package:veatre/common/globals.dart';

void main() {
  runZoned(() async {
    await initialGlobals();
    runApp(App());
  }, onError: (dynamic err, StackTrace stack) {
    print("unhandled error: $err");
    print("stack: $stack");
  });
}

Future<void> initialGlobals() async {
  Globals.connexJS = await rootBundle.loadString("assets/connex.js");
  Globals.mainNetWallets = await WalletStorage.wallets(Network.MainNet);
  Globals.testNetWallets = await WalletStorage.wallets(Network.TestNet);
  Globals.setHead(
      Network.MainNet, BlockHead.fromJSON(Globals.mainNetGenesis.encoded));
  Globals.setHead(
      Network.TestNet, BlockHead.fromJSON(Globals.testNetGenesis.encoded));
}

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    Globals.watchBlockHead((blockHeadForNetwork) async {
      await _syncActivities(
        blockHeadForNetwork.network,
        blockHeadForNetwork.blockHead,
      );
    });
  }

  Future<void> _syncActivities(Network network, BlockHead blockHead) async {
    int headNumber = blockHead.number;
    List<Activity> activities = await ActivityStorage.queryPendings(network);
    for (Activity activity in activities) {
      String txID = activity.hash;
      final net = Globals.net(network);
      Map<String, dynamic> receipt = await net.getReceipt(txID);
      if (receipt != null) {
        int processBlock = receipt['meta']['blockNumber'];
        if (activity.processBlock == null) {
          await ActivityStorage.update(
              activity.id, {'processBlock': processBlock});
        }
        bool reverted = receipt['reverted'];
        if (reverted) {
          await ActivityStorage.update(
              activity.id, {'status': ActivityStatus.Reverted.index});
        } else if (headNumber - processBlock >= 12) {
          await ActivityStorage.update(
              activity.id, {'status': ActivityStatus.Finished.index});
        }
      } else if (headNumber - activity.block >= 30) {
        await ActivityStorage.update(
            activity.id, {'status': ActivityStatus.Expired.index});
      }
    }
  }

  // Future<void> _syncMainetActivities() async {
  //   await _syncActivities(Network.MainNet);
  // }

  // Future<void> _syncTestNetActivities() async {
  //   await _syncActivities(Network.TestNet);
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        MainUI.routeName: (context) => new MainUI(),
        // TestUI.routeName: (context) => new TestUI(),
        Settings.routeName: (context) => new Settings(),
        ManageWallets.routeName: (context) => new ManageWallets(),
        Networks.routeName: (context) => new Networks(),
        CreateWallet.routeName: (context) => new CreateWallet(),
        ImportWallet.routeName: (context) => new ImportWallet(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColorBrightness: Brightness.light,
        primaryColor: Colors.blue,
        primaryIconTheme: IconThemeData(color: Colors.black),
        primaryTextTheme: TextTheme(
          title: TextStyle(color: Colors.black, fontFamily: "Aveny"),
        ),
        textTheme: TextTheme(title: TextStyle(color: Colors.black)),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Globals.destory();
    super.dispose();
  }
}
