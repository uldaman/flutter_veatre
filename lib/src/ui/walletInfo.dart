import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/walletCard.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/walletOperation.dart';
import 'package:veatre/src/ui/sign_dialog/bottom_modal/summary.dart';

class WalletInfo extends StatefulWidget {
  final WalletEntity walletEntity;
  final Account account;

  WalletInfo({
    this.walletEntity,
    this.account,
  });

  @override
  WalletInfoState createState() => WalletInfoState();
}

class WalletInfoState extends State<WalletInfo> {
  List<Activity> activities = [];
  WalletEntity walletEntity;
  Account initialAccount;
  @override
  void initState() {
    walletEntity = widget.walletEntity;
    initialAccount = widget.account;
    super.initState();
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
            icon: Icon(
              MaterialCommunityIcons.dots_vertical,
            ),
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
      body: Column(
        children: <Widget>[
          buildWalletCard(context, walletEntity),
          Padding(
            padding: EdgeInsets.only(top: 15, left: 15, right: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Activities',
                style: TextStyle(
                  color: Theme.of(context).primaryTextTheme.subtitle.color,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: activities.length > 0
                ? ListView.builder(
                    padding: EdgeInsets.only(bottom: 15),
                    itemBuilder: buildActivity,
                    itemCount: activities.length,
                    physics: ClampingScrollPhysics(),
                  )
                : Center(
                    child: SizedBox(
                      height: 200,
                      child: Column(
                        children: <Widget>[
                          Text(
                            'No Activity',
                            style: TextStyle(
                              fontSize: 22,
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.only(top: 20, left: 40, right: 40),
                            child: Text(
                              "Transaction and Certificate that you've signed will appear here",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .display2
                                    .color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildWalletCard(BuildContext context, WalletEntity walletEntity) {
    return WalletCard(
      context,
      walletEntity,
      initialAccount: initialAccount,
      getAccount: () => AccountAPI.get(walletEntity.address),
    );
  }

  Widget buildActivity(BuildContext context, int index) {
    Activity activity = activities[index];
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(activity.timestamp * 1000);
    String dateString =
        "${formatTime(date.day)} ${formatMonth(date.month)},${date.year} ${formatTime(date.hour)}:${formatTime(date.minute)}:${formatTime(date.second)}";
    int processBlock = activity.processBlock;
    return Card(
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
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryTextTheme.title.color,
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
                          color:
                              Theme.of(context).primaryTextTheme.display2.color,
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
                                      color: Color(0xFF57BD89),
                                      size: 16,
                                    ),
                                    Text(
                                      'Confirmed',
                                      style: TextStyle(
                                        color: Color(0xFF57BD89),
                                        fontSize: 12,
                                      ),
                                    )
                                  ],
                                )
                              : activity.status == ActivityStatus.Pending
                                  ? Row(
                                      children: <Widget>[
                                        Icon(
                                          MaterialCommunityIcons
                                              .progress_upload,
                                          color: Color(0xFF57BD89),
                                          size: 16,
                                        ),
                                        Text(
                                          'Sending',
                                          style: TextStyle(
                                            color: Color(0xFF57BD89),
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
                                              color: Color(0xFFEF8816),
                                              size: 16,
                                            ),
                                            Text(
                                              'Expired',
                                              style: TextStyle(
                                                color: Color(0xFFEF8816),
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
                                                  color: Theme.of(context)
                                                      .errorColor,
                                                  size: 16,
                                                ),
                                                Text(
                                                  'Reverted',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .errorColor,
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
                                                      color: Color(0xFF57BD89),
                                                      size: 16,
                                                    ),
                                                    Text(
                                                      'Confirmed',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF57BD89),
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
                                                        backgroundColor: Theme
                                                                .of(context)
                                                            .primaryTextTheme
                                                            .display3
                                                            .color,
                                                        value: (Globals.head()
                                                                    .number -
                                                                processBlock) /
                                                            12,
                                                        valueColor:
                                                            AlwaysStoppedAnimation(
                                                                Theme.of(
                                                                        context)
                                                                    .primaryColor),
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
                                                          color: Theme.of(
                                                                  context)
                                                              .primaryTextTheme
                                                              .display2
                                                              .color,
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
            thickness: 1,
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
                        MaterialCommunityIcons.link_variant,
                        size: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                      FlatButton(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                          getDomain(Uri.parse(activity.link)),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
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
                            ? MaterialCommunityIcons.magnify
                            : MaterialCommunityIcons.content_copy,
                        size: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                      activity.type == ActivityType.Transaction
                          ? FlatButton(
                              padding: EdgeInsets.only(left: 5),
                              child: Text(
                                '0x${abbreviate(activity.hash.substring(2))}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              onPressed: () async {
                                final url =
                                    "https://insight.vecha.in/#${Globals.network == Network.MainNet ? '' : '/test'}/txs/${activity.hash}";
                                Navigator.of(context).pop(url);
                              },
                            )
                          : FlatButton(
                              padding: EdgeInsets.only(left: 5),
                              child: Text(
                                'Signed Message',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
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
