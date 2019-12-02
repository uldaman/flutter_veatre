import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/authentication/decision.dart';
import 'package:veatre/src/ui/webViews.dart';

class MainUI extends StatefulWidget {
  static const routeName = '/home';

  MainUI({Key key}) : super(key: key);

  @override
  MainUIState createState() => MainUIState();
}

class MainUIState extends State<MainUI>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  Network network = Globals.network;
  int _timestamp = 0;
  bool _pageLocked = false;
  AppLifecycleState _state = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WebViews.create(network: Network.MainNet);
    WebViews.create(network: Network.TestNet);
    Globals.addNetworkHandler(_hanleNetworkChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        _state == AppLifecycleState.resumed) {
      _state = state;
      _timestamp = currentTime;
    } else if (state == AppLifecycleState.resumed) {
      if ((_state == AppLifecycleState.paused ||
              _state == AppLifecycleState.inactive) &&
          currentTime - _timestamp > 5 * 1000 &&
          !_pageLocked) {
        _present(Decision());
      }
      _state = AppLifecycleState.resumed;
    }
    super.didChangeAppLifecycleState(state);
  }

  void _hanleNetworkChanged() {
    setState(() {
      network = Globals.network;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Globals.removeNetworkHandler(_hanleNetworkChanged);
    super.dispose();
  }

  Future<dynamic> _present(Widget widget) async {
    _pageLocked = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => widget,
        fullscreenDialog: true,
        settings: RouteSettings(isInitialRoute: true),
      ),
    );
    _pageLocked = false;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Stack testStack = Stack(
      children: WebViews.testNetWebViews,
    );
    Stack mainStack = Stack(
      children: WebViews.mainNetWebViews,
    );
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Offstage(
            child: testStack,
            offstage: network != Network.TestNet,
          ),
          Offstage(
            child: mainStack,
            offstage: network != Network.MainNet,
          ),
        ],
      ),
    );
  }
}
