import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/walletInfo.dart';
import 'package:veatre/main.dart';

class Activities extends StatefulWidget {
  final HeadController headController;

  Activities({this.headController});

  @override
  ActivitiesState createState() => ActivitiesState();
}

class ActivitiesState extends State<Activities> {
  List<Activity> activities = [];

  @override
  void initState() {
    super.initState();
    loadActivities();
    widget.headController.addListener(loadActivities);
  }

  void loadActivities() async {
    if (mounted) {
      List<Activity> activities = await ActivityStorage.queryAll();
      setState(() {
        this.activities = activities;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Activities'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
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

  Widget buildActivity(BuildContext context, int index) {
    Activity activity = activities[index];
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(activity.timestamp * 1000);
    Function formatTime = (int time) {
      return time.toString().length == 2 ? "$time" : "0$time";
    };
    String dateString =
        "${date.year}/${date.month}/${date.day} ${formatTime(date.hour)}:${formatTime(date.minute)}:${formatTime(date.second)}";
    Map<String, dynamic> content = json.decode(activity.content);
    int processBlock = activity.processBlock;
    return Container(
      child: Card(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 15, left: 15, right: 15),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                child: Text(
                                  activity.comment,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    child: Card(
                                      color: activity.type ==
                                              ActivityType.Transaction
                                          ? Colors.blue
                                          : Colors.red,
                                      child: Padding(
                                        padding: EdgeInsets.all(5),
                                        child: Text(
                                          activity.type ==
                                                  ActivityType.Transaction
                                              ? 'TX'
                                              : 'CERT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 10, right: 20),
                              child: Text(
                                dateString,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  activity.status == ActivityStatus.Finished
                      ? Icon(
                          Icons.check_circle_outline,
                          color: Colors.blue,
                          size: 20,
                        )
                      : activity.status == ActivityStatus.Expired
                          ? Icon(
                              Icons.alarm_off,
                              color: Colors.grey,
                              size: 20,
                            )
                          : activity.status == ActivityStatus.Reverted
                              ? Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 20,
                                )
                              : processBlock != null
                                  ? SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        backgroundColor: Colors.grey[200],
                                        value: (widget.headController.value
                                                    .number -
                                                processBlock) /
                                            12,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.update,
                                      color: Colors.blue,
                                      size: 15,
                                    )
                ],
              ),
            ),
            Row(
              children: <Widget>[
                FlatButton(
                  onPressed: () async {
                    WalletEntity walletEntity =
                        await WalletStorage.read(activity.walletName);
                    if (walletEntity != null) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WalletInfo(
                            walletName: activity.walletName,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    activity.walletName,
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            activity.type == ActivityType.Certificate
                ? Padding(
                    padding: EdgeInsets.only(bottom: 15, left: 15, right: 15),
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Text(
                            'Link',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            enableInteractiveSelection: true,
                            maxLines: null,
                            decoration:
                                InputDecoration(border: InputBorder.none),
                            controller:
                                TextEditingController(text: activity.link),
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        )
                      ],
                    ))
                : Padding(
                    padding: EdgeInsets.only(bottom: 15, left: 15, right: 15),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: <Widget>[
                              Text(
                                'Amount',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      content['amount'],
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    Container(
                                      margin:
                                          EdgeInsets.only(left: 5, right: 9),
                                      child: Text(
                                        'VET',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Text(
                              'Fee',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    content['fee'],
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 5),
                                    child: Text(
                                      'VTHO',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Text(
                                'TXID',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                readOnly: true,
                                enableInteractiveSelection: true,
                                maxLines: null,
                                decoration:
                                    InputDecoration(border: InputBorder.none),
                                controller:
                                    TextEditingController(text: activity.hash),
                                style:
                                    TextStyle(color: Colors.blue, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Text(
                                'Link',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                readOnly: true,
                                enableInteractiveSelection: true,
                                maxLines: null,
                                decoration:
                                    InputDecoration(border: InputBorder.none),
                                controller:
                                    TextEditingController(text: activity.link),
                                style:
                                    TextStyle(color: Colors.blue, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
