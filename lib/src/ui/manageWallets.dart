import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/ui/CreateWallet.dart';
import 'package:veatre/src/ui/ImportWallet.dart';

class ManageWallets extends StatefulWidget {
  static const routeName = '/wallets_management';
  ManageWallets() : super();
  @override
  ManageWalletsState createState() => ManageWalletsState();
}

class ManageWalletsState extends State<ManageWallets> {
  List<WalletEntity> walletEntities = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies');
    WalletStorage.readAll().then((walletEntities) {
      setState(() {
        this.walletEntities = walletEntities;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> walletWidgets = [];
    for (WalletEntity walletEntity in walletEntities) {
      walletWidgets.add(walletWidget(walletEntity));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Wallets'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ListView(
              children: walletWidgets,
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
                          onPressed: () {
                            Navigator.pushNamed(
                                context, CreateWallet.routeName);
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
                          onPressed: () {
                            print("Import");
                            Navigator.pushNamed(
                                context, ImportWallet.routeName);
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

  Widget walletWidget(WalletEntity walletEntity) {
    return GestureDetector(
      child: Container(
        height: 110,
        child: Card(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Icon(
                      FontAwesomeIcons.wallet,
                      color: Colors.blue,
                    ),
                    height: 30,
                  ),
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Text(
                      walletEntity.name,
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    height: 30,
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Icon(
                      FontAwesomeIcons.addressCard,
                      color: Colors.blue,
                    ),
                    height: 30,
                  ),
                  Container(
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.fromLTRB(0, 6, 0, 5),
                    child: Text(
                      '0x' + walletEntity.keystore.address,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                    ),
                    height: 30,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        print('tap wallet');
      },
    );
  }
}
