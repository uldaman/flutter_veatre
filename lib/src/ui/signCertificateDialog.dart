import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/models/account.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/ui/wallets.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';

class SignCertificateDialog extends StatefulWidget {
  final SigningCertMessage certMessage;
  final SigningCertOptions options;
  final Network network;

  SignCertificateDialog({
    this.certMessage,
    this.options,
    this.network,
  });

  @override
  SignCertificateDialogState createState() => SignCertificateDialogState();
}

class SignCertificateDialogState extends State<SignCertificateDialog> {
  bool loading = true;
  Wallet wallet;
  WalletEntity walletEntity;
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getWalletEntity(widget.options.signer).then((walletEntity) {
      this.walletEntity = walletEntity;
      updateWallet().whenComplete(() {
        setState(() {
          this.loading = false;
        });
        Globals.watchBlockHead((blockHeadForNetwork) async {
          if (blockHeadForNetwork.network == widget.network) {
            await updateWallet();
          }
        });
      });
    });
  }

  Future<void> updateWallet() async {
    Wallet wallet = await walletFrom(walletEntity);
    if (mounted) {
      setState(() {
        this.wallet = wallet;
      });
    }
  }

  Future<WalletEntity> getWalletEntity(String signer) async {
    if (signer != null) {
      List<WalletEntity> walletEntities =
          await WalletStorage.readAll(widget.network);
      for (WalletEntity walletEntity in walletEntities) {
        if ('0x' + walletEntity.keystore.address == signer) {
          return walletEntity;
        }
      }
    }
    WalletEntity mianWalletEntity =
        await WalletStorage.getMainWallet(widget.network);
    if (mianWalletEntity != null) {
      return mianWalletEntity;
    }
    List<WalletEntity> walletEntities =
        await WalletStorage.readAll(widget.network);
    return walletEntities[0];
  }

  Future<void> showWallets() async {
    final WalletEntity walletEntity = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new Wallets(
          network: widget.network,
        ),
      ),
    );
    if (walletEntity != null) {
      this.walletEntity = walletEntity;
      await updateWallet();
    }
  }

  Future<Wallet> walletFrom(WalletEntity walletEntity) async {
    Account acc =
        await AccountAPI.get(walletEntity.keystore.address, widget.network);
    return Wallet(
      account: acc,
      keystore: walletEntity.keystore,
      name: walletEntity.name,
    );
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
              Icons.more_horiz,
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
                                : wallet.account.formatBalance),
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
                                : wallet.account.formatEnergy),
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
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Card(
                          color: Colors.grey[100],
                          child: Container(
                            margin: EdgeInsets.all(10),
                            child: Text(
                              widget.certMessage.payload.content,
                            ),
                          ),
                        ),
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
                                    obscureText: true,
                                    autofocus: true,
                                    decoration: InputDecoration(
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
                                passwordController.clear();
                                Navigator.pop(context);
                                setState(() {
                                  loading = true;
                                });
                                Uint8List privateKey;
                                try {
                                  privateKey = await BipKeyDerivation
                                      .decryptedByKeystore(
                                    wallet.keystore,
                                    password,
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
                                  final head = Globals.head(widget.network);
                                  int timestamp = head.timestamp;
                                  Certificate cert = Certificate(
                                    certMessage: widget.certMessage,
                                    timestamp: timestamp,
                                    domain: widget.options.link,
                                  );
                                  cert.sign(privateKey);
                                  await WalletStorage.setMainWallet(
                                    WalletEntity(
                                      keystore: wallet.keystore,
                                      name: wallet.name,
                                    ),
                                    widget.network,
                                  );
                                  await ActivityStorage.insert(
                                    Activity(
                                      block: head.number,
                                      content:
                                          json.encode(cert.encoded.encoded),
                                      link: cert.domain,
                                      walletName: wallet.name,
                                      type: ActivityType.Certificate,
                                      comment: cert.certMessage.purpose,
                                      timestamp: timestamp,
                                      status: ActivityStatus.Finished,
                                    ),
                                  );
                                  Navigator.of(context).pop(cert.encoded);
                                } catch (err) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return alert(context, Text("Error"), "$err");
                                } finally {
                                  setState(() {
                                    loading = false;
                                  });
                                }
                              }, cancelAction: () async {
                                passwordController.clear();
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
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
