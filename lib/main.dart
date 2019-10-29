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
import 'package:veatre/src/storage/database.dart';
import 'package:veatre/src/ui/mainUI.dart';
import 'package:veatre/src/ui/apperance.dart';
import 'package:veatre/src/ui/passwordGeneration.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/network.dart';
import 'package:veatre/src/ui/unlock.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await init();
    String passwordHash = await Config.passwordHash;
    runApp(App(
      hasPasscodes: passwordHash != null,
    ));
  }, onError: (dynamic err, StackTrace stack) {
    print("unhandled error: $err");
    print("stack: $stack");
  });
}

Future<void> init() async {
  await Storage.open();
  Globals.connexJS = await rootBundle.loadString("assets/connex.js");
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
  Globals.updateAppearance(await Config.appearance);
  Globals.updateNetwork(await Config.network);
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

  @override
  void initState() {
    super.initState();
    Globals.addAppearanceHandler(_handleAppearanceChanged);
    Globals.periodic(
      10,
      (timer) async {
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
      },
    );
  }

  void _handleAppearanceChanged() {
    setState(() {
      _appearance = Globals.appearance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        MainUI.routeName: (context) => mainUI,
        ManageWallets.routeName: (context) => manageWallets,
        Settings.routeName: (context) => new Settings(),
        Networks.routeName: (context) => new Networks(),
        Appearances.routeName: (context) => new Appearances(),
      },
      theme: _appearance == Appearance.light ? lightTheme : darkTheme,
      home: !widget.hasPasscodes
          ? PasswordGeneration()
          : Unlock(
              everLaunched: false,
            ),
    );
  }

  MainUI get mainUI => MainUI();
  ManageWallets get manageWallets => ManageWallets();

  ThemeData get lightTheme => ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.white,
        accentColor: Colors.blue,
        brightness: Brightness.light,
        primaryIconTheme: IconThemeData(color: Colors.black),
        iconTheme: IconThemeData(color: Colors.black),
        accentTextTheme: TextTheme(
          title: TextStyle(color: Colors.grey[500], fontFamily: "Aveny"),
        ),
        primaryTextTheme: TextTheme(
          title: TextStyle(
            color: Colors.black,
            fontFamily: "Aveny",
            fontSize: 17,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        textTheme: TextTheme(
          title: TextStyle(color: Colors.black),
          display1: TextStyle(color: Colors.grey[500]),
          body1: TextStyle(color: Colors.black),
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
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
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
