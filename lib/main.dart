import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veatre/src/api/BlockAPI.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/apperance.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/importWallet.dart';
import 'package:veatre/src/ui/mainUI.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/network.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/common/globals.dart';

void main() {
  runZoned(() async {
    await initialGlobals();
    runApp(App());
  }, onError: (dynamic err, StackTrace stack) {
    print("unhandled error: $err");
    print("stack: $stack");
  });
}

Future<void> initialGlobals() async {
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
  Globals.updateAppearance(await AppearanceStorage.appearance);
  Globals.updateNetwork(await NetworkStorage.network);
}

class App extends StatefulWidget {
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
    Globals.periodic(10, (timer) async {
      try {
        final network = await NetworkStorage.network;
        final block = await BlockAPI.best(network);
        final newHead = BlockHead.fromJSON(block.encoded);
        final head = Globals.head(network);
        if (head.id != newHead.id && newHead.number > head.number) {
          final blockHeadForNetwork = BlockHeadForNetwork(
            head: newHead,
            network: network,
          );
          Globals.updateBlockHead(blockHeadForNetwork);
          await _syncActivities(blockHeadForNetwork);
        }
      } catch (e) {
        print('sync head error: $e');
      }
    });
  }

  void _handleAppearanceChanged() {
    setState(() {
      _appearance = Globals.appearance;
    });
  }

  Future<void> _syncActivities(BlockHeadForNetwork blockHeadForNetwork) async {
    int headNumber = blockHeadForNetwork.head.number;
    List<Activity> activities =
        await ActivityStorage.queryPendings(blockHeadForNetwork.network);
    for (Activity activity in activities) {
      String txID = activity.hash;
      final net = Globals.net(blockHeadForNetwork.network);
      Map<String, dynamic> receipt = await net.getReceipt(txID);
      if (receipt != null) {
        int processBlock = receipt['meta']['blockNumber'];
        if (activity.processBlock == null) {
          await ActivityStorage.update(
              activity.id, {'processBlock': processBlock});
        }
        bool reverted = receipt['reverted'];
        if (reverted) {
          await ActivityStorage.update(
              activity.id, {'status': ActivityStatus.Reverted.index});
        } else if (headNumber - processBlock >= 12) {
          await ActivityStorage.update(
              activity.id, {'status': ActivityStatus.Finished.index});
        }
      } else if (headNumber - activity.block >= 30) {
        await ActivityStorage.update(
            activity.id, {'status': ActivityStatus.Expired.index});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        MainUI.routeName: (context) => new MainUI(),
        Settings.routeName: (context) => new Settings(),
        ManageWallets.routeName: (context) => new ManageWallets(),
        Networks.routeName: (context) => new Networks(),
        Appearances.routeName: (context) => new Appearances(),
        CreateWallet.routeName: (context) => new CreateWallet(),
        ImportWallet.routeName: (context) => new ImportWallet(),
      },
      theme: _appearance == Appearance.light ? lightTheme : darkTheme,
    );
  }

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
          title: TextStyle(color: Colors.black, fontFamily: "Aveny"),
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
          title: TextStyle(color: Colors.white, fontFamily: "Aveny"),
        ),
        cardTheme: CardTheme(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
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
