import 'package:flutter/material.dart';
import 'package:veatre/common/web_views.dart' as web_view;

class SearchWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(),
      child: Material(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        elevation: 2.0,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10.0),
          child: TextField(
            maxLines: 1,
            keyboardAppearance: Brightness.light,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(bottom: 6.0, top: 8.0),
              hintText: "Url | app | block | tx | account",
              border: InputBorder.none,
            ),
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }

  onSubmitted(String url) {
    if (url != "") {
      web_view.loadUrl(url);
    }
  }
}
