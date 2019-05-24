import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vetheat/common/event.dart';
import 'package:vetheat/screen/feed_screen.dart';
import 'package:vetheat/screen/star_screen.dart';
import 'package:vetheat/screen/tab_screen.dart';
import 'package:vetheat/screen/wallet_screen.dart';

class Navigation extends StatefulWidget {
  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  final FeedScreen feed = FeedScreen();
  final PageController _pageController = PageController(
    initialPage: 2,
  ); // star page
  bool _canGoBack = false;
  bool _canGoForward = false;
  int _currentNav = 3; // star navigation
  bool get isAtWebView => _currentNav == 1;

  @override
  void initState() {
    super.initState();
    onGoUrl.on((arg) {
      feed.loadUrl(arg);
      if (!isAtWebView) _pageController.jumpToPage(0); // webview page
    });
    onWebChanged.on((arg) async {
      _canGoBack = await feed.canGoBack();
      _canGoForward = await feed.canGoForward();
      !isAtWebView ? _pageController.jumpToPage(0) : setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  BottomNavigationBarItem makeNavBarItem(IconData data, bool activated) {
    return BottomNavigationBarItem(
      icon: Icon(
        data,
        color: activated ? Colors.black : Colors.grey,
      ),
      title: Container(height: 0.0),
      backgroundColor: Colors.white,
    );
  }

  Future onPageChanged(int page) async {
    setState(() {
      _currentNav = page + 1;
    });
  }

  Future navigationTapped(int index) async {
    switch (index) {
      case 0:
        if (isAtWebView) feed.goBack();
        break;
      case 1:
        if (isAtWebView) feed.goForward();
        break;
      case 2:
      case 3:
      case 4:
        _currentNav == index
            ? _pageController.jumpToPage(0)
            : _pageController.jumpToPage(index - 1);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          feed.webView,
          TabScreen(feed: feed),
          StarScreen(),
          WalletScreen(),
        ],
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: onPageChanged,
      ),
      bottomNavigationBar: CupertinoTabBar(
        activeColor: Colors.orange,
        items: <BottomNavigationBarItem>[
          makeNavBarItem(Icons.arrow_back_ios, isAtWebView && _canGoBack),
          makeNavBarItem(Icons.arrow_forward_ios, isAtWebView && _canGoForward),
          makeNavBarItem(Icons.filter_none, _currentNav == 2),
          makeNavBarItem(Icons.star, _currentNav == 3),
          makeNavBarItem(Icons.account_balance_wallet, _currentNav == 4),
        ],
        onTap: navigationTapped,
        currentIndex: _currentNav,
      ),
    );
  }
}
