import 'dart:async';
import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/addressDetail.dart';
import 'package:veatre/src/ui/createOrImportWallet.dart';
import 'package:veatre/src/ui/walletInfo.dart';

class ManageWallets extends StatefulWidget {
  static final routeName = '/wallets';

  @override
  ManageWalletsState createState() => ManageWalletsState();
}

class ManageWalletsState extends State<ManageWallets> {
  List<WalletEntity> walletEntities = [];
  @override
  void initState() {
    super.initState();
    updateWallets(Globals.network);
    Globals.addBlockHeadHandler(_handleHeadChanged);
  }

  void _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await updateWallets(Globals.network);
    }
  }

  Future<void> updateWallets(Network network) async {
    List<WalletEntity> walletEntities = await WalletStorage.readAll();
    if (mounted) {
      setState(() {
        this.walletEntities = walletEntities;
      });
    }
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: FlatButton(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          padding: EdgeInsets.all(0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Close',
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Wallets'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.add,
              size: 30,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                new MaterialPageRoute(
                  builder: (context) => new CreateOrImportWallet(
                    fromRouteName: ManageWallets.routeName,
                  ),
                ),
              );
              await updateWallets(Globals.network);
            },
          )
        ],
      ),
      body: SafeArea(
        child: walletEntities.length > 0
            ? ListView.builder(
                padding: EdgeInsets.only(bottom: 10),
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  return buildWalletCard(context, walletEntities[index]);
                },
                itemCount: walletEntities.length,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Text(
                      'Add your first wallet',
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                    child: Text(
                      'Wallet is a universal identity on blockchain,create one to explore.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            Theme.of(context).primaryTextTheme.display2.color,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget buildWalletCard(BuildContext context, WalletEntity walletEntity) {
    return GestureDetector(
      child: Card(
        margin: EdgeInsets.only(left: 15, right: 15, top: 15),
        child: Container(
          margin: EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 10, top: 10, right: 10),
                    child: Picasso(
                      '0x${walletEntity.address}',
                      size: 60,
                      borderRadius: 10,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            walletEntity.name,
                            style: TextStyle(
                              fontSize: 22,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            '0x${abbreviate(walletEntity.address)}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .display2
                                  .color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: IconButton(
                      icon: Icon(
                        MaterialCommunityIcons.getIconData('qrcode'),
                        size: 30,
                      ),
                      onPressed: () async {
                        await showGeneralDialog(
                          context: context,
                          barrierDismissible: false,
                          transitionDuration: Duration(milliseconds: 150),
                          pageBuilder: (context, a, b) {
                            return ScaleTransition(
                              scale: Tween(begin: 0.0, end: 1.0).animate(a),
                              child: AddressDetail(
                                walletEntity: walletEntity,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: IconButton(
                      icon: Icon(
                        MaterialCommunityIcons.getIconData('file-find-outline'),
                        size: 30,
                      ),
                      onPressed: () async {
                        final url =
                            "https://insight.vecha.in/#/${Globals.network == Network.MainNet ? 'main' : 'test'}/accounts/0x${walletEntity.address}";
                        Navigator.of(context).pop(url);
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: 10,
                  left: 15,
                  right: 15,
                ),
                child: Divider(
                  thickness: 1,
                ),
              ),
              FutureBuilder(
                future: AccountAPI.get(walletEntity.address),
                builder: (context, shot) {
                  Account account = shot.data;
                  return balance(
                    account?.formatBalance ?? '--',
                    account?.formatEnergy ?? '--',
                  );
                },
              ),
            ],
          ),
        ),
      ),
      onTapUp: (details) async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WalletInfo(
              walletEntity: walletEntity,
            ),
          ),
        );
        if (result != null) {
          Navigator.of(context).pop(result);
        } else {
          await updateWallets(Globals.network);
        }
      },
    );
  }

  Widget balance(String balance, String energy) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                balance,
                style: TextStyle(fontSize: 22),
              ),
              Container(
                margin: EdgeInsets.only(left: 5, right: 22, top: 10),
                child: Text(
                  'VET',
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(energy, style: TextStyle(fontSize: 14)),
              Container(
                margin: EdgeInsets.only(left: 5, right: 12, top: 2),
                child: Text(
                  'VTHO',
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
