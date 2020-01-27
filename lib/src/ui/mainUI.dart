import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/authentication/decision.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/utils/validators.dart';

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
    WidgetsBinding.instance
        .addPostFrameCallback((duration) => updateClipboard());
    WebViews.create(network: Network.MainNet);
    WebViews.create(network: Network.TestNet);
    Globals.addNetworkHandler(_hanleNetworkChanged);
    Globals.addTabHandler(_handleTabChanged);
  }

  _handleTabChanged() {
    if (Globals.tabValue.stage == TabStage.Created) {
      setState(() {});
    }
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
          currentTime - _timestamp > 30 * 1000 &&
          !_pageLocked) {
        _present(Decision());
      } else {
        updateClipboard();
      }
      _state = AppLifecycleState.resumed;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Future<bool> didPushRoute(String route) {
    return super.didPushRoute(route);
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
    await updateClipboard();
    _pageLocked = false;
  }

  Future<void> updateClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null) {
      final text = data.text;
      if (Globals.clipboardValue.data != text &&
          (isAddress(text) || isHash(text))) {
        Globals.updateClipboardValue(ClipboardValue(data: text));
      }
    }
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
