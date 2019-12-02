import 'dart:async';
import 'dart:core';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/api/BlockAPI.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/ui/authentication/decision.dart';
import 'package:veatre/src/ui/welcome.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await init();
    runApp(App(
      hasPasscodes: await Config.masterPassHash != null,
    ));
  }, onError: (dynamic err, StackTrace stack) {
    print("unhandled error: $err");
    print("stack: $stack");
  });
}

Future<void> init() async {
  await Storage.open();
  Globals.connexJS = await rootBundle.loadString("assets/connex.js");
  Globals.updateAppearance(await Config.appearance);
  Globals.updateNetwork(await Config.network);
  Globals.setHead(
    BlockHeadForNetwork(
      head: BlockHead.fromJSON(Globals.mainNetGenesis.encoded),
      network: Network.MainNet,
    ),
  );
  Globals.setHead(
    BlockHeadForNetwork(
      head: BlockHead.fromJSON(Globals.testNetGenesis.encoded),
      network: Network.TestNet,
    ),
  );
}

class App extends StatefulWidget {
  final bool hasPasscodes;
  App({@required this.hasPasscodes});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  Timer _timer;
  Appearance _appearance = Globals.appearance;
  Network _network = Globals.network;

  @override
  void initState() {
    super.initState();
    Globals.addAppearanceHandler(_handleAppearanceChanged);
    Globals.addNetworkHandler(_hanleNetworkChanged);
    Globals.periodic(10, _syncBlock);
  }

  Future<void> _syncBlock(Timer timer) async {
    try {
      final network = Globals.network;
      final block = await BlockAPI.best();
      final newHead = BlockHead.fromJSON(block.encoded);
      final head = Globals.head();
      if (head.id != newHead.id && newHead.number > head.number) {
        BlockHeadForNetwork blockHeadForNetwork = BlockHeadForNetwork(
          head: newHead,
          network: network,
        );
        await ActivityStorage.sync(blockHeadForNetwork);
        Globals.updateBlockHead(blockHeadForNetwork);
      }
    } catch (e) {
      print('sync head error: $e');
    }
  }

  void _handleAppearanceChanged() {
    setState(() {
      _appearance = Globals.appearance;
    });
  }

  void _hanleNetworkChanged() {
    setState(() {
      _network = Globals.network;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return _network == Network.MainNet
            ? child
            : Banner(
                child: child,
                color: Theme.of(context).primaryColor,
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).accentColor,
                ),
                message: 'TEST',
                textDirection: TextDirection.ltr,
                location: BannerLocation.topStart,
              );
      },
      theme: _appearance == Appearance.light ? lightTheme : darkTheme,
      home: !widget.hasPasscodes ? Welcome() : Decision(),
    );
  }

  ThemeData get lightTheme => ThemeData(
        appBarTheme: AppBarTheme(
          color: Color(0xFFF8F8F8),
          iconTheme: IconThemeData(color: Color(0xFF666666)),
          brightness: Brightness.light,
        ),
        primaryColor: MaterialColor(0xFF410FE6, {0: Color(0xFF410FE6)}), //主色调
        accentColor: Colors.white,
        backgroundColor: Color(0xFFF8F8F8), //背景色
        brightness: Brightness.light,
        primaryIconTheme: IconThemeData(color: Color(0xFF410FE6)),
        iconTheme: IconThemeData(color: Color(0xFF666666)),
        primaryColorBrightness: Brightness.light,
        primaryTextTheme: TextTheme(
          title: TextStyle(
            color: Color(0xFF333333),
            fontFamily: "Aveny",
            fontSize: 17,
          ),
          subtitle: TextStyle(
            color: Color(0xFF666666),
            fontFamily: "Aveny",
            fontSize: 17,
          ),
          //大标题
          display1: TextStyle(
            color: Color(0xFF333333),
            fontFamily: "Aveny",
            fontSize: 28,
          ),
          //描述性文字
          display2: TextStyle(
            color: Color(0xFF999999),
            fontFamily: "Aveny",
            fontSize: 17,
          ),
          //辅助文字
          display3: TextStyle(
            color: Color(0xFFCCCCCC),
            fontFamily: "Aveny",
            fontSize: 17,
          ),
          button: TextStyle(
            fontFamily: "Aveny",
            fontSize: 17,
          ),
        ), //主文字//副标题
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFEF6F6F), width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFEF6F6F), width: 1.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[500], width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF410FE6), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF410FE6), width: 1.0),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF410FE6), width: 1.0),
          ),
          hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
        ),
        dividerColor: Color(0xFFCCCCCC),
        buttonColor: Colors.blueGrey,
        errorColor: Color(0xFFEF6F6F),
      );

  ThemeData get darkTheme => ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.black,
        accentColor: Colors.blue,
        brightness: Brightness.dark,
        primaryIconTheme: IconThemeData(color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
        accentTextTheme: TextTheme(
          title: TextStyle(color: Colors.grey[500], fontFamily: "Aveny"),
        ),
        primaryTextTheme: TextTheme(
          title: TextStyle(
            color: Colors.white,
            fontFamily: "Aveny",
            fontSize: 17,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            side: BorderSide(color: Colors.grey[800], width: 1),
          ),
        ),
        textTheme: TextTheme(
          title: TextStyle(color: Colors.white),
          display1: TextStyle(color: Colors.grey[500]),
          body1: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[500], width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[500], width: 1.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[500], width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 1.0),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 1.0),
          ),
          hintStyle: TextStyle(color: Colors.white),
        ),
      );

  @override
  void dispose() {
    Globals.destroy();
    _timer.cancel();
    super.dispose();
  }
}
