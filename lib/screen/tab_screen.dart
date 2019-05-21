import 'package:flutter/material.dart';
import 'package:vetheat/screen/feed_screen.dart';

class TabScreen extends StatefulWidget {
  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final int feedNums = feeds.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Tabs'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: feedNums + 1,
        itemBuilder: (context, int currentIdx) {
          if (currentIdx == feedNums) {
            return _buildPage(currentIdx, true);
          } else if (currentIdx < feedNums) {
            return _buildPage(currentIdx);
          }
        },
      ),
    );
  }

  Widget _buildPage(int index, [bool isAdd = false]) {
    final bool active = index == _currentPage;
    final double top = active ? 100 : 200;
    final double elevation = active ? 2.0 : 1.0;
    final Color shadowColor = active ? Colors.black87 : Colors.transparent;
    final Widget page = isAdd ? Icon(Icons.add_circle) : feeds[index];
    final Color color = isAdd ? Colors.grey[300] : Colors.transparent;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(top: top, bottom: 50, right: 30),
      child: PhysicalModel(
        elevation: elevation,
        child: page,
        color: color,
        // borderRadius: BorderRadius.circular(35.0),
        // https://github.com/OpenFlutter/amap_base_flutter/issues/58
        clipBehavior: Clip.hardEdge,
        shadowColor: shadowColor,
      ),
    );
  }
}
