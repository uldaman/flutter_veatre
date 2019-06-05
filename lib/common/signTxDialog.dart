import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/models/wallet.dart';
import 'package:veatre/src/ui/progressHUD.dart';

class SignTxDialog extends StatefulWidget {
  static const routeName = "/sign/tx";

  @override
  SignTxDialogState createState() => SignTxDialogState();
}

class SignTxDialogState extends State<SignTxDialog> {
  int currentPage = 0;
  double priority = 0.5;
  List<Wallet> wallets = [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      loading = true;
    });
    WalletStorage.readAll().then((walletEntities) {
      walletList(walletEntities).then((wallets) {
        setState(() {
          this.wallets = wallets;
          this.loading = false;
        });
      }).catchError((err) => print(err));
    });
  }

  Future<List<Wallet>> walletList(List<WalletEntity> walletEntities) async {
    List<Wallet> walltes = [];
    for (WalletEntity walletEntity in walletEntities) {
      Account acc = await AccountAPI.get(walletEntity.keystore.address);
      walltes.add(
        Wallet(
          account: acc,
          address: walletEntity.keystore.address,
          name: walletEntity.name,
        ),
      );
    }
    return walltes;
  }

  Widget buildWalletCard(Wallet wallet) {
    return GestureDetector(
      child: Card(
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: <Widget>[
            Container(
              height: 100,
              width: MediaQuery.of(context).size.width - 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
                gradient: LinearGradient(
                  colors: [const Color(0xFF81269D), const Color(0xFFEE112D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width - 100,
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
                    width: MediaQuery.of(context).size.width - 100,
                    child: Text(
                      '0x' + wallet.address,
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
        print('wallet tapped');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(initialPage: currentPage);
    List<Widget> walletWidgets = [];
    for (Wallet wallet in this.wallets) {
      walletWidgets.add(buildWalletCard(wallet));
    }
    PageView accountsPageView = PageView(
      onPageChanged: (page) async {
        setState(() {
          currentPage = page;
        });
      },
      scrollDirection: Axis.horizontal,
      physics: new ClampingScrollPhysics(),
      controller: pageController,
      children: walletWidgets,
    );
    return ProgressHUD(
      isLoading: loading,
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Sign Transaction'),
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
        ),
        body: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                currentPage != 0
                    ? IconButton(
                        onPressed: () async {
                          if (currentPage != 0) {
                            await pageController.previousPage(
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeOut);
                          }
                        },
                        icon: Icon(Icons.keyboard_arrow_left),
                      )
                    : SizedBox(
                        width: 50,
                      ),
                Container(
                  child: accountsPageView,
                  width: MediaQuery.of(context).size.width - 100,
                  height: 195,
                ),
                currentPage < wallets.length - 1
                    ? IconButton(
                        onPressed: () async {
                          if (currentPage < wallets.length) {
                            await pageController.nextPage(
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                          }
                        },
                        icon: Icon(Icons.keyboard_arrow_right),
                      )
                    : SizedBox(
                        width: 50,
                      ),
              ],
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Spend value',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '100',
                          style: TextStyle(color: Colors.black),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5, right: 9),
                          child: Text(
                            'VET',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Estimated fee',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '100',
                          style: TextStyle(color: Colors.black),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5),
                          child: Text(
                            'VTHO',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Priority',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Slider(
                      onChanged: (priority) async {
                        print(priority);
                        setState(() {
                          this.priority = priority;
                        });
                      },
                      value: priority,
                      activeColor: Colors.blueAccent,
                      label: "$priority",
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(right: 15),
                        child: FlatButton(
                          child: Text(
                            'transaction details',
                            style: TextStyle(
                              color: Colors.blueAccent,
                            ),
                          ),
                          onPressed: () async {
                            print('more');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
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
                              print('confirm');
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
      ),
    );
  }
}
