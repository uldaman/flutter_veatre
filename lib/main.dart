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

WalletsChangedController walletsChangedController;
GenesisChangedController genesisChangedController;
HeadValueController headValueController;

void main() async {
  walletsChangedController =
      WalletsChangedController(await WalletStorage.wallets);
  genesisChangedController = GenesisChangedController(driver.genesis);
  Block _currentHead = driver.genesis;
  try {
    _currentHead = Block.fromJSON(await driver.head);
  } catch (e) {
    print("network error: $e");
  }
  headValueController = HeadValueController(_currentHead);
  Timer _timer = Timer.periodic(Duration(seconds: 10), (time) async {
    try {
      Block head = Block.fromJSON(await driver.head);
      if (head.number != _currentHead.number) {
        _currentHead = head;
        headValueController.value = _currentHead;
      }
    } catch (e) {
      print("sync block error: $e");
    }
  });
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        // Navigation.routeName: (context) => new Navigation(),
        MainUI.routeName: (context) => new MainUI(),
        Settings.routeName: (context) => new Settings(),
        ManageWallets.routeName: (context) => new ManageWallets(),
        Activities.routeName: (context) => new Activities(),
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
}
