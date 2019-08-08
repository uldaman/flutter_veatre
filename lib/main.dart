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

Timer _timer;

void main() {
  runZoned(() async {
    await initialGlobals();
    // await syncHead();
    runApp(App());
  }, onError: (dynamic err, StackTrace stack) {
    print("unhandled error: $err");
    print("stack: $stack");
  });
}

Future<void> initialGlobals() async {
  Globals.connexJS = await rootBundle.loadString("assets/connex.js");
  Globals.testNetWallets = await WalletStorage.wallets(Network.TestNet);
  Globals.mainNetWallets = await WalletStorage.wallets(Network.TestNet);
  Globals.mainNetHeadController =
      HeadController(BlockHead.fromJSON(Globals.testNetGenesis.encoded));
  Globals.testNetHeadController =
      HeadController(BlockHead.fromJSON(Globals.mainNetGenesis.encoded));
}

Future<void> syncHead() async {
  // BlockHead _testNetCurrentHead =
  //     BlockHead.fromJSON(Globals.testNetGenesis.encoded);
  // BlockHead _mainNetCurrentHead = Globals.mainNetGenesis.encoded;
  // try {
  //   _mainNetCurrentHead = await Net.head(Globals.mainNet);
  //   _testNetCurrentHead = await Net.head(Globals.testNet);
  // } catch (e) {
  //   print("network error: $e");
  // }
  Globals.mainNetHeadController =
      HeadController(BlockHead.fromJSON(Globals.testNetGenesis.encoded));
  Globals.testNetHeadController =
      HeadController(BlockHead.fromJSON(Globals.mainNetGenesis.encoded));
  // _timer = Timer.periodic(Duration(seconds: 10), (time) async {
  //   try {
  //     bool isMainNet = await NetworkStorage.isMainNet;
  //     Block head;
  //     if (isMainNet) {
  //       head = await Net.head(Globals.mainNet);
  //       if (head.number != _mainNetCurrentHead.number) {
  //         _mainNetCurrentHead = head;
  //         Globals.mainNetHeadController.value = _mainNetCurrentHead;
  //       }
  //     } else {
  //       head = await Net.head(Globals.testNet);
  //       if (head.number != _testNetCurrentHead.number) {
  //         _testNetCurrentHead = head;
  //         Globals.testNetHeadController.value = _testNetCurrentHead;
  //       }
  //     }
  //     await syncActivities(isMainNet, head.number);
  //   } catch (e) {
  //     print("sync block error: $e");
  //   }
  // });
}

// Future<void> syncActivities(bool isMainNet, int headNumber) async {
//   List<Activity> activities = await ActivityStorage.queryPendings(isMainNet);
//   for (Activity activity in activities) {
//     String txID = activity.hash;
//     final net = isMainNet ? Globals.mainNet : Globals.testNet;
//     Map<String, dynamic> receipt = await net.getReceipt(txID);
//     if (receipt != null) {
//       int processBlock = receipt['meta']['blockNumber'];
//       if (activity.processBlock == null) {
//         await ActivityStorage.update(
//             activity.id, {'processBlock': processBlock});
//       }
//       bool reverted = receipt['reverted'];
//       if (reverted) {
//         await ActivityStorage.update(
//             activity.id, {'status': ActivityStatus.Reverted.index});
//       } else if (headNumber - processBlock >= 12) {
//         await ActivityStorage.update(
//             activity.id, {'status': ActivityStatus.Finished.index});
//       }
//     } else if (headNumber - activity.block >= 30) {
//       await ActivityStorage.update(
//           activity.id, {'status': ActivityStatus.Expired.index});
//     }
//   }
// }

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    Globals.mainNetHeadController.addListener(_syncMainetActivities);
    Globals.testNetHeadController.addListener(_syncTestNetActivities);
  }

  Future<void> _syncActivities(Network network) async {
    int headNumber = Globals.headControllerFor(network).value.number;
    List<Activity> activities = await ActivityStorage.queryPendings(network);
    for (Activity activity in activities) {
      String txID = activity.hash;
      final net = Globals.netFor(network);
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

  Future<void> _syncMainetActivities() async {
    await _syncActivities(Network.MainNet);
  }

  Future<void> _syncTestNetActivities() async {
    await _syncActivities(Network.TestNet);
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
    Globals.testNetHeadController.dispose();
    Globals.mainNetHeadController.dispose();
    _timer.cancel();
    super.dispose();
  }
}
