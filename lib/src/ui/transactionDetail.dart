import 'package:flutter/material.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/utils/common.dart';

class TransactionDetail extends StatelessWidget {
  static final routeName = '/transaction/detail';

  List<Widget> buildClauses(List<SigningTxMessage> txMessages) {
    List<Widget> clauseCards = [];
    for (SigningTxMessage txMessage in txMessages) {
      Widget clauseCard = Container(
        child: Card(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 80,
                    margin: EdgeInsets.only(top: 15, left: 10),
                    child: Text(
                      'To',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                      child: Text(txMessage.to),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 15, left: 10),
                    width: 80,
                    child: Text(
                      'Value',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text("${fixed2Value(BigInt.parse(txMessage.value))}"),
                          Container(
                            margin: EdgeInsets.only(left: 5),
                            child: Text(
                              'VET',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 15, left: 10),
                    width: 80,
                    child: Text(
                      'Inpu data',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                      child: Text(txMessage.data),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 80,
                    margin: EdgeInsets.only(top: 15, left: 10, bottom: 15),
                    child: Text(
                      'Comment',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          top: 15, left: 5, right: 10, bottom: 15),
                      child: Text(txMessage.comment),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      clauseCards.add(clauseCard);
    }
    return clauseCards;
  }

  @override
  Widget build(BuildContext context) {
    final List<SigningTxMessage> txMessages =
        ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Transaction Detail'),
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
      body: ListView(
        children: buildClauses(txMessages),
      ),
    );
  }
}
