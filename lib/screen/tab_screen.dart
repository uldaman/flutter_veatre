import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:veatre/common/event.dart';
import 'package:veatre/common/web_views.dart' as web_view;

class TabScreen extends StatefulWidget {
  const TabScreen({Key key}) : super(key: key);

  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final PageController _ctrl = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(
      () {
        int next = _ctrl.page.round();
        if (_currentPage != next) {
          setState(() {
            _currentPage = next;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  InkWell _buildScreenshotCard(int index, bool active) {
    // Animated Properties
    final double blur = active ? 30 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 100 : 200;

    return InkWell(
      onTap: () {
        onWebViewSelected.emit(index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutQuint,
        margin: EdgeInsets.only(top: top, bottom: 50, right: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            fit: BoxFit.cover,
            image: MemoryImage(web_view.screenshotMap[index]),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black87,
              blurRadius: blur,
              offset: Offset(offset, offset),
            ),
          ],
        ),
      ),
    );
  }

  InkWell _buildAddCard() {
    return InkWell(
      onTap: () {
        int index = web_view.createWebView();
        onWebViewSelected.emit(index);
      },
      child: Container(
        margin: EdgeInsets.all(20.0),
        alignment: Alignment.center,
        child: Icon(Icons.add_circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Tabs'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: web_view.screenshotMap.length + 1,
        itemBuilder: (BuildContext context, int currentIdx) {
          if (currentIdx == web_view.screenshotMap.length) {
            return _buildAddCard();
          }
          return _buildScreenshotCard(currentIdx, currentIdx == _currentPage);
        },
      ),
    );
  }
}
