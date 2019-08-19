import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:bip_key_derivation/keystore.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/progressHUD.dart';

class WalletOperation extends StatefulWidget {
  final Wallet wallet;
  WalletOperation({this.wallet});

  @override
  WalletOperationState createState() => WalletOperationState();
}

class WalletOperationState extends State<WalletOperation> {
  TextEditingController keystoreBackUpController;
  TextEditingController passwordController = TextEditingController();
  TextEditingController originalPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    keystoreBackUpController = TextEditingController(
      text: json.encode(widget.wallet.keystore.encoded),
    );
  }

  @override
  Widget build(BuildContext context) {
    Wallet wallet = widget.wallet;
    List<Widget> widgets = [];
    widgets.addAll([
      buildCell("Backup wallet", () async {
        customAlert(context,
            title: Text('Backup wallet'),
            content: TextField(
              controller: passwordController,
              maxLength: 20,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Password',
              ),
            ), confirmAction: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          String password = passwordController.text;
          if (password.isEmpty) {
            return alert(
              context,
              Text('Warnning'),
              "Password can't be empty",
            );
          }
          passwordController.clear();
          Navigator.pop(context);
          setState(() {
            loading = true;
          });
          try {
            await BipKeyDerivation.decryptedByKeystore(
              wallet.keystore,
              password,
            );
            setState(() {
              loading = false;
            });
            await showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) {
                  return AlertDialog(
                    contentPadding: EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text('Keystore'),
                    content: Wrap(
                      children: <Widget>[
                        Card(
                          color: Colors.grey[100],
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: TextField(
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                              readOnly: true,
                              enableInteractiveSelection: true,
                              maxLines: null,
                              decoration:
                                  InputDecoration(border: InputBorder.none),
                              controller: keystoreBackUpController,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                });
          } catch (err) {
            return alert(
              context,
              Text('Warnning'),
              err.toString(),
            );
          } finally {
            setState(() {
              loading = false;
            });
          }
        }, cancelAction: () async {
          passwordController.clear();
          FocusScope.of(context).requestFocus(FocusNode());
        });
      }),
      buildCell("Change password", () async {
        customAlert(context,
            title: Text('Change wallet password'),
            content: Container(
              height: 170,
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: originalPasswordController,
                    maxLength: 20,
                    autofocus: true,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Original Password',
                    ),
                  ),
                  TextField(
                    controller: newPasswordController,
                    maxLength: 20,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'New Password',
                    ),
                  ),
                ],
              ),
            ), confirmAction: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          String originalPassword = originalPasswordController.text;
          String newPassword = newPasswordController.text;
          if (originalPassword.isEmpty || newPassword.isEmpty) {
            return alert(
              context,
              Text('Warnning'),
              "Password can't be empty",
            );
          }
          if (bool.fromEnvironment('dart.vm.product') &&
              newPassword.length < 6) {
            return alert(context, Text("Warnning"),
                "Password must be 6 characters at least!");
          }
          originalPasswordController.clear();
          newPasswordController.clear();
          Navigator.pop(context);
          setState(() {
            loading = true;
          });
          try {
            Uint8List privateKey = await BipKeyDerivation.decryptedByKeystore(
              wallet.keystore,
              originalPassword,
            );
            KeyStore newKeyStore =
                await BipKeyDerivation.encrypt(privateKey, newPassword);
            await WalletStorage.write(
              walletEntity:
                  WalletEntity(keystore: newKeyStore, name: wallet.name),
              network: await NetworkStorage.currentNet,
            );
            return alert(
                context, Text('Success'), 'Password changed successfully');
          } catch (err) {
            return alert(
              context,
              Text('Warnning'),
              err.toString(),
            );
          } finally {
            setState(() {
              loading = false;
            });
          }
        }, cancelAction: () async {
          originalPasswordController.clear();
          newPasswordController.clear();
          FocusScope.of(context).requestFocus(FocusNode());
        });
      }),
      buildCell("Delete wallet", () async {
        customAlert(context,
            title: Text('Delete wallet'),
            content: TextField(
              controller: passwordController,
              maxLength: 20,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Password',
              ),
            ), confirmAction: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          String password = passwordController.text;
          if (password.isEmpty) {
            return alert(
              context,
              Text('Warnning'),
              "Password can't be empty",
            );
          }
          passwordController.clear();
          Navigator.pop(context);
          setState(() {
            loading = true;
          });
          try {
            await BipKeyDerivation.decryptedByKeystore(
              wallet.keystore,
              password,
            );
            await WalletStorage.delete(
              wallet.name,
              await NetworkStorage.currentNet,
            );
            Navigator.popUntil(
                context, ModalRoute.withName(ManageWallets.routeName));
          } catch (err) {
            return alert(
              context,
              Text('Warnning'),
              err.toString(),
            );
          } finally {
            setState(() {
              loading = false;
            });
          }
        }, cancelAction: () async {
          passwordController.clear();
          FocusScope.of(context).requestFocus(FocusNode());
        });
      }),
    ]);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Operation'),
        centerTitle: true,
      ),
      body: ProgressHUD(
        child: Container(
          color: Colors.grey[100],
          child: ListView(
            padding: EdgeInsets.only(top: 8),
            children: widgets,
          ),
        ),
        isLoading: loading,
      ),
    );
  }

  Widget buildCell(String title, Future Function() onTap) {
    return Container(
      child: GestureDetector(
        onTap: () {
          onTap();
        },
        child: Card(
          child: Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 20),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      FontAwesomeIcons.angleRight,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      height: 60,
    );
  }
}
