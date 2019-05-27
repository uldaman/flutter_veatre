import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:vetheat/common/event_bus.dart';
import 'package:vetheat/common/search_widget.dart';
import 'package:vetheat/common/vechain.dart';

String initialUrl = "about:blank";

class CustomWebView extends StatefulWidget {
  final onWebViewCreatedCallback onWebViewCreated;
  final onWebViewLoadStopCallback onLoadStop;

  const CustomWebView({
    Key key,
    this.onWebViewCreated,
    this.onLoadStop,
  }) : super(key: key);

  @override
  _CustomWebViewState createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView>
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
      body: InAppWebView(
        initialUrl: initialUrl,
        onWebViewCreated: (InAppWebViewController controller) {
          controller.addJavaScriptHandler("debugLog", (arguments) async {
            debugPrint("debugLog: " + arguments.join(","));
          });
          controller.addJavaScriptHandler("webChanged", (arguments) async {
            bus.emit("webChanged");
          });
          controller.addJavaScriptHandler("vechain", (arguments) async {
            return Vechain().callMethod(arguments);
          });
          // TODO, 心跳
          widget.onWebViewCreated(controller);
        },
        onLoadStop: (InAppWebViewController controller, String url) async {
          widget.onLoadStop(controller, url);
        },
        onProgressChanged: (InAppWebViewController controller, int progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
      ),
    );
  }
}
