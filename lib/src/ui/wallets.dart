import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/main.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/api/accountAPI.dart';

class Wallets extends StatefulWidget {
  final HeadController headController;
  Wallets({this.headController});

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
      widget.headController.addListener(updateWallets);
    });
  }

  Future<void> updateWallets() async {
    List<WalletEntity> walletEntities = await WalletStorage.readAll();
    if (mounted) {
      setState(() {
        this.walletEntities = walletEntities;
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Wallets'),
        centerTitle: true,
      ),
      body: ProgressHUD(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemBuilder: buildWalletCard,
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

  Widget buildWalletCard(BuildContext context, int index) {
    WalletEntity walletEntity = walletEntities[index];
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 170,
      child: GestureDetector(
        child: Card(
          margin: EdgeInsets.only(left: 10, right: 10, top: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: <Widget>[
              Container(
                height: 85,
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
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: Container(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          walletEntity.name,
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
                        '0x' + walletEntity.keystore.address,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder(
                future: walletFrom(walletEntity),
                builder: (context, shot) {
                  if (shot.hasData) {
                    Wallet wallet = shot.data;
                    return balance(wallet.account.formatBalance,
                        wallet.account.formatEnergy);
                  }
                  return balance('0', '0');
                },
              )
            ],
          ),
        ),
        onTap: () async {
          Navigator.of(context).pop(walletEntity);
        },
      ),
    );
  }

  Future<Wallet> walletFrom(WalletEntity walletEntity) async {
    Account acc = await AccountAPI.get(walletEntity.keystore.address);
    return Wallet(
      account: acc,
      keystore: walletEntity.keystore,
      name: walletEntity.name,
    );
  }

  Widget balance(String balance, String energy) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                balance,
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
          margin: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(energy, style: TextStyle(fontSize: 12)),
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
    );
  }
}
