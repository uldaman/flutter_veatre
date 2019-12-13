import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/ui/snapshotCard.dart';
import 'package:veatre/src/ui/webViews.dart';

class TabViews extends StatefulWidget {
  final int id;
  final Size size;
  final String url;
  final String currentTabKey;

  TabViews({
    this.id,
    this.size,
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
  int _currentIndex;
  double ratio;
  double gridViewPadding = 15.0;
  double itemVerticalSpacing = 10.0;
  double itemHorizontalSpacing = 10.0;
  double toolBarHeight = 59.0;
  double dividerHeight = 1.0;

  @override
  void initState() {
    super.initState();
    ratio = widget.size.width / widget.size.height;
    selectedTab = widget.id;
    url = widget.url;
    snapshots = WebViews.snapshots();
    selectedTabKey = widget.currentTabKey;
    for (int i = 0; i < snapshots.length; i++) {
      if (snapshots[i].key == selectedTabKey) {
        _currentIndex = i;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, cons) {
            double itemWidth = (MediaQuery.of(context).size.width -
                    2 * gridViewPadding -
                    itemHorizontalSpacing) /
                2;
            double itemHeight = itemWidth / ratio;
            final fullHeight =
                (_currentIndex ~/ 2 + 1) * (itemHeight + itemVerticalSpacing) -
                    itemVerticalSpacing;
            double contenHeight = cons.maxHeight -
                toolBarHeight -
                dividerHeight -
                2 * gridViewPadding;
            double offset = 0;
            if (fullHeight > contenHeight) {
              offset = fullHeight - contenHeight;
            }
            return Column(
              children: <Widget>[
                Expanded(
                  child: GridView.builder(
                    controller: ScrollController(initialScrollOffset: offset),
                    scrollDirection: Axis.vertical,
                    padding: EdgeInsets.all(gridViewPadding),
                    physics: ClampingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: itemHorizontalSpacing,
                      mainAxisSpacing: itemVerticalSpacing,
                      childAspectRatio: ratio,
                    ),
                    itemCount: snapshots.length,
                    itemBuilder: (context, index) {
                      return snapshotCard(index);
                    },
                  ),
                ),
                Divider(
                  thickness: 1,
                  height: dividerHeight,
                ),
                Container(
                  height: toolBarHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      FlatButton(
                        child: Text('Close All'),
                        onPressed: () {
                          WebViews.removeAll();
                          WebViews.create();
                          setState(() {
                            snapshots = [];
                          });
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
                          snapshots.add(Snapshot(title: '', data: null));
                          setState(() {
                            _currentIndex = snapshots.length - 1;
                          });
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
            );
          },
        ),
      ),
    );
  }

  Widget snapshotCard(int index) {
    Snapshot snapshot = snapshots[index];
    return _currentIndex == index
        ? Hero(
            tag: 'snapshot${snapshot.id}${Globals.network}',
            child: SnapshotCard(
              snapshot,
              true,
              hasCorner: true,
              isSelected: true,
              onClosed: () => close(snapshot, index),
              onSelected: () => select(snapshot, index),
            ),
          )
        : SnapshotCard(
            snapshot,
            true,
            hasCorner: true,
            onClosed: () => close(snapshot, index),
            onSelected: () => select(snapshot, index),
          );
  }

  void select(Snapshot snapshot, int index) {
    setState(() {
      _currentIndex = index;
    });
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
  }

  void close(Snapshot snapshot, int index) {
    WebViews.removeSnapshot(snapshot.key);
    setState(() {
      snapshots = WebViews.snapshots();
    });
    if (snapshots.length == 0) {
      WebViews.removeWebview(snapshot.id);
      WebViews.create();
      Navigator.of(context).pop();
      return;
    }
    if (snapshot.isAlive) {
      WebViews.removeWebview(
        snapshot.id,
      );
    }
    if (index > 0) {
      if (_currentIndex >= index) {
        _currentIndex--;
      }
    } else if (_currentIndex != 0) {
      _currentIndex--;
    }
    selectedTab = snapshots[_currentIndex].id;
    isSelectedTabAlive = snapshots[_currentIndex].isAlive;
    url = snapshots[_currentIndex].url;
    selectedTabKey = snapshots[_currentIndex].key;
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
  }
}
