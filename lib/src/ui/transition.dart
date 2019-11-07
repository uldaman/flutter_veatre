import 'package:flutter/cupertino.dart';

Future<dynamic> slide(BuildContext context, Widget widget,
    {String routeName}) async {
  PageRouteBuilder pageRouteBuilder = PageRouteBuilder(
    barrierDismissible: false,
    transitionDuration: Duration(milliseconds: 150),
    pageBuilder: (context, a, b) {
      return SlideTransition(
        position: Tween(begin: Offset(0, 1), end: Offset.zero).animate(a),
        child: widget,
      );
    },
    settings: routeName == null ? null : RouteSettings(name: routeName),
  );
  return Navigator.of(context).push(pageRouteBuilder);
}
