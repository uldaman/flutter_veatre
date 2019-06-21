import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/keyStore.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/ui/wallets.dart';
import 'package:veatre/src/ui/alert.dart';

import 'package:veatre/src/storage/storage.dart';

class SignCertificateDialog extends StatefulWidget {
  final SigningCertMessage certMessage;
  final SigningCertOptions options;

  SignCertificateDialog({this.certMessage, this.options});

  @override
  SignCertificateDialogState createState() => SignCertificateDialogState();
}

class SignCertificateDialogState extends State<SignCertificateDialog> {
  bool loading = true;
  Wallet wallet;
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    void Function(WalletEntity walletEntity) setWallet =
        (WalletEntity walletEntity) async {
      Account acc = await AccountAPI.get(walletEntity.keystore.address);
      setState(() {
        this.wallet = Wallet(
          account: acc,
          keystore: walletEntity.keystore,
          name: walletEntity.name,
        );
      });
      setState(() {
        this.loading = false;
      });
    };

    getWalletEntity(widget.options.signer).then((walletEntity) {
      setWallet(walletEntity);
    });
  }

  Future<WalletEntity> getWalletEntity(String signer) async {
    if (signer != null) {
      List<WalletEntity> walletEntities = await WalletStorage.readAll();
      for (WalletEntity walletEntity in walletEntities) {
        if ('0x' + walletEntity.keystore.address == signer) {
          return walletEntity;
        }
      }
    }
    WalletEntity mianWalletEntity = await WalletStorage.getMainWallet();
    if (mianWalletEntity != null) {
      return mianWalletEntity;
    }
    List<WalletEntity> walletEntities = await WalletStorage.readAll();
    return walletEntities[0];
  }

  showWallets() async {
    final Wallet selectedWallet = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new Wallets()),
    );
    if (selectedWallet != null) {
      setState(() {
        loading = true;
        this.wallet = selectedWallet;
      });
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Sign Certificate'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            size: 25,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.menu,
              size: 25,
              color: Colors.blue,
            ),
            onPressed: () async {
              await showWallets();
            },
          )
        ],
      ),
      body: ProgressHUD(
        child: Column(
          children: <Widget>[
            GestureDetector(
              child: Container(
                child: Card(
                  margin: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 100,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF81269D),
                              const Color(0xFFEE112D)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Container(
                                padding: EdgeInsets.all(15),
                                child: Text(
                                  wallet == null ? '' : wallet.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 15, right: 15),
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                wallet == null
                                    ? ''
                                    : '0x' + wallet.keystore.address,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(wallet == null
                                ? '0'
                                : wallet.account.formatBalance()),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 14),
                              child: Text(
                                'VET',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(wallet == null
                                ? '0'
                                : wallet.account.formatEnergy()),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                'VTHO',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                height: 195,
              ),
              onTap: () async {
                await showWallets();
              },
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      alignment: Alignment.topLeft,
                      margin: EdgeInsets.all(20),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.certMessage.payload.content,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height: 50,
                          child: FlatButton(
                            color: Colors.blue,
                            child: Text(
                              'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await customAlert(context,
                                  title: Text('Sign Certificate'),
                                  content: TextField(
                                    controller: passwordController,
                                    maxLength: 20,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.lightBlue,
                                        ),
                                      ),
                                      hintText: 'Input your password',
                                    ),
                                  ), confirmAction: () async {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
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
                                Uint8List privateKey;
                                try {
                                  privateKey = await compute(
                                    decrypt,
                                    Decriptions(
                                        keystore: wallet.keystore,
                                        password: password),
                                  );
                                } catch (err) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return alert(
                                    context,
                                    Text('Warnning'),
                                    "Password Invalid",
                                  );
                                }
                                try {
                                  Certificate cert = Certificate(
                                    certMessage: widget.certMessage,
                                    timestamp: new DateTime.now()
                                            .millisecondsSinceEpoch ~/
                                        1000,
                                    domain: widget.options.link,
                                  );
                                  cert.sign(privateKey);
                                  await WalletStorage.setMainWallet(
                                    WalletEntity(
                                      keystore: wallet.keystore,
                                      name: wallet.name,
                                    ),
                                  );
                                  Navigator.of(context).pop(cert.encoded);
                                } catch (err) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return alert(
                                      context, Text("Error"), "Unkown error");
                                } finally {
                                  setState(() {
                                    loading = false;
                                  });
                                }
                              }, cancelAction: () async {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                Navigator.pop(context);
                              });
                            },
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
        isLoading: loading,
      ),
    );
  }
}
