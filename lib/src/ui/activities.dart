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
  int limit = 10;
  int offset = 0;
  ScrollController scrollController = ScrollController(initialScrollOffset: 0);
  bool loading = false;

  @override
  void initState() {
    super.initState();
    ActivityStorage.updateHasShown();
    loadActivities();
    scrollController.addListener(_handleScroll);
    Globals.addBlockHeadHandler(_handleHeadChanged);
  }

  void _handleScroll() async {
    if (scrollController.offset == scrollController.position.maxScrollExtent &&
        !loading) {
      setState(() {
        loading = true;
      });
      await Future.delayed(Duration(milliseconds: 300));
      await loadActivities();
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await ActivityStorage.updateHasShown();
    }
  }

  Future<void> loadActivities() async {
    List<Activity> acs = await ActivityStorage.query(
      limit: limit,
      offset: offset,
    );
    if (mounted) {
      setState(() {
        this.activities.addAll(acs);
        offset = this.activities.length;
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
                padding: EdgeInsets.only(bottom: 15),
                controller: scrollController,
                itemBuilder: buildActivity,
                itemCount: activities.length,
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
    return Column(
      children: <Widget>[
        ActivityCard(
          activity,
          hasAvatar: true,
        ),
        Visibility(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: loading
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).primaryColor),
                    )
                  : Text(
                      'load more',
                      style: TextStyle(
                        color:
                            Theme.of(context).primaryTextTheme.display2.color,
                        fontSize: 17,
                      ),
                    ),
            ),
          ),
          visible: index == offset - 1,
        )
      ],
    );
  }
}
