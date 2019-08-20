import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:veatre/src/ui/createBookmark.dart';
import 'package:veatre/src/ui/tabViews.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class MainUI extends StatefulWidget {
  static const routeName = '/';
  final Network network;

  MainUI(this.network);

  @override
  MainUIState createState() => MainUIState();
}

class MainUIState extends State<MainUI> with AutomaticKeepAliveClientMixin {
  Network currentNet;
  int mainNetID = 0;
  int testNetID = 0;
  bool canBack = false;
  bool canForward = false;
  PageController netPageController = PageController(initialPage: 0);
  PageController mainNetPageController = PageController(initialPage: 0);
  PageController testNetPageController = PageController(initialPage: 0);
  String currentURL = Globals.initialURL;

  @override
  void initState() {
    super.initState();
    currentNet = widget.network;
    netPageController =
        PageController(initialPage: currentNet == Network.MainNet ? 0 : 1);
    if (WebViews.mainNetWebViews.length == 0) {
      WebViews.createWebView(Network.MainNet,
          (controller, network, id, url) async {
        await updateBackForward(network, id, url);
      });
    }
    if (WebViews.testNetWebViews.length == 0) {
      WebViews.createWebView(Network.TestNet,
          (controller, network, id, url) async {
        await updateBackForward(network, id, url);
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    PageView mainNetPageView = PageView.builder(
      controller: mainNetPageController,
      itemCount: WebViews.mainNetWebViews.length,
      itemBuilder: (context, index) {
        return WebViews.mainNetWebViews[index];
      },
      physics: NeverScrollableScrollPhysics(),
    );
    PageView testNetPageView = PageView.builder(
      controller: testNetPageController,
      itemCount: WebViews.testNetWebViews.length,
      itemBuilder: (context, index) {
        return WebViews.testNetWebViews[index];
      },
      physics: NeverScrollableScrollPhysics(),
    );
    return Scaffold(
      body: PageView(
        children: <Widget>[
          mainNetPageView,
          testNetPageView,
        ],
        physics: NeverScrollableScrollPhysics(),
        controller: netPageController,
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
                return WebViews.goBack(currentNet, currentID);
              }
              break;
            case 1:
              if (canForward) {
                return WebViews.goForward(currentNet, currentID);
              }
              break;
            case 2:
              String url = await WebViews.getURL(currentNet, currentID);
              if (url != Globals.initialURL) {
                String title = await WebViews.getTitle(currentNet, currentID);
                String favicon =
                    await WebViews.getFavicon(currentNet, currentID);
                if (favicon != null) {
                  Uri uri = Uri.parse(url);
                  final scheme = uri.scheme;
                  final host = uri.host;
                  if (favicon.startsWith('//')) {
                    favicon = '$scheme:$favicon';
                  } else if (favicon.startsWith('/')) {
                    favicon = '$scheme://$host$favicon';
                  } else if (favicon.startsWith('http')) {
                    favicon = favicon;
                  } else {
                    favicon = '$scheme://$host/$favicon';
                  }
                }
                print("favicon $favicon");
                Bookmark bookmark = Bookmark(
                  net: currentNet == Network.MainNet ? 0 : 1,
                  url: url,
                  title: title,
                  favicon: favicon,
                );
                await _present(CreateBookmark(bookmark: bookmark));
              }
              break;
            case 3:
              print('currentID $currentID $currentNet');
              Uint8List captureData =
                  await WebViews.takeScreenshot(currentNet, currentID);
              String t = await title;
              WebViews.updateSnapshot(
                currentNet,
                currentID,
                title: t == "" ? 'New Tab' : t,
                data: captureData,
              );
              TabResult tabResult = await _present(
                TabViews(
                  id: currentID,
                  net: currentNet,
                ),
              );
              if (tabResult != null) {
                if (tabResult.stage == TabStage.Created ||
                    tabResult.stage == TabStage.RemovedAll) {
                  setState(() {
                    WebViews.createWebView(currentNet,
                        (controller, network, id, url) async {
                      await updateBackForward(network, id, url);
                    });
                  });
                  if (currentNet == Network.MainNet) {
                    mainNetID = WebViews.mainNetWebViews.length - 1;
                    mainNetPageController
                        .jumpToPage(WebViews.mainNetWebViews.length - 1);
                  } else {
                    testNetID = WebViews.testNetWebViews.length - 1;
                    testNetPageController
                        .jumpToPage(WebViews.testNetWebViews.length - 1);
                  }
                } else if (tabResult.stage == TabStage.Selected) {
                  int selectedID = tabResult.id;
                  if (currentNet == Network.MainNet) {
                    mainNetID = selectedID;
                    mainNetPageController.jumpToPage(selectedID);
                  } else {
                    testNetID = selectedID;
                    testNetPageController.jumpToPage(selectedID);
                  }
                }
                await updateBackForward(currentNet, currentID, currentURL);
              }
              break;
            case 4:
              await _present(Settings());
              currentNet = await NetworkStorage.currentNet;
              netPageController
                  .jumpToPage(currentNet == Network.MainNet ? 0 : 1);
              await updateBackForward(currentNet, currentID, currentURL);
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
        Icons.star_border,
        currentURL != Globals.initialURL ? active : inactive,
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
    return WebViews.getTitle(
      currentNet,
      currentID,
    );
  }

  Future<void> updateBackForward(Network network, int id, String url) async {
    if (network == currentNet && id == currentID) {
      bool canBack = await WebViews.canGoBack(
        currentNet,
        currentID,
      );
      bool canForward = await WebViews.canGoForward(
        currentNet,
        currentID,
      );
      setState(() {
        currentURL = url;
        this.canBack = canBack;
        this.canForward = canForward;
      });
    }
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

  int get currentID => currentNet == Network.MainNet ? mainNetID : testNetID;
}
