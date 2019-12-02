import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/ui/webViews.dart';

class TabViews extends StatefulWidget {
  final int id;
  final double ratio;
  final String url;
  final String currentTabKey;

  TabViews({
    this.id,
    this.ratio,
    this.url,
    this.currentTabKey,
  });

  @override
  TabViewsState createState() => TabViewsState();
}

class TabViewsState extends State<TabViews> {
  List<Snapshot> snapshots;
  int selectedTab;
  bool isSelectedTabAlive = true;
  String url;
  String selectedTabKey;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.id;
    url = widget.url;
    snapshots = WebViews.snapshots();
    selectedTabKey = widget.currentTabKey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(15),
                physics: ClampingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: widget.ratio,
                ),
                itemCount: snapshots.length,
                itemBuilder: (context, index) {
                  return snapshotCard(index);
                },
              ),
            ),
            Container(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  FlatButton(
                    child: Text('Close All'),
                    onPressed: () {
                      WebViews.removeAll();
                      setState(() {
                        snapshots = WebViews.snapshots();
                      });
                      WebViews.create();
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: 35,
                    ),
                    onPressed: () {
                      WebViews.create();
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text('Done'),
                    onPressed: () {
                      Globals.updateTabValue(
                        TabControllerValue(
                          id: selectedTab,
                          url: url,
                          network: Globals.network,
                          stage: isSelectedTabAlive
                              ? TabStage.SelectedAlive
                              : TabStage.SelectedInAlive,
                          tabKey: selectedTabKey,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget snapshotCard(int index) {
    Snapshot snapshot = snapshots[index];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          width: 2,
          color: selectedTabKey == snapshot.key
              ? Theme.of(context).primaryColor
              : Color(0xFF666666),
        ),
      ),
      child: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 10, right: 40),
                        child: FutureBuilder<String>(
                          future: snapshot.title,
                          builder: (context, snapshot) => Text(
                            !snapshot.hasData
                                ? 'New Tab'
                                : snapshot.data == ''
                                    ? 'New Tab'
                                    : snapshot.data,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 17,
                      ),
                      onPressed: () async {
                        WebViews.removeSnapshot(
                          snapshot.key,
                        );
                        setState(() {
                          snapshots = WebViews.snapshots();
                        });
                        if (snapshots.length == 0) {
                          WebViews.removeWebview(
                            snapshot.id,
                          );
                          WebViews.create();
                          Navigator.of(context).pop();
                          return;
                        }
                        if (snapshot.isAlive) {
                          WebViews.removeWebview(
                            snapshot.id,
                          );
                        }
                        if (index == 0) {
                          selectedTab = snapshots.first.id;
                          isSelectedTabAlive = snapshots.first.isAlive;
                          url = snapshots.first.url;
                          selectedTabKey = snapshots.first.key;
                        } else if (selectedTab == snapshot.id) {
                          selectedTab = snapshots[index - 1].id;
                          isSelectedTabAlive = snapshots[index - 1].isAlive;
                          url = snapshots[index - 1].url;
                          selectedTabKey = snapshots[index - 1].key;
                        }
                        if (snapshot.isAlive) {
                          Globals.updateTabValue(
                            TabControllerValue(
                              id: snapshot.id,
                              url: url,
                              network: Globals.network,
                              stage: TabStage.Removed,
                              tabKey: selectedTabKey,
                            ),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 0),
              child: GestureDetector(
                child: FutureBuilder<Uint8List>(
                  future: snapshot.data,
                  builder: (context, snapshot) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      image: DecorationImage(
                        alignment: Alignment.topCenter,
                        fit: BoxFit.fitWidth,
                        image: snapshot.hasData
                            ? MemoryImage(snapshot.data)
                            : AssetImage('assets/blank.png'),
                      ),
                    ),
                  ),
                ),
                onTapUp: (tap) {
                  Globals.updateTabValue(
                    TabControllerValue(
                      id: snapshot.id,
                      network: Globals.network,
                      url: snapshot.url,
                      stage: snapshot.isAlive
                          ? TabStage.SelectedAlive
                          : TabStage.SelectedInAlive,
                      tabKey: snapshot.key,
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
