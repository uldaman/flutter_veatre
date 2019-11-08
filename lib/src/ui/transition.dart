import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<dynamic> slide(BuildContext context, Widget widget,
    {String routeName}) async {
  PageRouteBuilder pageRouteBuilder = PageRouteBuilder(
    barrierDismissible: false,
    maintainState: false,
    fullscreenDialog: false,
    pageBuilder: (context, a, b) {
      return widget;
    },
    transitionsBuilder: (context, a, b, child) {
      return SlideTransition(
        position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(a),
        transformHitTests: false,
        child: child,
      );
    },
    settings: routeName == null ? null : RouteSettings(name: routeName),
  );
  return Navigator.of(context).push(pageRouteBuilder);
}
