import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class MainUI extends StatefulWidget {
  static const routeName = '/';

  MainUI({Key key}) : super(key: key);

  @override
  MainUIState createState() => MainUIState();
}

class MainUIState extends State<MainUI>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  Network network = Globals.network;
  Appearance appearance = Globals.appearance;

  PageController netPageController = PageController(initialPage: 0);
  PageController mainNetPageController = PageController(initialPage: 0);
  PageController testNetPageController = PageController(initialPage: 0);
  int timestamp;
  bool presented = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WebViews.initialWebViews(appearance: appearance);
    netPageController =
        PageController(initialPage: network == Network.MainNet ? 0 : 1);
    Globals.addNetworkHandler(_hanleNetworkChanged);
    Globals.addTabHandler(_handleTabChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (state == AppLifecycleState.paused) {
      timestamp = currentTime;
      print("AppLifecycleState.paused $timestamp");
    }
    if (state == AppLifecycleState.resumed) {
      print("AppLifecycleState.resumed $timestamp");
      if (currentTime - timestamp > 5 * 1000 && !presented) {
        presented = true;
        _present(ManageWallets());
      }
    }
  }

  void _hanleNetworkChanged() {
    setState(() {
      network = Globals.network;
      netPageController.jumpToPage(network == Network.MainNet ? 0 : 1);
    });
  }

  void _handleTabChanged() {
    final tabValue = Globals.tabValue;
    if (tabValue.stage != TabStage.Removed) {
      if (tabValue.network == Network.MainNet) {
        setState(() {
          mainNetPageController.jumpToPage(tabValue.id);
        });
      } else {
        setState(() {
          testNetPageController.jumpToPage(tabValue.id);
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    print("dispose");
    WidgetsBinding.instance.removeObserver(this);
    Globals.removeTabHandler(_handleTabChanged);
    Globals.removeNetworkHandler(_hanleNetworkChanged);
  }

  Future<dynamic> _present(Widget widget) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 500),
      pageBuilder: (context, a, b) {
        return ScaleTransition(
          scale: Tween(begin: 0.0, end: 1.0).animate(a),
          child: widget,
        );
      },
    );
    presented = false;
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
