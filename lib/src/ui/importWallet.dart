import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/importWalletGeneration.dart';

class ImportWallet extends StatefulWidget {
  final String rootRouteName;

  ImportWallet({
    @required this.rootRouteName,
  });

  @override
  ImportWalletState createState() => ImportWalletState();
}

class ImportWalletState extends State<ImportWallet> {
  TextEditingController mnemonicController = TextEditingController();
  String walletName = '';
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    generateWalletName();
  }

  Future<void> generateWalletName() async {
    int count = await WalletStorage.count() + 1;
    bool hasName = false;
    do {
      final name = "Account$count";
      hasName = await WalletStorage.hasName(name);
      if (hasName) {
        count++;
      } else {
        walletName = name;
      }
    } while (hasName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 10, top: 0),
                child: IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 30,
                ),
                child: SizedBox(
                  width: 300,
                  child: Text(
                    'Import Mnemonic',
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width - 60,
              height: 200,
              padding: EdgeInsets.only(top: 40),
              child: TextFormField(
                onChanged: (text) async {
                  setState(() {
                    errorMsg = '';
                  });
                },
                controller: mnemonicController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(10),
                  hintText: 'Please input mnemonic words seperated by space.',
                ),
                maxLines: 30,
                autofocus: true,
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                errorMsg,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 60,
              height: 44,
              child: FlatButton(
                color: Theme.of(context).textTheme.title.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  side: BorderSide(
                    color: Theme.of(context).textTheme.title.color,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Import',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () async {
                  String mnemonic = mnemonicController.text;
                  bool isValid =
                      await BipKeyDerivation.isValidMnemonic(mnemonic);
                  if (!isValid) {
                    return setState(() {
                      errorMsg = "Invalid Recovery phrases.";
                    });
                  }
                  String address;
                  try {
                    address = await addressFrom(mnemonic);
                  } catch (err) {
                    return setState(() {
                      errorMsg = (err as KeyError).message;
                    });
                  }
                  bool hasWallet = await WalletStorage.hasWallet(address);
                  if (hasWallet) {
                    await customAlert(
                      context,
                      title: Text('Wallet existed'),
                      content:
                          Text('Would you like to replace existed wallet.'),
                      confirmAction: () async {
                        await WalletStorage.updateName(address, walletName);
                        Navigator.of(context).pop();
                        await Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (context) => new ImportWalletGeneration(
                              address: address,
                              defaultWalletName: walletName,
                              rootRouteName: widget.rootRouteName,
                            ),
                          ),
                        );
                      },
                      cancelAction: () async {
                        return Navigator.pop(context);
                      },
                    );
                  } else {
                    await WalletStorage.saveWallet(
                      address,
                      walletName,
                      mnemonic,
                      Globals.masterPasscodes,
                    );
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ImportWalletGeneration(
                          address: address,
                          defaultWalletName: walletName,
                          rootRouteName: widget.rootRouteName,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
