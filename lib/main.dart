import 'package:flutter/material.dart';
import 'package:veatre/navigation.dart';
// import 'package:flutter/rendering.dart';
import 'package:veatre/common/vechain.dart';

void main() {
  // debugPaintSizeEnabled = true;
  // Vechain().getBlockByHash("hash");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VEATRE',
      theme: new ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.black,
          primaryIconTheme: IconThemeData(color: Colors.black),
          primaryTextTheme: TextTheme(
              title: TextStyle(color: Colors.black, fontFamily: "Aveny")),
          textTheme: TextTheme(title: TextStyle(color: Colors.black))),
      home: Navigation(),
    );
  }
}
