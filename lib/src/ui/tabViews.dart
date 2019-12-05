import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
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
  ScrollController controller;
  int _currentIndex;
  double ratio;
  bool didPush = false;
  bool shouldPop = false;
  Size pushItemSize;
  Size popItemSize;
  Offset pushItemPosition;
  Offset popItemPosition;

  double itemWidth;
  double itemHeight;
  double contenHeight;
  double dx;
  double dy;
  double gridViewPadding = 15.0;
  double itemVerticalSpacing = 10.0;
  double itemHorizontalSpacing = 10.0;
  double toolBarHeight = 59.0;
  double dividerHeight = 1.0;
  @override
  void initState() {
    super.initState();
    pushItemSize = widget.size;
    pushItemPosition = Offset(0, 0);
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

    WidgetsBinding.instance.addPostFrameCallback((duration) async {
      setState(() {
        pushItemSize = Size(itemWidth, itemHeight);
        pushItemPosition = Offset(dx, dy);
      });
    });
  }

  _handleScroll() {
    final offset = controller.offset;
    final fullHeight =
        (_currentIndex ~/ 2) * (itemHeight + itemVerticalSpacing);
    double y = (fullHeight - offset) % contenHeight;
    if (y == itemVerticalSpacing && _currentIndex != 0) {
      y = contenHeight - 6;
    }
    final x = _currentIndex % 2 == 0
        ? gridViewPadding
        : gridViewPadding + itemWidth + itemHorizontalSpacing;
    popItemPosition = Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, cons) {
            itemWidth = (widget.size.width -
                    2 * gridViewPadding -
                    itemHorizontalSpacing) /
                2;
            itemHeight = itemWidth / ratio;
            final fullHeight =
                (_currentIndex ~/ 2 + 1) * (itemHeight + itemVerticalSpacing) -
                    itemVerticalSpacing;
            contenHeight = cons.maxHeight -
                2 * gridViewPadding -
                toolBarHeight -
                dividerHeight;
            double offset = 0;
            if (fullHeight > contenHeight) {
              offset = fullHeight - contenHeight;
            }
            if (dx == null) {
              dx = _currentIndex % 2 == 0
                  ? gridViewPadding
                  : gridViewPadding + itemWidth + itemHorizontalSpacing;
              dy = fullHeight > contenHeight
                  ? contenHeight - itemHeight + gridViewPadding
                  : fullHeight - itemHeight + gridViewPadding;
              popItemSize = Size(itemWidth, itemHeight);
              popItemPosition = Offset(dx, dy);
              controller = ScrollController(initialScrollOffset: offset);
            }
            return Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Expanded(
                      child: Stack(
                        children: <Widget>[
                          GridView.builder(
                            controller: controller,
                            scrollDirection: Axis.vertical,
                            padding: EdgeInsets.all(gridViewPadding),
                            physics: ClampingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
                          pushSnapshot(),
                          Visibility(
                            visible: shouldPop,
                            child: popSnapshot(),
                          ),
                        ],
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
                              snapshots.add(
                                Snapshot(
                                  title: Future.value(""),
                                  data: Future.value(null),
                                ),
                              );
                              _currentIndex = snapshots.length - 1;
                              handlePop();
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
                              handlePop();
                            },
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget title(
    Snapshot snapshot, {
    Function close,
    bool shouldHide = false,
  }) {
    return Stack(
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
                      shouldHide
                          ? ""
                          : !snapshot.hasData
                              ? 'New Tab'
                              : snapshot.data == '' ? 'New Tab' : snapshot.data,
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
                onPressed: close,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget image(Snapshot snapshot) {
    return FutureBuilder<Uint8List>(
      future: snapshot.data,
      builder: (context, snapshot) => snapshot.hasData
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                image: DecorationImage(
                    alignment: Alignment.topCenter,
                    fit: BoxFit.fitWidth,
                    image: MemoryImage(snapshot.data)),
              ),
            )
          : Container(
              color: Theme.of(context).backgroundColor,
            ),
    );
  }

  Widget popSnapshot() {
    Snapshot snapshot = snapshots[_currentIndex];
    return AnimatedContainer(
      onEnd: () {
        Navigator.of(context).pop();
      },
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(
          left: popItemPosition.dx,
          top: popItemPosition.dy + kToolbarHeight + dividerHeight),
      width: popItemSize.width,
      height: popItemSize.height,
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
      ),
      child: Column(
        children: <Widget>[
          // title(snapshot, shouldHide: true),
          Expanded(
            child: image(snapshot),
          ),
        ],
      ),
    );
  }

  Widget pushSnapshot() {
    Snapshot snapshot = snapshots[_currentIndex];
    return Offstage(
      offstage: didPush,
      child: AnimatedContainer(
        onEnd: () {
          setState(() {
            didPush = true;
          });
        },
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(
            left: pushItemPosition.dx, top: pushItemPosition.dy),
        width: pushItemSize.width,
        height: pushItemSize.height,
        decoration: decoration(snapshot),
        child: Column(
          children: <Widget>[
            title(snapshot, shouldHide: true),
            Expanded(
              child: image(snapshot),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration decoration(Snapshot snapshot) {
    return BoxDecoration(
      color: Theme.of(context).backgroundColor,
      borderRadius: BorderRadius.all(Radius.circular(10)),
      border: Border.all(
        width: 2,
        color: selectedTabKey == snapshot.key
            ? Theme.of(context).primaryColor
            : Color(0xFF666666),
      ),
    );
  }

  Widget snapshotCard(int index) {
    Snapshot snapshot = snapshots[index];
    return Offstage(
      offstage: (!didPush || shouldPop) && index == _currentIndex,
      child: Container(
        decoration: decoration(snapshot),
        child: Column(
          children: <Widget>[
            title(
              snapshot,
              close: () async {
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
                  _currentIndex = index;
                } else if (selectedTab == snapshot.id) {
                  selectedTab = snapshots[index - 1].id;
                  isSelectedTabAlive = snapshots[index - 1].isAlive;
                  url = snapshots[index - 1].url;
                  selectedTabKey = snapshots[index - 1].key;
                  _currentIndex = index - 1;
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
                _handleScroll();
              },
            ),
            Expanded(
              child: GestureDetector(
                child: image(snapshot),
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
                  _currentIndex = index;
                  handlePop();
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  handlePop() async {
    _handleScroll();
    setState(() {
      shouldPop = true;
    });
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      popItemSize = widget.size;
      popItemPosition = Offset(0, 0);
    });
  }
}
