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

class MainUI extends StatefulWidget {
  static const routeName = '/';

  @override
  MainUIState createState() => MainUIState();
}

class MainUIState extends State<MainUI>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  int tabID = 0;
  final GlobalKey captureKey = GlobalKey();
  bool canBack = false;
  bool canForward = false;
  @override
  void initState() {
    super.initState();
    createWebView((controller) async {
      await updateBackForward();
    });
  }

  @override
  void dispose() {
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
                return goBack(tabID);
              }
              break;
            case 1:
              if (canForward) {
                return goForward(tabID);
              }
              break;
            case 2:
              return reload(tabID);
            case 3:
              Uint8List captureData = await takeScreenshot(tabID);
              String t = await title;
              setState(() {
                updateSnapshot(
                  tabID,
                  title: t == "" ? 'New Tab' : t,
                  data: captureData,
                );
              });
              TabResult tabResult = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TabViews(
                    id: tabID,
                  );
                }),
              );
              if (tabResult != null) {
                if (tabResult.stage == TabStage.Created ||
                    tabResult.stage == TabStage.RemovedAll) {
                  setState(() {
                    createWebView((controller) async {
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
