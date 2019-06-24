import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/models/keyStore.dart';
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
  TextEditingController passwordController = TextEditingController();
  TextEditingController originalPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  bool loading = false;

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
          Navigator.pop(context);
          setState(() {
            loading = true;
          });
          try {
            await compute(
              decrypt,
              Decriptions(keystore: wallet.keystore, password: password),
            );
            setState(() {
              loading = false;
            });
            await showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) {
                  return AlertDialog(
                    title: Text('KeyStore'),
                    content: Container(
                      height: 380,
                      child: Column(
                        children: <Widget>[
                          Card(
                            child: Container(
                              padding: EdgeInsets.all(15),
                              child: Text(
                                json.encode(wallet.keystore.encoded),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                height: 50,
                                child: FlatButton(
                                  child: Text(
                                    'copy',
                                    style: TextStyle(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      new ClipboardData(
                                        text: json
                                            .encode(wallet.keystore.encoded),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                });
          } catch (err) {
            return alert(
              context,
              Text('Warnning'),
              "Password Invalid",
            );
          } finally {
            setState(() {
              loading = false;
            });
          }
        }, cancelAction: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          Navigator.pop(context);
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
                    decoration: InputDecoration(
                      hintText: 'Original Password',
                    ),
                  ),
                  TextField(
                    controller: newPasswordController,
                    maxLength: 20,
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
          Navigator.pop(context);
          setState(() {
            loading = true;
          });
          try {
            Uint8List privateKey = await compute(
              decrypt,
              Decriptions(
                  keystore: wallet.keystore, password: originalPassword),
            );
            KeyStore newKeyStore =
                await KeyStore.encrypt(privateKey, newPassword);
            await WalletStorage.write(
              walletEntity:
                  WalletEntity(keystore: newKeyStore, name: wallet.name),
              isMainWallet: true,
            );
            return alert(
                context, Text('Success'), 'Password changed successfully');
          } catch (err) {
            return alert(
              context,
              Text('Warnning'),
              "Password incorrect",
            );
          } finally {
            setState(() {
              loading = false;
            });
          }
        }, cancelAction: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          Navigator.pop(context);
        });
      }),
      buildCell("Delete wallet", () async {
        customAlert(context,
            title: Text('Delete wallet'),
            content: TextField(
              controller: passwordController,
              maxLength: 20,
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
          Navigator.pop(context);
          setState(() {
            loading = true;
          });
          try {
            await compute(
              decrypt,
              Decriptions(keystore: wallet.keystore, password: password),
            );
            await WalletStorage.delete(wallet.name);
            Navigator.popUntil(
                context, ModalRoute.withName(ManageWallets.routeName));
          } catch (err) {
            return alert(
              context,
              Text('Warnning'),
              "Password Invalid",
            );
          } finally {
            setState(() {
              loading = false;
            });
          }
        }, cancelAction: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          Navigator.pop(context);
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
        child: ListView(
          children: widgets,
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
