import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/ui/activityCard.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';

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
      await ActivityStorage.updateHasShown();
      await loadActivities();
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
      appBar: AppBar(
        title: Text('Activity'),
        leading: FlatButton(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          padding: EdgeInsets.all(0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Close',
              style: TextStyle(
                color: Theme.of(context).textTheme.title.color,
              ),
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: activities.length > 0
            ? ListView.builder(
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
                        padding: EdgeInsets.only(top: 20, left: 40, right: 40),
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
    );
  }

  Widget buildActivity(BuildContext context, int index) {
    Activity activity = activities[index];
    return ActivityCard(
      activity,
      hasAvatar: true,
    );
  }
}
