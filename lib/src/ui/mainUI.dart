import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/unlock.dart';
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
  Appearance appearance = Globals.appearance;
  int timestamp = 0;
  bool lockPagePresented = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WebViews.initialWebViews(appearance: appearance);
    Globals.addNetworkHandler(_hanleNetworkChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      timestamp = currentTime;
    }
    if (state == AppLifecycleState.resumed &&
        currentTime - timestamp > 30 * 1000 &&
        !lockPagePresented) {
      Globals.clearMasterPasscodes();
      _present(
        Unlock(
          everLaunched: true,
        ),
      );
    }
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
    lockPagePresented = true;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, a, b) {
        return ScaleTransition(
          scale: Tween(begin: 0.0, end: 1.0).animate(a),
          child: widget,
        );
      },
    );
    lockPagePresented = false;
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
