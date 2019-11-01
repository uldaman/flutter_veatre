import 'package:flutter/material.dart';

class Summary extends StatelessWidget {
  Summary({
    Key key,
    @required this.title,
    @required this.content,
  }) : super(key: key);

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Card(
            child: Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: Text(content,
                          style: TextStyle(
                            fontSize: 17,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .display1
                                .color,
                          )))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
