import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';

class Activities extends StatefulWidget {
  static const routeName = '/activities';

  @override
  ActivitiesState createState() => ActivitiesState();
}

class ActivitiesState extends State<Activities> {
  List<Activity> activities = [];

  int offset = 0;
  int limit = 10;

  @override
  void initState() {
    super.initState();
    loadActivities().then((activities) {
      setState(() {
        this.activities = activities;
      });
    });
  }

  Future<List<Activity>> loadActivities() async {
    return ActivityStorage.query(
      offset,
      limit,
    );
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
    return Container(
      child: Card(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(15),
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
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            )
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
                                      color: Colors.blue,
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
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.orange,
                    size: 15,
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
