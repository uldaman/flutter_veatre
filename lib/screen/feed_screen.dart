import 'package:flutter/material.dart';
import 'package:veatre/common/event.dart';
import 'package:veatre/common/web_views.dart' as web_view;

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FeedScreentate();
}

class _FeedScreentate extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController(keepPage: false);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    web_view.createWebView();
    onWebViewSelected.on((arg) {
      web_view.index = arg;
      _pageController.jumpToPage(arg);
      onWebChanged.emit();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PageView(
      children: web_view.views,
      physics: NeverScrollableScrollPhysics(),
      controller: _pageController,
    );
  }
}
