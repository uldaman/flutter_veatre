import 'package:flutter/cupertino.dart';

Future<dynamic> slide(BuildContext context, Widget widget,
    {String routeName}) async {
  PageRouteBuilder pageRouteBuilder;
  if (routeName != null) {
    pageRouteBuilder = PageRouteBuilder(
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, a, b) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset.zero).animate(a),
          child: widget,
        );
      },
      settings: RouteSettings(name: routeName),
    );
  } else {
    pageRouteBuilder = PageRouteBuilder(
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, a, b) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset.zero).animate(a),
          child: widget,
        );
      },
    );
  }
  return Navigator.of(context).push(pageRouteBuilder);
}
