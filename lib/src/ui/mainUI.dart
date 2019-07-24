import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:veatre/common/driver.dart';
import 'package:veatre/src/ui/tabViews.dart';
import 'package:veatre/src/ui/webView.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/ui/settings.dart';

class MainUI extends StatefulWidget {
  static const routeName = '/';

  @override
  MainUIState createState() => MainUIState();
}

class MainUIState extends State<MainUI> with AutomaticKeepAliveClientMixin {
  int tabID = 0;
  HeadValueController headValueController = HeadValueController(driver.genesis);
  Timer _timer;
  final GlobalKey captureKey = GlobalKey();
  bool canBack = false;
  bool canForward = false;

  @override
  void initState() {
    super.initState();
    createWebView(headValueController, (controller) async {
      await updateBackForward();
    });
    BlockHead currentHead = driver.genesis;
    _timer = Timer.periodic(Duration(seconds: 5), (time) async {
      BlockHead head = BlockHead.fromJSON(await driver.head);
      if (head.number != currentHead.number) {
        currentHead = head;
        headValueController.value = currentHead;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    headValueController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  PageController pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    PageView pageView = PageView.builder(
      controller: pageController,
      itemCount: webViews.length,
      itemBuilder: (context, index) {
        return webViews[index];
      },
      physics: NeverScrollableScrollPhysics(),
    );
    return Scaffold(
      body: RepaintBoundary(
        key: captureKey,
        child: pageView,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  BottomNavigationBar get bottomNavigationBar => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: bottomNavigationBarItems,
        onTap: (index) async {
          switch (index) {
            case 0:
              if (canBack) {
                await goBack(tabID);
              }
              break;
            case 1:
              if (canForward) {
                await goForward(tabID);
              }
              break;
            case 2:
              await reload(tabID);
              break;
            case 3:
              Uint8List captureData = await takeScreenshot(tabID);
              String t = await title;
              setState(() {
                updateSnapshot(
                  tabID,
                  title: t ?? 'New Tab',
                  data: captureData,
                );
              });
              TabResult tabResult = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TabViews();
                }),
              );
              if (tabResult != null) {
                if (tabResult.stage == TabStage.Created ||
                    tabResult.stage == TabStage.RemovedAll) {
                  setState(() {
                    createWebView(headValueController, (controller) async {
                      await updateBackForward();
                    });
                  });
                  setState(() {
                    tabID = webViews.length - 1;
                    pageController.jumpToPage(webViews.length - 1);
                  });
                } else if (tabResult.stage == TabStage.Selected) {
                  if (tabResult.id != tabID) {
                    setState(() {
                      tabID = tabResult.id;
                      pageController.jumpToPage(tabID);
                    });
                  }
                }
              }
              break;
            case 4:
              await Navigator.of(context).pushNamed(Settings.routeName);
              break;
          }
        },
      );

  BottomNavigationBarItem bottomNavigationBarItem(
    IconData iconData,
    Color color,
  ) {
    Widget nullWidget = SizedBox(height: 0);
    double size = 30;
    return BottomNavigationBarItem(
      icon: Icon(
        iconData,
        size: size,
        color: color,
      ),
      title: nullWidget,
    );
  }

  List<BottomNavigationBarItem> get bottomNavigationBarItems {
    Color active = Colors.blue;
    Color inactive = Colors.grey[300];
    return [
      bottomNavigationBarItem(
        Icons.arrow_back_ios,
        canBack ? active : inactive,
      ),
      bottomNavigationBarItem(
        Icons.arrow_forward_ios,
        canForward ? active : inactive,
      ),
      bottomNavigationBarItem(
        Icons.refresh,
        active,
      ),
      bottomNavigationBarItem(
        Icons.filter_none,
        active,
      ),
      bottomNavigationBarItem(
        Icons.more_horiz,
        active,
      ),
    ];
  }

  Future<String> get title async {
    return getTitle(tabID);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateBackForward();
  }

  Future<void> updateBackForward() async {
    bool canBack = await canGoBack(tabID);
    bool canForward = await canGoForward(tabID);
    setState(() {
      this.canBack = canBack;
      this.canForward = canForward;
    });
  }
}
