import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/ui/authentication/decision.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/crypto.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/recoveryPhrasesBackup.dart';

class WalletOperation extends StatefulWidget {
  final WalletEntity walletEntity;
  WalletOperation({this.walletEntity});

  @override
  WalletOperationState createState() => WalletOperationState();
}

class WalletOperationState extends State<WalletOperation> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController walletNameController = TextEditingController();
  bool hasBackup;

  @override
  void initState() {
    hasBackup = widget.walletEntity.hasBackup;
    super.initState();
  }

  Future<void> updateBackup() async {
    final walletEntity = await WalletStorage.read(widget.walletEntity.address);
    setState(() {
      this.hasBackup = walletEntity.hasBackup;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advance'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.only(top: 10),
        children: [
          buildCell(
            "Change Wallet Name",
            onTap: () async {
              await customAlert(context,
                  title: Text('Input Wallet Name'),
                  content: Column(
                    children: <Widget>[
                      Text(
                        'Please input new wallet name to continue',
                        style: TextStyle(fontSize: 14),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: TextField(
                          autofocus: true,
                          controller: walletNameController,
                          maxLength: 10,
                          decoration: InputDecoration(
                              hintText: 'Please input wallet name'),
                        ),
                      ),
                    ],
                  ), confirmAction: () async {
                String walletName = walletNameController.text;
                if (walletName.isEmpty) {
                  return alert(context, Text('Incorrect Wallet Name'),
                      "Wallet name can't be empty");
                }
                await WalletStorage.updateName(
                    widget.walletEntity.address, walletName);
                Navigator.of(context).pop();
              });
              walletNameController.clear();
            },
          ),
          buildCell(
            "Backup Recovery Phrases",
            showWarnning: !hasBackup,
            onTap: () async {
              final bool isOK = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => Decision(
                    canCancel: true,
                    isForVerification: true,
                  ),
                  fullscreenDialog: true,
                ),
              );
              if (!isOK) return;
              String mnemonicCipher = widget.walletEntity.mnemonicCipher;
              String iv = widget.walletEntity.iv;
              Uint8List mnemonicData = AESCipher.decrypt(
                Globals.masterPasscodes,
                hexToBytes(mnemonicCipher),
                hexToBytes(iv),
              );
              String mnemonic = utf8.decode(mnemonicData);
              String name = ModalRoute.of(context).settings.name;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RecoveryPhraseBackup(
                    hasBackup: hasBackup,
                    mnemonic: mnemonic,
                    rootRouteName: name,
                  ),
                ),
              );
              await updateBackup();
            },
          ),
          buildCell(
            "Delete",
            important: true,
            centerTitle: true,
            showArrow: false,
            onTap: () async {
              final bool isOK = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => Decision(
                    canCancel: true,
                    isForVerification: true,
                  ),
                  fullscreenDialog: true,
                ),
              );
              if (!isOK) return;
              await customAlert(
                context,
                title: Text('Delete Wallet'),
                content: Text(
                  'Are you sure to delete this wallet',
                ),
                confirmAction: () async {
                  await WalletStorage.delete(widget.walletEntity.address);
                  Navigator.of(context)
                      .popUntil(ModalRoute.withName('/wallets'));
                },
              );
            },
          )
        ],
      ),
    );
  }

  Widget buildCell(
    String title, {
    bool showArrow = true,
    bool centerTitle = false,
    bool showWarnning = false,
    bool important = false,
    Future Function() onTap,
  }) {
    return Container(
      child: GestureDetector(
        onTapUp: (detail) async {
          if (onTap != null) {
            await onTap();
          }
        },
        child: Card(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    title,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      color: important
                          ? Theme.of(context).errorColor
                          : Theme.of(context).primaryTextTheme.display1.color,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              showArrow
                  ? Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Row(
                        children: <Widget>[
                          showWarnning
                              ? Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Icon(
                                    Icons.error,
                                    size: 20,
                                    color: Theme.of(context).errorColor,
                                  ),
                                )
                              : SizedBox(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 20,
                          )
                        ],
                      ),
                    )
                  : SizedBox(),
            ],
          ),
        ),
      ),
      height: 60,
    );
  }

  Future<Uint8List> verifyPassword() async {
    Uint8List password = await customAlert(context,
        title: Text('Input Master Code'),
        content: Column(
          children: <Widget>[
            Text(
              'Please input the master code to continue',
              style: TextStyle(fontSize: 14),
            ),
            Padding(
              padding: EdgeInsets.only(top: 15),
              child: TextField(
                autofocus: true,
                controller: passwordController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Master code'),
                maxLength: 6,
              ),
            ),
          ],
        ), confirmAction: () async {
      String password = passwordController.text;
      String masterPassHash = await Config.masterPassHash;
      String hash = bytesToHex(sha512(bytesToHex(sha256(password))));
      if (hash != masterPassHash) {
        Navigator.of(context).pop();
        return alert(context, Text('Incorrect Master Code'),
            'Please input correct master code');
      } else {
        await Globals.updateMasterPasscodes(password);
        Navigator.of(context).pop(Globals.masterPasscodes);
      }
    });
    passwordController.clear();
    return password;
  }
}
