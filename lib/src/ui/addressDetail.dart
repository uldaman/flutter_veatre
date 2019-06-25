import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:veatre/src/models/account.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddressDetail extends StatefulWidget {
  final Wallet wallet;
  AddressDetail({this.wallet});

  @override
  AddressDetailState createState() => AddressDetailState();
}

class AddressDetailState extends State<AddressDetail> {
  bool isCopied = false;

  @override
  Widget build(BuildContext context) {
    Wallet wallet = widget.wallet;
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 50),
            child: Row(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 25,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 60, left: 15, right: 15),
            width: MediaQuery.of(context).size.width - 30,
            height: MediaQuery.of(context).size.width - 30,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Stack(
              children: <Widget>[
                Container(
                  height: 100,
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
                      SizedBox(
                        height: 50,
                        child: Center(
                          child: Text(
                            wallet.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: Center(
                          child: FlatButton(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "0x${wallet.keystore.address}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Icon(
                                    FontAwesomeIcons.copy,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () async {
                              await Clipboard.setData(new ClipboardData(
                                  text: '0x' + wallet.keystore.address));
                              setState(() {
                                isCopied = true;
                              });
                              await Future.delayed(Duration(seconds: 1));
                              setState(() {
                                isCopied = false;
                              });
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.width - 130,
                    width: MediaQuery.of(context).size.width - 30,
                    child: Center(
                      child: new QrImage(
                        data: '0x' + wallet.keystore.address,
                        size: MediaQuery.of(context).size.width - 200,
                      ),
                    ),
                  ),
                ),
                isCopied
                    ? Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: Card(
                              color: Colors.grey[200],
                              child: Container(
                                child: Text(
                                  'copied',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.green),
                                ),
                                padding: EdgeInsets.all(8),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Text(''),
              ],
            ),
          )
        ],
      ),
    );
  }
}
