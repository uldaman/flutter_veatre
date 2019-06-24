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

  MapEntry<int, InkWell> _buildThumb(int index, String title) {
    return MapEntry(
      index,
      InkWell(
        onTap: () {
          onWebViewSelected.emit(index);
        },
        child: Container(
          margin: EdgeInsets.all(20.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.grey,
          ),
          child: Text(
            title == "" ? "空" : title[0].toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 55.0),
          ),
        ),
      ),
    );
  }

  InkWell _buildAdd() {
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
    List<Widget> thumbs = web_view.titleMap.map(_buildThumb).values.toList();
    thumbs.add(_buildAdd());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Tabs'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(25.0),
        child: GridView.count(
          crossAxisCount: 2,
          children: thumbs,
        ),
      ),
    );
  }
}
