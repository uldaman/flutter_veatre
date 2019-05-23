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
  final _tabPage = 2;
  int _currentPage = 3; // Icons.star
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _spread = false;

  PageController _pageController;
  void goToWebPage() => _pageController.jumpToPage(0);

  Future navigationTapped(int page) async {
    final bool b1 = _currentPage == _tabPage;
    final bool b2 = _currentPage == page;
    switch (page) {
      case 0:
        if (b1 && webView != null && await webView.canGoBack()) {
          webView.goBack();
        }
        break;
      case 1:
        if (b1 && webView != null && await webView.canGoForward()) {
          webView.goForward();
        }
        break;
      case 2:
        _spread = b1 ? !_spread : true;
        b2 ? _updateNavBar(true, () {}) : goToWebPage();
        break;
      case 3:
      case 4:
        _spread = false;
        b2 ? goToWebPage() : _pageController.jumpToPage(page - 2);
        break;
    }
  }

  Future _updateNavBar(bool isTabPage, VoidCallback fn) async {
    final bool b = isTabPage && webView != null;
    _canGoBack = b ? await webView.canGoBack() : false;
    _canGoForward = b ? await webView.canGoForward() : false;
    setState(fn);
  }

  Future onPageChanged(int page) async {
    await _updateNavBar(page == _tabPage, () {
      _currentPage = page + 2;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1); //  StarScreen
    onWebChanged.on((arg) {
      _updateNavBar(_currentPage == _tabPage, () {});
    });
    onGoUrl.on((arg) {
      if (webView != null) {
        webView.loadUrl(arg);
      } else {
        initialUrl = arg;
      }
      _spread = false;
      goToWebPage();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          TabScreen(spread: _spread),
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
          makeNavBarItem(Icons.arrow_back_ios, _canGoBack),
          makeNavBarItem(Icons.arrow_forward_ios, _canGoForward),
          makeNavBarItem(
            Icons.filter_none,
            _currentPage == 2 && _spread,
          ),
          makeNavBarItem(Icons.star, _currentPage == 3),
          makeNavBarItem(Icons.account_balance_wallet, _currentPage == 4),
        ],
        onTap: navigationTapped,
        currentIndex: _currentPage,
      ),
    );
  }
}
