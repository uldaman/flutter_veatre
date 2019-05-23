import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:vetheat/common/event_bus.dart';
import 'package:vetheat/common/search_widget.dart';

String initialUrl = "about:blank";

class FeedScreen extends StatefulWidget {
  final onWebViewCreatedCallback onScreenCreated;

  const FeedScreen({
    Key key,
    @required this.onScreenCreated,
  }) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double _progress = 0;

  Widget _progressIndicator(double value) {
    return Padding(
      child: SizedBox(
        height: 2.5,
        child: PhysicalModel(
          child: LinearProgressIndicator(value: value),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(45.0),
          clipBehavior: Clip.hardEdge,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SearchWidget(),
              (_progress != 1.0) ? _progressIndicator(_progress) : null,
            ].where((Object o) => o != null).toList(),
          ),
          padding: EdgeInsets.only(bottom: 3.0),
        ),
      ),
      body: Center(
        child: InAppWebView(
          initialUrl: initialUrl,
          onWebViewCreated: (InAppWebViewController controller) {
            webView.addJavaScriptHandler("pageChange", (arguments) async {
            widget.onScreenCreated(controller);
              bus.emit("pageChange");
            });
          },
        ),
      ),
    );
  }
}
