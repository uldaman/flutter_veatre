import 'package:flutter/material.dart';
import 'package:vetheat/screen/feed_screen.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

class TabScreen extends StatefulWidget {
  final bool spread;

  const TabScreen({Key key, this.spread = false}) : super(key: key);

  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen>
    with AutomaticKeepAliveClientMixin {
  List<Widget> _feeds = <Widget>[FeedScreen(), Icon(Icons.add_circle)];
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  void onPageChanged(int page) {
    setState(() {
      _currentPage = page;
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
        shadowColor: (page is Icon || !widget.spread)
            ? Colors.transparent
            : Colors.black87,
      ),
    );
  }
}
