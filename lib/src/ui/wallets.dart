import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/api/accountAPI.dart';

class Wallets extends StatefulWidget {
  static const routeName = '/wallets';

  @override
  WalletsState createState() => WalletsState();
}

class WalletsState extends State<Wallets> {
  List<Wallet> wallets = [];
  bool loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {
      loading = true;
    });
    WalletStorage.readAll().then((walletEntities) {
      walletList(walletEntities).then((wallets) {
        setState(() {
          this.wallets = wallets;
          loading = false;
        });
      });
    }).catchError((err) {
      print(err);
    });
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
    List<Widget> walletWidgets = [];
    for (Wallet wallet in wallets) {
      walletWidgets.add(buildWalletCard(wallet));
    }
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
              child: ListView(
                children: walletWidgets,
              ),
            ),
          ],
        ),
        isLoading: loading,
      ),
    );
  }

  Widget buildWalletCard(Wallet wallet) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: GestureDetector(
        child: Card(
          margin: EdgeInsets.all(10),
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
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: Container(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          wallet.name,
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
                        '0x' + wallet.keystore.address,
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
                    Text(wallet.account.formatBalance()),
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
                    Text(wallet.account.formatEnergy()),
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
        onTap: () async {
          Navigator.of(context).pop(wallet);
        },
      ),
    );
  }
}
