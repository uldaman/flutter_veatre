import 'dart:async';
import 'dart:typed_data';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/webView.dart';
import 'package:veatre/src/utils/common.dart';

class Snapshot {
  int id;
  String key;
  Future<Uint8List> data;
  Future<String> title;
  String url;
  int timestamp;
  bool isAlive;

  Snapshot({
    this.id,
    this.key,
    this.title,
    this.data,
    this.url,
    this.timestamp,
    this.isAlive = true,
  });
}

class WebViews {
  static Map<String, Snapshot> _mainNetSnapshots = {};
  static List<WebView> mainNetWebViews = [];

  static Map<String, Snapshot> _testNetSnapshots = {};
  static List<WebView> testNetWebViews = [];

  static final maxTabLen = 5;

  static void removeSnapshot(String key, {Network network}) {
    if ((network ?? Globals.network) == Network.MainNet) {
      _mainNetSnapshots.remove(key);
    } else {
      _testNetSnapshots.remove(key);
    }
  }

  static void removeWebview(int id, {Network network}) {
    Globals.updateTabValue(
      TabControllerValue(
        id: id,
        network: network ?? Globals.network,
        stage: TabStage.Removed,
      ),
    );
  }

  static void _createTab(
    List<WebView> webViews,
    Map<String, Snapshot> snapshots,
    String tabKey,
    Network network,
  ) {
    if (webViews.length < maxTabLen) {
      final id = webViews.length;
      WebView webView = new WebView(
        id: id,
        offstage: false,
        network: network,
        initialURL: Globals.initialURL,
        appearance: Globals.appearance,
        tabKey: randomHex(32),
      );
      webViews.add(webView);
      Globals.updateTabValue(
        TabControllerValue(
          id: id,
          network: network,
          stage: TabStage.Created,
          tabKey: tabKey,
        ),
      );
    } else {
      int id;
      int time;
      if (snapshots.isEmpty) {
        id = 0;
        time = 0;
      } else {
        id = snapshots.values.first.id;
        time = snapshots.values.first.timestamp;
      }
      for (var entry in snapshots.entries) {
        Snapshot snapshot = entry.value;
        if (time > snapshot.timestamp) {
          time = snapshot.timestamp;
          id = snapshot.id;
        }
      }
      Globals.updateTabValue(
        TabControllerValue(
          id: id,
          network: network,
          stage: TabStage.Coverred,
          tabKey: tabKey,
        ),
      );
    }
  }

  static void create({Network network}) {
    final tabKey = randomHex(32);
    network = network ?? Globals.network;
    if (network == Network.MainNet) {
      _createTab(mainNetWebViews, _mainNetSnapshots, tabKey, network);
    } else {
      _createTab(testNetWebViews, _testNetSnapshots, tabKey, network);
    }
  }

  static void _setSnapshot(
    Map<String, Snapshot> snapshots,
    String key,
    Snapshot snapshot,
  ) {
    for (var entry in snapshots.entries) {
      Snapshot entrySnapshot = entry.value;
      if (entrySnapshot.id == snapshot.id) {
        snapshots[entrySnapshot.key].isAlive = false;
      }
    }
    snapshots[key] = snapshot;
  }

  static void updateSnapshot(
    int id,
    String key,
    Network network, {
    Future<Uint8List> data,
    Future<String> title,
    String url,
  }) {
    Snapshot snapshot = Snapshot(
      id: id,
      key: key,
      data: data,
      title: title,
      url: url,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isAlive: true,
    );
    if (network == Network.MainNet) {
      _setSnapshot(_mainNetSnapshots, key, snapshot);
    } else {
      _setSnapshot(_testNetSnapshots, key, snapshot);
    }
  }

  static void removeAll({Network network}) {
    if ((network ?? Globals.network) == Network.MainNet) {
      _mainNetSnapshots.clear();
    } else {
      _testNetSnapshots.clear();
    }
    Globals.updateTabValue(
      TabControllerValue(
        id: 0,
        network: network,
        stage: TabStage.RemoveAll,
      ),
    );
  }

  static List<Snapshot> snapshots({Network network}) {
    if ((network ?? Globals.network) == Network.MainNet) {
      return List.from(_mainNetSnapshots.values);
    }
    return List.from(_testNetSnapshots.values);
  }
}
