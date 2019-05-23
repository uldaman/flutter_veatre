import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:vetheat/screen/feed_screen.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

InAppWebViewController webView;

class TabScreen extends StatefulWidget {
  final bool spread;

  const TabScreen({Key key, this.spread = false}) : super(key: key);

  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen>
    with AutomaticKeepAliveClientMixin {
  int _currentPage = 0;
  List<Widget> _feeds = <Widget>[];
  Map<int, InAppWebViewController> _ctrlMap = {};

  @override
  bool get wantKeepAlive => true;

  FeedScreen _makeFeedScreen(int index) {
    return FeedScreen(
      onScreenCreated: (InAppWebViewController controller) {
        _ctrlMap[index] = controller;
        webView = controller;
        initialUrl = "about:blank";
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _feeds.add(_makeFeedScreen(0));
    _feeds.add(
      IconButton(
        icon: Icon(Icons.add_circle),
        onPressed: () {
          int index = _feeds.length - 1;
          setState(() {
            _feeds.insert(index, _makeFeedScreen(index));
          });
        },
      ),
    );
  }

  void onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      if (_currentPage < _feeds.length - 1) {
        webView = _ctrlMap[_currentPage];
      }
    });
  }

  void onPageTap(int page) {
    setState(() {
      // TODO: open web
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: widget.spread
          ? AppBar(
              backgroundColor: Colors.white,
              title: Text('Tabs'),
              centerTitle: true,
            )
          : null,
      body: Swiper(
        index: _currentPage,
        itemCount: _feeds.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildPage(index);
        },
        onIndexChanged: onPageChanged,
        onTap: onPageTap,
        viewportFraction: widget.spread ? 0.8 : 1.0,
        loop: false,
        physics: widget.spread
            ? PageScrollPhysics()
            : NeverScrollableScrollPhysics(),
      ),
    );
  }

  AnimatedContainer _buildPage(int index) {
    final bool active = index == _currentPage;
    final Widget page = _feeds[index];
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(
        top: widget.spread ? (active ? 100 : 200) : 0,
        bottom: widget.spread ? 50 : 0,
        right: widget.spread ? 30 : 0,
      ),
      child: PhysicalModel(
        elevation: widget.spread ? (active ? 20.0 : 1.0) : 0,
        child: page,
        color: Colors.transparent,
        // https://github.com/OpenFlutter/amap_base_flutter/issues/58
        // borderRadius: BorderRadius.circular(35.0),
        // clipBehavior: Clip.hardEdge,
        shadowColor: (page is IconButton || !widget.spread)
            ? Colors.transparent
            : Colors.black87,
      ),
    );
  }
}
