import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/walletStorage.dart';

class Wallets extends StatefulWidget {
  @override
  WalletsState createState() => WalletsState();
}

class WalletsState extends State<Wallets> {
  List<WalletEntity> walletEntities = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    updateWallets().whenComplete(() {
      setState(() {
        loading = false;
      });
      Globals.addBlockHeadHandler(_handleHeadChanged);
    });
  }

  void _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await updateWallets();
    }
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    super.dispose();
  }

  Future<void> updateWallets() async {
    List<WalletEntity> walletEntities = await WalletStorage.readAll();
    if (mounted) {
      setState(() {
        this.walletEntities = walletEntities;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallets'),
        centerTitle: true,
      ),
      body: ProgressHUD(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return buildWalletCard(context, walletEntities[index]);
                },
                itemCount: walletEntities.length,
                physics: ClampingScrollPhysics(),
              ),
            ),
          ],
        ),
        isLoading: loading,
      ),
    );
  }

  Widget buildWalletCard(BuildContext context, WalletEntity walletEntity) {
    return GestureDetector(
      child: Card(
        margin: EdgeInsets.only(left: 15, top: 15, right: 15),
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
                              fontSize: 17,
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
              )
            ],
          ),
        ),
      ),
      onTap: () async {
        Navigator.of(context).pop(walletEntity);
      },
    );
  }

  Widget balance(String balance, String energy) {
    return Column(
      children: <Widget>[
        Row(
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
