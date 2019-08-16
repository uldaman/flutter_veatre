import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veatre/src/api/BlockAPI.dart';

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
    BlockHeadForNetwork(
      head: BlockHead.fromJSON(Globals.mainNetGenesis.encoded),
      network: Network.MainNet,
    ),
  );
  Globals.setHead(
    BlockHeadForNetwork(
      head: BlockHead.fromJSON(Globals.testNetGenesis.encoded),
      network: Network.TestNet,
    ),
  );
}

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  Timer _timer;

  @override
  void initState() {
    super.initState();
    Globals.periodic(10, (timer) async {
      try {
        final currentNet = await NetworkStorage.currentNet;
        final block = await BlockAPI.best(currentNet);
        final newHead = BlockHead.fromJSON(block.encoded);
        final head = Globals.head(currentNet);
        if (head.id != newHead.id && newHead.number > head.number) {
          final blockHeadForNetwork = BlockHeadForNetwork(
            head: newHead,
            network: currentNet,
          );
          Globals.updateBlockHead(blockHeadForNetwork);
          await _syncActivities(blockHeadForNetwork);
        }
      } catch (e) {
        print('sync head error: $e');
      }
    });
  }

  Future<void> _syncActivities(BlockHeadForNetwork blockHeadForNetwork) async {
    int headNumber = blockHeadForNetwork.head.number;
    List<Activity> activities =
        await ActivityStorage.queryPendings(blockHeadForNetwork.network);
    for (Activity activity in activities) {
      String txID = activity.hash;
      final net = Globals.net(blockHeadForNetwork.network);
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        MainUI.routeName: (context) => new MainUI(),
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
    _timer.cancel();
    super.dispose();
  }
}
