import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veatre/common/driver.dart';
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

class HeadController extends ValueNotifier<Block> {
  HeadController(Block value) : super(value);
}

class WalletsController extends ValueNotifier<List<String>> {
  WalletsController(List<String> value) : super(value);
}

WalletsController mainNetWalletsController;
WalletsController testNetWalletsController;

HeadController mainNetHeadController;
HeadController testNetHeadController;
Timer _timer;
String connexJS;
void main() {
  runZoned(() async {
    connexJS = await rootBundle.loadString("assets/connex.js");
    mainNetWalletsController =
        WalletsController(await WalletStorage.wallets(Network.MainNet));
    testNetWalletsController =
        WalletsController(await WalletStorage.wallets(Network.TestNet));
    await syncHead();
    runApp(App());
  }, onError: (dynamic err, StackTrace stack) {
    print("unhandled error: $err");
    print("stack: $stack");
  });
}

Future<void> syncHead() async {
  Block _testNetCurrentHead = testNetGenesis;
  Block _mainNetCurrentHead = mainNetGenesis;
  try {
    _mainNetCurrentHead = await Driver.head(mainNet);
    _testNetCurrentHead = await Driver.head(testNet);
  } catch (e) {
    print("network error: $e");
  }
  mainNetHeadController = HeadController(_mainNetCurrentHead);
  testNetHeadController = HeadController(_testNetCurrentHead);
  _timer = Timer.periodic(Duration(seconds: 10), (time) async {
    try {
      bool isMainNet = await NetworkStorage.isMainNet;
      Block head;
      if (isMainNet) {
        head = await Driver.head(mainNet);
        if (head.number != _mainNetCurrentHead.number) {
          _mainNetCurrentHead = head;
          mainNetHeadController.value = _mainNetCurrentHead;
        }
      } else {
        head = await Driver.head(testNet);
        if (head.number != _testNetCurrentHead.number) {
          _testNetCurrentHead = head;
          testNetHeadController.value = _testNetCurrentHead;
        }
      }
      await syncActivities(isMainNet, head.number);
    } catch (e) {
      print("sync block error: $e");
    }
  });
}

Future<void> syncActivities(bool isMainNet, int headNumber) async {
  List<Activity> activities = await ActivityStorage.queryPendings(isMainNet);
  for (Activity activity in activities) {
    String txID = activity.hash;
    final net = isMainNet ? mainNet : testNet;
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

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
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
    testNetHeadController.dispose();
    mainNetHeadController.dispose();
    testNetWalletsController.dispose();
    mainNetWalletsController.dispose();
    _timer.cancel();
    super.dispose();
  }
}
