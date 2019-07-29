import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:veatre/common/driver.dart';
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

WalletsController walletsController;
GenesisController genesisController;
HeadController headController;
Timer _timer;

void main() {
  runZoned(() async {
    walletsController =
        WalletsController(await WalletStorage.wallets);
    genesisController = GenesisController(await Driver.genesis);
    Block _currentHead = await Driver.genesis;
    try {
      Driver _driver = await Driver.instance;
      _currentHead = Block.fromJSON(await _driver.head);
    } catch (e) {
      print("network error: $e");
    }
    headController = HeadController(_currentHead);
    _timer = Timer.periodic(Duration(seconds: 10), (time) async {
      try {
        Driver _driver = await Driver.instance;
        Block head = Block.fromJSON(await _driver.head);
        if (head.number != _currentHead.number) {
          _currentHead = head;
          headController.value = _currentHead;
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
    headController.dispose();
    walletsController.dispose();
    genesisController.dispose();
    _timer.cancel();
    super.dispose();
  }
}
