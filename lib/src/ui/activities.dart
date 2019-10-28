import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/ui/sign_dialog/bottom_modal/summary.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';

class Activities extends StatefulWidget {
  @override
  ActivitiesState createState() => ActivitiesState();
}

class ActivitiesState extends State<Activities> {
  List<Activity> activities = [];

  @override
  void initState() {
    super.initState();
    ActivityStorage.updateHasShown();
    loadActivities();
    Globals.addBlockHeadHandler(_handleHeadChanged);
  }

  void _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await loadActivities();
      await ActivityStorage.updateHasShown();
    }
  }

  Future<void> loadActivities() async {
    List<Activity> activities = await ActivityStorage.queryAll();
    if (mounted) {
      setState(() {
        this.activities = activities;
      });
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
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('Activity'),
        leading: FlatButton(
          padding: EdgeInsets.all(0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Close',
              style: TextStyle(
                color: Theme.of(context).textTheme.title.color,
                fontSize: 16,
              ),
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemBuilder: buildActivity,
        itemCount: activities.length,
        physics: ClampingScrollPhysics(),
      ),
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
                child: Padding(
                  padding: EdgeInsets.only(right: 10),
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
              )
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 10, right: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 60,
                ),
                Text(
                  'Signed by',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 2, right: 2),
                  child: Picasso(
                    '0x${activity.address}',
                    size: 20,
                    borderRadius: 4,
                  ),
                ),
                FutureBuilder(
                  future: WalletStorage.read(
                    activity.address,
                    network: activity.network,
                  ),
                  builder: (context, shot) {
                    if (shot.hasData) {
                      WalletEntity walletEntity = shot.data;
                      return Text(walletEntity.name);
                    }
                    return Text('Unkown');
                  },
                ),
                Expanded(
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
                                  : activity.status == ActivityStatus.Reverted
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
                                      : Globals.head().number - processBlock >=
                                              12
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
                                          : Row(
                                              children: <Widget>[
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    value:
                                                        (Globals.head().number -
                                                                processBlock) /
                                                            12,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 35,
                                                  child: Text(
                                                    '${Globals.head().number - processBlock}/12',
                                                    textAlign: TextAlign.right,
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
                                Navigator.of(context).pop(
                                    "https://insight.vecha.in/#/txs/${activity.hash}");
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
                                      title: 'Certificate',
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
