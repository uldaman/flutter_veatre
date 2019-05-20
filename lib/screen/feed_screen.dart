import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:vetheat/common/event_bus.dart';
import 'package:vetheat/common/search_widget.dart';

InAppWebViewController webView;
String initialUrl = "about:blank";

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Container(
          child: SearchWidget(),
          padding: EdgeInsets.only(bottom: 3.0),
        ),
      ),
      body: Center(
        child: InAppWebView(
          initialUrl: initialUrl,
          onWebViewCreated: (InAppWebViewController controller) {
            webView = controller;
            webView.addJavaScriptHandler("pageChange", (arguments) async {
              bus.emit("pageChange");
            });
          },
        ),
      ),
    );
  }
}
