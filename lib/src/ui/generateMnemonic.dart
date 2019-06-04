import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/verifyMnemonic.dart';

class GenerateMnemonic extends StatefulWidget {
  static const routeName = '/wallet/mnemonic/generation';

  GenerateMnemonic() : super();

  @override
  GenerateMnemonicState createState() => GenerateMnemonicState();
}

class GenerateMnemonicState extends State<GenerateMnemonic> {
  @override
  Widget build(BuildContext context) {
    final WalletArguments args = ModalRoute.of(context).settings.arguments;
    List<String> mnemonics = args.mnemonics;
    List<Widget> widgets = [];

    for (int i = 0; i < mnemonics.length; i++) {
      String word = mnemonics[i];
      Widget widget = Container(
        child: Text(
          word,
          textAlign: TextAlign.center,
        ),
        width: (MediaQuery.of(context).size.width - 60) * 0.25,
      );
      widgets.add(widget);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Generate Mnemonic'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(10),
            child: Text(
              "Mnemonic phrase is a list of words that store all the information needed for the recovery of a wallet. Please write it down on paper.if you forget the private key, You would be able to upload the same wallet and use the paper backup copy to get your tokens back. As every owner of a mnemonic phrase gets an access to the wallet, it must be kept very carefully.",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
          Card(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: widgets.sublist(0, 4),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: widgets.sublist(4, 8),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: widgets.sublist(8, 12),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: widgets.sublist(12, 16),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: widgets.sublist(16, 20),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: widgets.sublist(20, 24),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            margin: EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width - 40,
            child: RaisedButton(
              child: Text(
                "OK",
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.blue,
              onPressed: () {
                print("ok");
                Navigator.pushNamed(context, VerifyMnemonic.routeName,
                    arguments: args);
              },
            ),
          )
        ],
      ),
    );
  }
}
