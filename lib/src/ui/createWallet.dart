import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/generateWallet.dart';
import 'package:veatre/src/storage/walletStorage.dart';

class CreateWallet extends StatefulWidget {
  static const routeName = '/wallets/creation';
  CreateWallet() : super();

  @override
  CreateWalletState createState() => CreateWalletState();
}

class CreateWalletState extends State<CreateWallet> {
  TextEditingController walletNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('Create Wallet'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 20),
            child: TextField(
              controller: walletNameController,
              maxLength: 20,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Wallet Name',
              ),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.body1.color,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          ),
          Container(
            child: TextField(
              controller: passwordController,
              maxLength: 20,
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
              ),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.body1.color,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          ),
          Container(
            child: TextField(
              controller: repeatPasswordController,
              maxLength: 20,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Repeat password',
              ),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.body1.color,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
          ),
          Container(
            child: RaisedButton(
              color: Colors.blue,
              child: Text(
                "Confirm",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                FocusScope.of(context).requestFocus(FocusNode());
                String walletName = walletNameController.text;
                String password = passwordController.text;
                String repeatPassword = repeatPasswordController.text;
                if (walletName.isEmpty) {
                  return alert(
                      context, Text("Warnning"), "Wallet name can't be empty!");
                }
                if (bool.fromEnvironment('dart.vm.product') &&
                    password.length < 6) {
                  return alert(context, Text("Warnning"),
                      "Password must be 6 characters at least!");
                }
                if (password.isEmpty || repeatPassword.isEmpty) {
                  return alert(
                      context, Text("Warnning"), "Password can't be empty!");
                }
                if (password != repeatPassword) {
                  return alert(
                      context, Text("Warnning"), "Password is inconsistent");
                }
                WalletEntity wallet = await WalletStorage.read(
                  walletName,
                  await NetworkStorage.network,
                );
                if (wallet != null) {
                  return alert(context, Text("Warnning"),
                      "This wallet name has been already existed");
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GenerateWallet(
                      walletName: walletName,
                      password: password,
                    ),
                  ),
                );
              },
            ),
            width: MediaQuery.of(context).size.width - 40,
            height: 50,
          )
        ],
      ),
    );
  }
}

class WalletArguments {
  String walletName;
  String password;
  List<String> mnemonics;
  List<List<String>> randomWordsList;
  WalletArguments(
      this.walletName, this.password, this.mnemonics, this.randomWordsList);
}
