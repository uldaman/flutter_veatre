import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vetheat/screen/star_screen.dart';
import 'package:vetheat/screen/feed_screen.dart';
import 'package:vetheat/screen/tab_screen.dart';
import 'package:vetheat/screen/wallet_screen.dart';
import 'package:vetheat/common/event_bus.dart';

class Navigation extends StatefulWidget {
  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  final _feedPage = 0;
  int _currentPage = 3; // Icons.star
  bool _canGoBack = false;
  bool _canGoForward = false;
  PageController _pageController;

  Future navigationTapped(int page) async {
    switch (page) {
      case 0:
        if (_currentPage == _feedPage) {
          feeds.goBack();
        }
        break;
      case 1:
        if (_currentPage == _feedPage) {
          feeds.goForward();
        }
        break;
      case 2:
      case 3:
      case 4:
        if (_currentPage == page) {
          _pageController.jumpToPage(_feedPage);
        } else {
          _pageController.jumpToPage(page - 1);
        }
        break;
    }
  }

  Future onPageChanged(int page) async {
    _canGoBack = page == _feedPage ? await feeds.canGoBack() : false;
    _canGoForward = page == _feedPage ? await feeds.canGoForward() : false;
    setState(() {
      switch (page) {
        case 0:
          _currentPage = _feedPage;
          break;
        case 1:
        case 2:
        case 3:
          _currentPage = page + 1;
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2); //  StarScreen
    bus.on("pageChange", (arg) {
      onPageChanged(_feedPage);
    });
    bus.on("goUrl", (arg) {
      feeds.loadUrl(arg);
      _pageController.jumpToPage(_feedPage);
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
          feeds.current,
          TabScreen(),
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
          makeNavBarItem(Icons.filter_none, _currentPage == 2),
          makeNavBarItem(Icons.star, _currentPage == 3),
          makeNavBarItem(Icons.account_balance_wallet, _currentPage == 4),
        ],
        onTap: navigationTapped,
        currentIndex: _currentPage,
      ),
    );
  }
}
