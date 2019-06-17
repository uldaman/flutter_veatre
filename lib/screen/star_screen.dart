import 'package:flutter/material.dart';
import 'package:veatre/common/event.dart';
import 'package:veatre/common/web_views.dart' as web_view;

class StarScreen extends StatefulWidget {
  @override
  _StarScreenState createState() => _StarScreenState();
}

class _StarScreenState extends State<StarScreen>
    with AutomaticKeepAliveClientMixin {
  final stars = <Map>[
    {
      "title": "Tokens",
      "icon":
          "https://apps.vechain.org/img/com.laalaguer.token-transfer.3be1b8d3.png",
      "url": "https://laalaguer.github.io/vechain-token-transfer/",
    },
    {
      "title": "Vepool",
      "icon": "https://apps.vechain.org/img/come.vepool.vepool.a07e2818.png",
      "url": "https://vepool.xyz/",
    },
    {
      "title": "Insight",
      "icon": "https://apps.vechain.org/img/com.vechain.insight.5b9cf491.png",
      "url": "https://insight.vecha.in/#/",
    },
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Stars'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.0),
        child: GridView.count(
          crossAxisCount: 3,
          children: List.generate(stars.length, (index) {
            return Container(
              margin: EdgeInsets.all(15.0),
              child: Column(
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      onWebChanged.emit();
                      web_view.loadUrl(stars[index]["url"]);
                    },
                    child: Container(
                      width: 55.0,
                      height: 55.0,
                      margin: EdgeInsets.only(bottom: 10.0),
                      child: Image.network(stars[index]["icon"]),
                    ),
                  ),
                  Text(stars[index]["title"]),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
