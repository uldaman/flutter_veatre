import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class MainUI extends StatefulWidget {
  static const routeName = '/';

  MainUI({Key key}) : super(key: key);

  @override
  MainUIState createState() => MainUIState();
}

class MainUIState extends State<MainUI> with AutomaticKeepAliveClientMixin {
  Network network = Globals.network;
  Appearance appearance = Globals.appearance;

  PageController netPageController = PageController(initialPage: 0);
  PageController mainNetPageController = PageController(initialPage: 0);
  PageController testNetPageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    WebViews.initialWebViews(appearance: appearance);
    netPageController =
        PageController(initialPage: network == Network.MainNet ? 0 : 1);
    Globals.addNetworkHandler(_hanleNetworkChanged);
    Globals.addTabHandler(_handleTabChanged);
  }

  void _hanleNetworkChanged() {
    setState(() {
      network = Globals.network;
      netPageController.jumpToPage(network == Network.MainNet ? 0 : 1);
    });
  }

  void _handleTabChanged() {
    final tabControllerValue = Globals.tabControllerValue;
    if (tabControllerValue.stage != TabStage.Removed) {
      if (tabControllerValue.network == Network.MainNet) {
        setState(() {
          mainNetPageController.jumpToPage(tabControllerValue.id);
        });
      } else {
        setState(() {
          testNetPageController.jumpToPage(tabControllerValue.id);
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    Globals.removeTabHandler(_handleTabChanged);
    Globals.removeNetworkHandler(_hanleNetworkChanged);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    PageView testNetPageView = PageView.builder(
      controller: testNetPageController,
      itemCount: WebViews.testNetWebViews.length,
      itemBuilder: (context, index) {
        return WebViews.testNetWebViews[index];
      },
      physics: NeverScrollableScrollPhysics(),
    );
    PageView mainNetPageView = PageView.builder(
      controller: mainNetPageController,
      itemCount: WebViews.mainNetWebViews.length,
      itemBuilder: (context, index) {
        return WebViews.mainNetWebViews[index];
      },
      physics: NeverScrollableScrollPhysics(),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: PageView(
        children: <Widget>[
          mainNetPageView,
          testNetPageView,
        ],
        physics: NeverScrollableScrollPhysics(),
        controller: netPageController,
      ),
    );
  }
}
