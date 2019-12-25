import 'package:flutter/material.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/utils/common.dart';

class Clauses extends StatelessWidget {
  final List<SigningTxMessage> txMessages;

  Clauses({
    Key key,
    @required this.txMessages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clause(${txMessages.length})'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        itemBuilder: buildClause,
        itemCount: txMessages.length,
        physics: ClampingScrollPhysics(),
      ),
    );
  }

  Widget buildClause(BuildContext context, int index) {
    final txMessage = txMessages[index];
    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    txMessage.to == null
                        ? "To: --"
                        : "To: 0x${abbreviate(txMessage.to.substring(2))}",
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        color: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          typeOf(txMessage),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              txMessage.comment != ''
                  ? Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              txMessage.comment,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    )
                  : SizedBox(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Divider(
                  thickness: 1,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 65,
                      child: Text(
                        'Value',
                        style: TextStyle(
                          color:
                              Theme.of(context).primaryTextTheme.display2.color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Text(
                            '${formatNum(fixed2Value(BigInt.parse(txMessage.value)))}',
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 3, top: 2),
                            child: Text(
                              'VET',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .display2
                                    .color,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 65,
                      child: Text(
                        'Data',
                        style: TextStyle(
                          color:
                              Theme.of(context).primaryTextTheme.display2.color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${txMessage.data}',
                        textAlign: TextAlign.left,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String typeOf(SigningTxMessage signingTxMessage) {
    if (signingTxMessage.to == null) {
      return 'Create';
    }
    if (signingTxMessage.data.length == 2) {
      return 'Transfer';
    }
    return 'Call';
  }
}
