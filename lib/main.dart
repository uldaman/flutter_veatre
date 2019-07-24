import 'package:flutter/material.dart';
import 'package:veatre/common/driver.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/activities.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/importWallet.dart';
import 'package:veatre/src/ui/mainUI.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/webView.dart';

List<String> wallets = [];

WalletsChangedController walletsChangedController;

GenesisChangedController genesisChangedController;

void main() async {
  wallets = await WalletStorage.wallets;
  walletsChangedController = WalletsChangedController(wallets);
  genesisChangedController = GenesisChangedController(driver.genesis);
  print("wallets $wallets");
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
