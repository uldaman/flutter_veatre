import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/models/keyStore.dart';
import 'package:veatre/src/models/account.dart';

import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletDetail extends StatefulWidget {
  static const routeName = '/wallet/detail';
  @override
  WalletDetailState createState() => WalletDetailState();
}

class WalletDetailState extends State<WalletDetail> {
  TextEditingController passwordController = TextEditingController();

  TextEditingController originalPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();

  bool loading = false;
  @override
  Widget build(BuildContext context) {
    Wallet wallet = ModalRoute.of(context).settings.arguments;
    return ProgressHUD(
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Details'),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              child: Card(
                child: Stack(
                  children: <Widget>[
                    new QrImage(
                      padding: EdgeInsets.all(100),
                      data: '0x' + wallet.keystore.address,
                      size: MediaQuery.of(context).size.width,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 25),
                      width: MediaQuery.of(context).size.width,
                      child: Text(
                        wallet.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                          top: MediaQuery.of(context).size.width - 60),
                      width: MediaQuery.of(context).size.width,
                      child: GestureDetector(
                        child: Text(
                          '0x' + wallet.keystore.address,
                          textAlign: TextAlign.center,
                        ),
                        onLongPress: () async {
                          await Clipboard.setData(new ClipboardData(
                              text: '0x' + wallet.keystore.address));
                          showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) {
                                return AlertDialog(
                                  content: Text('Copied to clipboard'),
                                );
                              });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            buildCell("delete wallet", () async {
              customAlert(context,
                  title: Text('Are you sure to delete your wallet?'),
                  content: Theme(
                    data: ThemeData(
                      primaryColor: Colors.blue,
                      primaryColorDark: Colors.blueAccent,
                    ),
                    child: TextField(
                      controller: passwordController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.lightBlue,
                          ),
                        ),
                        hintText: 'Password',
                      ),
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
            buildCell("backup wallet", () async {
              customAlert(context,
                  title: Text('Back up your wallet'),
                  content: Theme(
                    data: ThemeData(
                      primaryColor: Colors.blue,
                      primaryColorDark: Colors.blueAccent,
                    ),
                    child: TextField(
                      controller: passwordController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.lightBlue,
                          ),
                        ),
                        hintText: 'Password',
                      ),
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
                          content: GestureDetector(
                            onLongPress: () async {
                              await Clipboard.setData(
                                new ClipboardData(
                                  text: json.encode(wallet.keystore.encoded),
                                ),
                              );
                              showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    return AlertDialog(
                                      content: Text('Copied to clipboard'),
                                    );
                                  });
                            },
                            child: Text(
                              json.encode(wallet.keystore.encoded),
                            ),
                          ),
                        );
                      });

                  Navigator.popUntil(
                      context, ModalRoute.withName(WalletDetail.routeName));
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
            buildCell("change password", () async {
              customAlert(context,
                  title: Text('Are you sure to delete your wallet?'),
                  content: Container(
                    height: 170,
                    child: Column(
                      children: <Widget>[
                        Theme(
                          data: ThemeData(
                            primaryColor: Colors.blue,
                            primaryColorDark: Colors.blueAccent,
                          ),
                          child: TextField(
                            controller: originalPasswordController,
                            maxLength: 20,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.lightBlue,
                                ),
                              ),
                              hintText: 'Original Password',
                            ),
                          ),
                        ),
                        Theme(
                          data: ThemeData(
                            primaryColor: Colors.blue,
                            primaryColorDark: Colors.blueAccent,
                          ),
                          child: TextField(
                            controller: newPasswordController,
                            maxLength: 20,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.lightBlue,
                                ),
                              ),
                              hintText: 'New Password',
                            ),
                          ),
                        )
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
                  KeyStore newKeyStore = await KeyStore.encrypt(
                      bytesToHex(privateKey), newPassword);
                  await WalletStorage.write(
                    walletEntity:
                        WalletEntity(keystore: newKeyStore, name: wallet.name),
                    isMainWallet: true,
                  );
                  return alert(context, Text('Success'),
                      'Password changed successfully');
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
          ],
        ),
      ),
      isLoading: loading,
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
