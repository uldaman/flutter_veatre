import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/api/TransactionAPI.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/ui/walletOperation.dart';
import 'package:veatre/src/utils/common.dart';

class WalletInfo extends StatefulWidget {
  final Wallet wallet;
  WalletInfo({this.wallet});

  @override
  WalletInfoState createState() => WalletInfoState();
}

class WalletInfoState extends State<WalletInfo> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController originalPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();

  bool loadMore = false;
  ScrollController _scrollController = new ScrollController();
  int offset = 0;
  int limit = 10;
  Wallet wallet;
  List<Transfer> transfers = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      this.wallet = widget.wallet;
    });
    _getMoreData(widget.wallet.keystore.address);
    _scrollController.addListener(() async {
      if (!loadMore &&
          transfers.length % limit == 0 &&
          _scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent) {
        await _getMoreData(wallet.keystore.address);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  _getMoreData(String address) async {
    setState(() {
      loadMore = true;
    });
    List<Transfer> data = await TransactionAPI.filterTransfers(
      address,
      offset,
      limit,
    );
    offset += limit;
    setState(() {
      loadMore = false;
      transfers.addAll(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF81269D), const Color(0xFFEE112D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(top: 120),
                            height: 60,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        wallet.account.formatBalance(),
                                        style: TextStyle(
                                          fontSize: 40,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            left: 5, top: 15, right: 15),
                                        child: Text(
                                          'VET',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )),
                        Container(
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                wallet.account.formatEnergy(),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                margin:
                                    EdgeInsets.only(left: 5, top: 5, right: 15),
                                child: Text(
                                  'VTHO',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 8,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                margin: EdgeInsets.only(top: 50),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(left: 15),
                            width: 55,
                            child: IconButton(
                              icon: Icon(Icons.arrow_back_ios),
                              iconSize: 25,
                              color: Colors.white,
                              onPressed: () async {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Container(
                            child: Text(
                              wallet.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(right: 15),
                            width: 55,
                            child: IconButton(
                              icon: Icon(FontAwesomeIcons.wrench),
                              iconSize: 20,
                              color: Colors.white,
                              onPressed: () async {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => WalletOperation(
                                          wallet: wallet,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          Expanded(
            child: Container(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                physics: ClampingScrollPhysics(),
                controller: _scrollController,
                itemCount: transfers.length,
                itemBuilder: buildCell,
              ),
              color: Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCell(BuildContext context, int index) {
    Transfer transfer = transfers[index];
    bool isSender = transfer.sender == '0x' + wallet.keystore.address;
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        transfer.meta.blockTimestamp * 1000);
    Function formatTime = (int time) {
      return time.toString().length == 2 ? "$time" : "0$time";
    };
    String dateString =
        "${date.year}/${date.month}/${date.day} ${formatTime(date.hour)}:${formatTime(date.minute)}:${formatTime(date.second)}";
    BigInt amount = BigInt.parse(transfer.amount);
    return Container(
      child: Column(
        children: <Widget>[
          Card(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      height: 30,
                      margin: EdgeInsets.only(top: 15, left: 15),
                      child: Text(
                        isSender ? transfer.recipient : transfer.sender,
                        style: TextStyle(
                          color: isSender ? Colors.black : Colors.blueAccent,
                          // fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Container(
                      height: 30,
                      margin: EdgeInsets.only(
                        left: 15,
                      ),
                      child: Text(
                        dateString,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Text(
                              "${isSender ? '-' : '+'}${fixed2Value(amount)}",
                              style: TextStyle(
                                color:
                                    isSender ? Colors.black : Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            margin:
                                EdgeInsets.only(left: 4, right: 15, bottom: 12),
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
                  ],
                ),
              ],
            ),
          ),
          loadMore && index % limit == limit - 1
              ? Container(
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                    ],
                  ),
                )
              : SizedBox(
                  height: 0,
                ),
        ],
      ),
    );
  }
}
