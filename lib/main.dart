import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:veatre/common/driver.dart';
import 'package:veatre/common/net.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/activities.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/importWallet.dart';
import 'package:veatre/src/ui/mainUI.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/webView.dart';
import 'package:veatre/src/ui/network.dart';

WalletsController mainNetWalletsController;
WalletsController testNetWalletsController;

HeadController mainNetHeadController;
HeadController testNetHeadController;
Timer _timer;

void main() {
  runZoned(() async {
    mainNetWalletsController =
        WalletsController(await WalletStorage.wallets(Network.MainNet));
    testNetWalletsController =
        WalletsController(await WalletStorage.wallets(Network.TestNet));
    Block _testNetCurrentHead = testNetGenesis;
    Block _mainNetCurrentHead = mainNetGenesis;
    try {
      Net testNet = Net(NetworkStorage.testnet);
      Net mainNet = Net(NetworkStorage.mainnet);
      _mainNetCurrentHead = Block.fromJSON(await mainNet.getBlock());
      _testNetCurrentHead = Block.fromJSON(await testNet.getBlock());
    } catch (e) {
      print("network error: $e");
    }
    mainNetHeadController = HeadController(_mainNetCurrentHead);
    testNetHeadController = HeadController(_testNetCurrentHead);
    _timer = Timer.periodic(Duration(seconds: 10), (time) async {
      try {
        Block head = await Driver.head;
        if (await NetworkStorage.isMainNet) {
          if (head.number != _mainNetCurrentHead.number) {
            _mainNetCurrentHead = head;
            mainNetHeadController.value = _mainNetCurrentHead;
          }
        } else {
          if (head.number != _testNetCurrentHead.number) {
            _testNetCurrentHead = head;
            testNetHeadController.value = _testNetCurrentHead;
          }
        }
      } catch (e) {
        print("sync block error: $e");
      }
    });
    runApp(App());
  }, onError: (dynamic err, StackTrace stack) {
    print("unhandled error: $err");
    print("stack: $stack");
  });
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
        Activities.routeName: (context) => new Activities(),
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
