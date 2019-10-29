import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/walletOperation.dart';
import 'package:veatre/src/ui/sign_dialog/bottom_modal/summary.dart';

class WalletInfo extends StatefulWidget {
  final WalletEntity walletEntity;

  WalletInfo({this.walletEntity});

  @override
  WalletInfoState createState() => WalletInfoState();
}

class WalletInfoState extends State<WalletInfo> {
  List<Activity> activities = [];
  WalletEntity walletEntity;

  @override
  void initState() {
    super.initState();
    walletEntity = widget.walletEntity;
    _handleHeadChanged();
    Globals.addBlockHeadHandler(_handleHeadChanged);
  }

  Future<void> updateWalletEntity() async {
    final walletEntity = await WalletStorage.read(widget.walletEntity.address);
    if (mounted && walletEntity != null) {
      setState(() {
        this.walletEntity = walletEntity;
      });
    }
  }

  void _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await updateWalletEntity();
      await loadActivities();
    }
  }

  Future<void> loadActivities() async {
    try {
      List<Activity> activities =
          await ActivityStorage.query(widget.walletEntity.address);
      if (mounted) {
        setState(() {
          this.activities = activities;
        });
      }
    } catch (e) {
      print("loadActivities error: $e");
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
        title: Text('Wallets'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(FontAwesomeIcons.wrench),
            iconSize: 20,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WalletOperation(
                    walletEntity: walletEntity,
                  ),
                  settings: RouteSettings(name: '/wallet/operation'),
                ),
              );
              await updateWalletEntity();
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(15),
            child: buildWalletCard(context, walletEntity),
          ),
          Padding(
            padding: EdgeInsets.all(15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Activities',
                style: TextStyle(
                  color: Colors.brown,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: buildActivity,
              itemCount: activities.length,
              physics: ClampingScrollPhysics(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWalletCard(BuildContext context, WalletEntity walletEntity) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 165,
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Colors.grey[300],
              width: 2,
            ),
          ),
        ),
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
                          walletEntity?.name,
                          style: TextStyle(
                            fontSize: 22,
                            color: Theme.of(context).textTheme.title.color,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          shotHex(walletEntity?.address),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                      left: 20,
                      right: 20,
                    ),
                    child: Container(
                      color: Colors.grey[300],
                      height: 2,
                    ),
                  ),
                )
              ],
            ),
            FutureBuilder(
              future: AccountAPI.get(walletEntity?.address),
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
    );
  }

  Widget balance(String balance, String energy) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                balance,
                style: TextStyle(fontSize: 22),
              ),
              Container(
                margin: EdgeInsets.only(left: 10, right: 14, top: 10),
                child: Text(
                  'VET',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
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
              Text(
                energy,
                style: TextStyle(fontSize: 14),
              ),
              Container(
                margin: EdgeInsets.only(left: 5, right: 15, top: 2),
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
    );
  }

  Widget buildActivity(BuildContext context, int index) {
    Activity activity = activities[index];
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(activity.timestamp * 1000);
    String dateString =
        "${formatTime(date.day)} ${formatMonth(date.month)},${date.year} ${formatTime(date.hour)}:${formatTime(date.minute)}:${formatTime(date.second)}";
    int processBlock = activity.processBlock;
    return Container(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.grey[300],
            width: 2,
          ),
        ),
      ),
      margin: EdgeInsets.only(left: 15, right: 15, top: 15),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 10),
                width: 40,
                color: activity.type == ActivityType.Transaction
                    ? Colors.blue
                    : Colors.black,
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    activity.type == ActivityType.Transaction ? 'TX' : 'CERT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  activity.comment,
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 10, top: 10),
                      child: Text(
                        dateString,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10, right: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          activity.status == ActivityStatus.Finished
                              ? Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.greenAccent,
                                      size: 20,
                                    ),
                                    Text(
                                      'Confirmed',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    )
                                  ],
                                )
                              : activity.status == ActivityStatus.Pending
                                  ? Row(
                                      children: <Widget>[
                                        Icon(
                                          FontAwesomeIcons.arrowAltCircleUp,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                        Text(
                                          'Sending',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                          ),
                                        )
                                      ],
                                    )
                                  : activity.status == ActivityStatus.Expired
                                      ? Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.alarm_off,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                            Text(
                                              'Expired',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            )
                                          ],
                                        )
                                      : activity.status ==
                                              ActivityStatus.Reverted
                                          ? Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.error,
                                                  color: Colors.greenAccent,
                                                  size: 20,
                                                ),
                                                Text(
                                                  'Reverted',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              ],
                                            )
                                          : Globals.head().number -
                                                      processBlock >=
                                                  12
                                              ? Row(
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: Colors.greenAccent,
                                                      size: 20,
                                                    ),
                                                    Text(
                                                      'Confirmed',
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 12,
                                                      ),
                                                    )
                                                  ],
                                                )
                                              : Row(
                                                  children: <Widget>[
                                                    SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        backgroundColor:
                                                            Colors.grey[200],
                                                        value: (Globals.head()
                                                                    .number -
                                                                processBlock) /
                                                            12,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 35,
                                                      child: Text(
                                                        '${Globals.head().number - processBlock}/12',
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                )
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          Divider(
            color: Colors.grey[350],
            height: 2,
          ),
          Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        FontAwesomeIcons.link,
                        size: 12,
                        color: Colors.blue,
                      ),
                      FlatButton(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                          getDomain(Uri.parse(activity.link)),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop(activity.link);
                        },
                      )
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 15,
                  margin: EdgeInsets.only(top: 10, bottom: 10),
                  color: Theme.of(context).textTheme.title.color,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        activity.type == ActivityType.Transaction
                            ? FontAwesomeIcons.search
                            : FontAwesomeIcons.copy,
                        size: 12,
                        color: Colors.blue,
                      ),
                      activity.type == ActivityType.Transaction
                          ? FlatButton(
                              padding: EdgeInsets.only(left: 5),
                              child: Text(
                                shotHex(activity.hash),
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                              onPressed: () async {
                                final url = Globals.network == Network.MainNet
                                    ? 'https://insight.vecha.in/#/txs/${activity.hash}'
                                    : 'https://insight.vecha.in/#/test/txs/${activity.hash}';
                                Navigator.of(context).pop(url);
                              },
                            )
                          : FlatButton(
                              padding: EdgeInsets.only(left: 5),
                              child: Text(
                                'Signed Message',
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => Summary(
                                      title: 'Message',
                                      content: json.decode(
                                              activity.content)['payload']
                                          ['content'],
                                    ),
                                  ),
                                );
                              },
                            )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  String getDomain(Uri uri) {
    String host = uri.host;
    List<String> components = host.split('.');
    if (components.length <= 3) {
      return host;
    }
    return "${components[1]}.${components[2]}";
  }

  TextField blueText(String text) => TextField(
        autofocus: false,
        readOnly: true,
        enableInteractiveSelection: true,
        maxLines: null,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        controller: TextEditingController(text: text),
        style: TextStyle(color: Colors.blue, fontSize: 12),
      );

  String formatMonth(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return '';
  }

  String formatTime(int time) {
    return time.toString().length == 2 ? "$time" : "0$time";
  }
}
