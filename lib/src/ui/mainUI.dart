import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:veatre/src/ui/tabViews.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class MainUI extends StatefulWidget {
  static const routeName = '/';

  @override
  MainUIState createState() => MainUIState();
}

class MainUIState extends State<MainUI>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  Network currentNet;
  int mainNetID = 0;
  int testNetID = 0;
  bool canBack = false;
  bool canForward = false;
  PageController netPageController = PageController(initialPage: 0);
  PageController mainNetPageController = PageController(initialPage: 0);
  PageController testNetPageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    if (mainNetWebViews.length == 0) {
      createWebView(Network.MainNet, (controller) async {
        await updateBackForward();
      });
    }
    if (testNetWebViews.length == 0) {
      createWebView(Network.TestNet, (controller) async {
        await updateBackForward();
      });
    }
    NetworkStorage.isMainNet.then((isMainNet) {
      setState(() {
        currentNet = isMainNet ? Network.MainNet : Network.TestNet;
        netPageController.jumpToPage(isMainNet ? 0 : 1);
      });
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    PageView mainNetPageView = PageView.builder(
      controller: mainNetPageController,
      itemCount: mainNetWebViews.length,
      itemBuilder: (context, index) {
        return mainNetWebViews[index];
      },
      physics: NeverScrollableScrollPhysics(),
    );
    PageView testNetPageView = PageView.builder(
      controller: testNetPageController,
      itemCount: testNetWebViews.length,
      itemBuilder: (context, index) {
        return testNetWebViews[index];
      },
      physics: NeverScrollableScrollPhysics(),
    );
    PageView pageView = PageView(
      children: <Widget>[
        mainNetPageView,
        testNetPageView,
      ],
      physics: NeverScrollableScrollPhysics(),
      controller: netPageController,
    );
    return Scaffold(
      body: pageView,
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
                return goBack(
                  currentNet,
                  currentNet == Network.MainNet ? mainNetID : testNetID,
                );
              }
              break;
            case 1:
              if (canForward) {
                return goForward(
                  currentNet,
                  currentNet == Network.MainNet ? mainNetID : testNetID,
                );
              }
              break;
            case 2:
              return reload(
                currentNet,
                currentNet == Network.MainNet ? mainNetID : testNetID,
              );
            case 3:
              Uint8List captureData = await takeScreenshot(
                currentNet,
                currentNet == Network.MainNet ? mainNetID : testNetID,
              );
              String t = await title;
              updateSnapshot(
                currentNet,
                currentNet == Network.MainNet ? mainNetID : testNetID,
                title: t == "" ? 'New Tab' : t,
                data: captureData,
              );
              TabResult tabResult = await _present(TabViews(
                id: currentNet == Network.MainNet ? mainNetID : testNetID,
                net: currentNet,
              ));
              if (tabResult != null) {
                if (tabResult.stage == TabStage.Created ||
                    tabResult.stage == TabStage.RemovedAll) {
                  setState(() {
                    createWebView(currentNet, (controller) async {
                      await updateBackForward();
                    });
                  });
                  if (currentNet == Network.MainNet) {
                    mainNetID = mainNetWebViews.length - 1;
                    mainNetPageController
                        .jumpToPage(mainNetWebViews.length - 1);
                  } else {
                    testNetID = testNetWebViews.length - 1;
                    testNetPageController
                        .jumpToPage(testNetWebViews.length - 1);
                  }
                } else if (tabResult.stage == TabStage.Selected) {
                  int selectedID = tabResult.id;
                  if (currentNet == Network.MainNet &&
                      selectedID != mainNetID) {
                    mainNetID = selectedID;
                    mainNetPageController.jumpToPage(selectedID);
                  } else if (selectedID != testNetID) {
                    testNetID = selectedID;
                    testNetPageController.jumpToPage(selectedID);
                  }
                }
                await updateBackForward();
              }
              break;
            case 4:
              await _present(Settings());
              bool isMainNet = await NetworkStorage.isMainNet;
              currentNet = isMainNet ? Network.MainNet : Network.TestNet;
              netPageController.jumpToPage(isMainNet ? 0 : 1);
              await updateBackForward();
              break;
          }
        },
      );

  BottomNavigationBarItem bottomNavigationBarItem(
    IconData iconData,
    Color color,
    double size,
  ) {
    Widget nullWidget = SizedBox(height: 0);
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
        30,
      ),
      bottomNavigationBarItem(
        Icons.arrow_forward_ios,
        canForward ? active : inactive,
        30,
      ),
      bottomNavigationBarItem(
        Icons.refresh,
        active,
        40,
      ),
      bottomNavigationBarItem(
        Icons.filter_none,
        active,
        30,
      ),
      bottomNavigationBarItem(
        Icons.more_horiz,
        active,
        30,
      ),
    ];
  }

  Future<String> get title async {
    return getTitle(
      currentNet,
      currentNet == Network.MainNet ? mainNetID : testNetID,
    );
  }

  Future<void> updateBackForward() async {
    bool canBack = await canGoBack(
      currentNet,
      currentNet == Network.MainNet ? mainNetID : testNetID,
    );
    bool canForward = await canGoForward(
      currentNet,
      currentNet == Network.MainNet ? mainNetID : testNetID,
    );
    setState(() {
      this.canBack = canBack;
      this.canForward = canForward;
    });
  }

  Future<dynamic> _present(Widget widget) async {
    dynamic result = await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, a, b) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset.zero).animate(a),
          child: widget,
        );
      },
    );
    return result;
  }
}
