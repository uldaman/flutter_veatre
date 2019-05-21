import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:vetheat/common/event_bus.dart';
import 'package:vetheat/common/search_widget.dart';

String initialUrl = "about:blank";

class FeedScreens {
  FeedScreens._internal();
  static FeedScreens _singleton = new FeedScreens._internal();
  factory FeedScreens() => _singleton;

  int _currentIdx = 0;
  List<FeedScreen> _feeds = <FeedScreen>[];
  Map<int, InAppWebViewController> _ctrlMap = {};

  int get length => _feeds.length;

  FeedScreen get current {
    if (length == 0) {
      _currentIdx = addFeed();
    }
    return _feeds[_currentIdx];
  }

  FeedScreen operator [](int idx) {
    return _feeds[idx];
  }

  int addFeed() {
    final index = length;
    FeedScreen feed = FeedScreen(
      onScreenCreated: (InAppWebViewController controller) {
        _ctrlMap[index] = controller;
        initialUrl = "about:blank";
      },
    );
    _feeds.add(feed);
    return index;
  }

  // TODO: 处理 _currentIdx
  void removeFeed(int index) {
    if (index >= 0 && index < length) {
      _feeds.removeAt(index);
      _ctrlMap.remove(index);
    }
  }

  void goBack() {
    if (_ctrlMap[_currentIdx] != null) {
      _ctrlMap[_currentIdx].goBack();
    }
  }

  void goForward() {
    if (_ctrlMap[_currentIdx] != null) {
      _ctrlMap[_currentIdx].goForward();
    }
  }

  Future<bool> canGoBack() async {
    if (_ctrlMap[_currentIdx] == null) {
      return false;
    }
    return await _ctrlMap[_currentIdx].canGoBack();
  }

  Future<bool> canGoForward() async {
    if (_ctrlMap[_currentIdx] == null) {
      return false;
    }
    return await _ctrlMap[_currentIdx].canGoForward();
  }

  void loadUrl(String url) {
    if (_currentIdx < 0) {
      addFeed();
    } else if (_ctrlMap[_currentIdx] != null) {
      _ctrlMap[_currentIdx].loadUrl(url);
    } else {
      initialUrl = url;
    }
  }
}

FeedScreens feeds = new FeedScreens();

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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.0),
      child: SizedBox(
        height: 2.0,
        child: new LinearProgressIndicator(value: value),
      ),
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
