import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:bip_key_derivation/keystore.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/progressHUD.dart';

class WalletOperation extends StatefulWidget {
  final WalletEntity walletEntity;
  WalletOperation({this.walletEntity});

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
              style: Theme.of(context).textTheme.body1,
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
            WalletEntity walletEntity = await WalletStorage.read(
                widget.walletEntity.name, widget.walletEntity.network);
            await BipKeyDerivation.decryptedByKeystore(
              walletEntity.keystore,
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
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: Theme.of(context).cardTheme.shape,
                    title: Text('Keystore'),
                    content: Wrap(
                      children: <Widget>[
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: TextField(
                              style: Theme.of(context).textTheme.body1,
                              readOnly: true,
                              enableInteractiveSelection: true,
                              maxLines: null,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              controller: TextEditingController(
                                  text: json
                                      .encode(walletEntity.keystore.encoded)),
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
                    style: Theme.of(context).textTheme.body1,
                  ),
                  TextField(
                    controller: newPasswordController,
                    maxLength: 20,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'New Password',
                    ),
                    style: Theme.of(context).textTheme.body1,
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
            WalletEntity walletEntity = await WalletStorage.read(
                widget.walletEntity.name, widget.walletEntity.network);
            Uint8List privateKey = await BipKeyDerivation.decryptedByKeystore(
              walletEntity.keystore,
              originalPassword,
            );
            KeyStore newKeyStore =
                await BipKeyDerivation.encrypt(privateKey, newPassword);
            await WalletStorage.write(
              walletEntity: WalletEntity(
                keystore: newKeyStore,
                name: walletEntity.name,
                network: await NetworkStorage.network,
              ),
            );
            await alert(
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
              style: Theme.of(context).textTheme.body1,
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
            WalletEntity walletEntity = await WalletStorage.read(
                widget.walletEntity.name, widget.walletEntity.network);
            await BipKeyDerivation.decryptedByKeystore(
              walletEntity.keystore,
              password,
            );
            await WalletStorage.delete(
              walletEntity.name,
              await NetworkStorage.network,
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
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('Operation'),
        centerTitle: true,
      ),
      body: ProgressHUD(
        child: Container(
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
                  style: TextStyle(
                    fontSize: 18,
                  ),
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
