import 'dart:async';
import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/main.dart';
import 'package:veatre/src/storage/networkStorage.dart';

import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/addressDetail.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/importWallet.dart';
import 'package:veatre/src/ui/walletInfo.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/api/accountAPI.dart';

class ManageWallets extends StatefulWidget {
  static final routeName = '/wallets';

  @override
  ManageWalletsState createState() => ManageWalletsState();
}

class ManageWalletsState extends State<ManageWallets> {
  List<Wallet> wallets = [];

  @override
  void initState() {
    super.initState();
    updateWallets();
    NetworkStorage.isMainNet.then((isMainNet) {
      final headController =
          isMainNet ? mainNetHeadController : testNetHeadController;
      headController.addListener(updateWallets);
    });
  }

  Future<void> updateWallets() async {
    if (mounted) {
      List<WalletEntity> walletEntities = await WalletStorage.readAll();
      List<Wallet> wallets = await walletList(walletEntities);
      setState(() {
        this.wallets = wallets;
      });
    }
  }

  Future<List<Wallet>> walletList(List<WalletEntity> walletEntities) async {
    List<Wallet> walltes = [];
    for (WalletEntity walletEntity in walletEntities) {
      Account acc = await AccountAPI.get(walletEntity.keystore.address);
      walltes.add(
        Wallet(
          account: acc,
          keystore: walletEntity.keystore,
          name: walletEntity.name,
        ),
      );
    }
    return walltes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Wallets'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 10),
              physics: ClampingScrollPhysics(),
              itemBuilder: buildWalletCard,
              itemCount: wallets.length,
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 50,
                        child: RaisedButton(
                          color: Colors.blue,
                          textColor: Colors.white,
                          child: Text("Create"),
                          onPressed: () async {
                            await Navigator.pushNamed(
                                context, CreateWallet.routeName);
                            await updateWallets();
                          },
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 50,
                        child: RaisedButton(
                          color: Colors.red,
                          textColor: Colors.white,
                          child: Text("Import"),
                          onPressed: () async {
                            await updateWallets();
                            Navigator.pushNamed(
                                context, ImportWallet.routeName);
                            await updateWallets();
                          },
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget buildWalletCard(BuildContext context, int index) {
    Wallet wallet = wallets[index];
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: GestureDetector(
        child: Card(
          margin: EdgeInsets.only(left: 10, right: 10, top: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    colors: [const Color(0xFF81269D), const Color(0xFFEE112D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(left: 15, top: 15),
                          child: Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        FlatButton(
                          onPressed: () async {
                            await showGeneralDialog(
                              context: context,
                              barrierDismissible: false,
                              transitionDuration: Duration(milliseconds: 200),
                              pageBuilder: (context, a, b) {
                                return SlideTransition(
                                  position: Tween(
                                          begin: Offset(0, 1), end: Offset.zero)
                                      .animate(a),
                                  child: AddressDetail(
                                    wallet: wallet,
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            children: <Widget>[
                              Text(
                                '0x' +
                                    wallet.keystore.address.substring(0, 8) +
                                    '...' +
                                    wallet.keystore.address.substring(32, 40),
                                style: TextStyle(color: Colors.white),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 5),
                                child: Icon(
                                  FontAwesomeIcons.qrcode,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      wallet.account.formatBalance,
                      style: TextStyle(fontSize: 30),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 5, right: 14, top: 10),
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
                    Text(wallet.account.formatEnergy,
                        style: TextStyle(fontSize: 12)),
                    Container(
                      margin: EdgeInsets.only(left: 5, right: 15, top: 2),
                      child: Text(
                        'VTHO',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 8,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WalletInfo(
                walletName: wallet.name,
              ),
            ),
          );
          await updateWallets();
        },
      ),
    );
  }
}
