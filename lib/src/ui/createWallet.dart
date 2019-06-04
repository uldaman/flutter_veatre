import 'dart:math';

import 'package:veatre/src/ui/ProgressHUD.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/generateMnemonic.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/bip39/mnemonic.dart';
import 'package:veatre/src/storage/storage.dart';

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
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Create Wallet'),
        centerTitle: true,
      ),
      body: ProgressHUD(
        isLoading: loading,
        child: Center(
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 30),
                child: TextField(
                  controller: walletNameController,
                  maxLength: 20,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.lightBlue,
                      ),
                    ),
                    hintText: 'Wallet Name',
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              ),
              Container(
                child: TextField(
                  controller: passwordController,
                  maxLength: 20,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.lightBlue,
                      ),
                    ),
                    hintText: 'Password',
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              ),
              Container(
                child: TextField(
                  controller: repeatPasswordController,
                  maxLength: 20,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.lightBlue,
                      ),
                    ),
                    hintText: 'Repeat password',
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
                    setState(() {
                      this.loading = true;
                    });
                    String walletName = walletNameController.text;
                    String password = passwordController.text;
                    String repeatPassword = repeatPasswordController.text;
                    if (walletName.isEmpty) {
                      setState(() {
                        this.loading = false;
                      });
                      return alert(context, Text("Warnning"),
                          "Wallet name can't be empty!");
                    }
                    if (password.isEmpty || repeatPassword.isEmpty) {
                      setState(() {
                        this.loading = false;
                      });
                      return alert(context, Text("Warnning"),
                          "Password can't be empty!");
                    }
                    if (password != repeatPassword) {
                      setState(() {
                        this.loading = false;
                      });
                      return alert(context, Text("Warnning"),
                          "Password is inconsistent");
                    }
                    WalletEntity wallet = await WalletStorage.read(walletName);
                    if (wallet != null) {
                      setState(() {
                        this.loading = false;
                      });
                      return alert(context, Text("Warnning"),
                          "This wallet name has been already existed");
                    }
                    String mnemonic =
                        await Mnemonic.generateMnemonic(randomBytes(32));
                    List<String> words = await Mnemonic.populateWordList();
                    List<List<String>> randomWordsList = List<List<String>>();
                    List<String> mnemonics = mnemonic.split(" ");
                    for (int i = 0; i < 6; i++) {
                      List<String> randomWords =
                          mnemonics.sublist(i * 4, (i + 1) * 4);
                      while (randomWords.length < 12) {
                        Random random = Random();
                        int index = random.nextInt(2048);
                        String word = words[index];
                        if (!randomWords.contains(word)) {
                          randomWords.add(word);
                        }
                      }
                      randomWords.shuffle();
                      randomWordsList.add(randomWords);
                    }
                    setState(() {
                      this.loading = false;
                    });
                    Navigator.pushNamed(context, GenerateMnemonic.routeName,
                        arguments: WalletArguments(
                            walletName, password, mnemonics, randomWordsList));
                  },
                ),
                width: MediaQuery.of(context).size.width - 40,
                height: 50,
              )
            ],
          ),
        ),
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
