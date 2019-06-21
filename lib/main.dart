import 'package:flutter/material.dart';
import 'package:veatre/common/driver.dart';
import 'package:veatre/navigation.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/walletDetail.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/importWallet.dart';
import 'package:veatre/src/ui/generateMnemonic.dart';
import 'package:veatre/src/ui/verifyMnemonic.dart';

void main() {
  // debugPaintSizeEnabled = true;
  // Vechain().getBlockByHash("hash");
  driver.syncHead().then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        Navigation.routeName: (context) => new Navigation(),
        ManageWallets.routeName: (context) => new ManageWallets(),
        WalletDetail.routeName: (context) => new WalletDetail(),
        CreateWallet.routeName: (context) => new CreateWallet(),
        ImportWallet.routeName: (context) => new ImportWallet(),
        GenerateMnemonic.routeName: (context) => new GenerateMnemonic(),
        VerifyMnemonic.routeName: (context) => new VerifyMnemonic(),
      },
      theme: new ThemeData(
        primarySwatch: Colors.blue,
        primaryColorBrightness: Brightness.light,
        primaryColor: Colors.blue,
        primaryIconTheme: IconThemeData(color: Colors.black),
        primaryTextTheme: TextTheme(
          title: TextStyle(color: Colors.black, fontFamily: "Aveny"),
        ),
        textTheme: TextTheme(title: TextStyle(color: Colors.black)),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.lightBlue,
            ),
          ),
        ),
      ),
    );
  }
}
