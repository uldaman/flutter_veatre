import 'dart:core';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/webView.dart';

class Snapshot {
  int id;
  String key;
  String title;
  Uint8List data;
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

  static List<int> _activeMainNetPages = [];
  static List<int> _inactiveMainNetPages = [];

  static List<int> _activeTestNetPages = [];
  static List<int> _inactiveTestNetPages = [];

  static initialWebViews({
    @required Appearance appearance,
  }) {
    for (int id = 0; id < maxTabLen; id++) {
      WebView mainNetWebView = new WebView(
        id: id,
        offstage: id != 0,
        network: Network.MainNet,
        initialURL: Globals.initialURL,
        appearance: appearance,
      );
      if (id != 0) {
        _inactiveMainNetPages.add(id);
      } else {
        _activeMainNetPages.add(id);
      }
      mainNetWebViews.add(mainNetWebView);
      WebView testNetWebView = new WebView(
        id: id,
        offstage: id != 0,
        network: Network.TestNet,
        initialURL: Globals.initialURL,
        appearance: appearance,
      );
      if (id != 0) {
        _inactiveTestNetPages.add(id);
      } else {
        _activeTestNetPages.add(id);
      }
      testNetWebViews.add(testNetWebView);
    }
  }

  static void removeSnapshot(
    Network network,
    String key,
  ) {
    if (network == Network.MainNet) {
      _mainNetSnapshots.remove(key);
    } else {
      _testNetSnapshots.remove(key);
    }
  }

  static void removeWebview(
    Network network,
    int id,
  ) {
    if (network == Network.MainNet) {
      _activeMainNetPages.remove(id);
      _inactiveMainNetPages.add(id);
    } else {
      _activeTestNetPages.remove(id);
      _inactiveTestNetPages.add(id);
    }
    Globals.updateTabValue(
      TabControllerValue(
        id: id,
        network: network,
        stage: TabStage.Removed,
      ),
    );
  }

  static void create(
    Network network,
    String key,
  ) {
    if (network == Network.MainNet) {
      if (_activeMainNetPages.length < maxTabLen) {
        int firstInactiveID = _inactiveMainNetPages.first;
        _activeMainNetPages.add(firstInactiveID);
        _inactiveMainNetPages.remove(firstInactiveID);
        Globals.updateTabValue(
          TabControllerValue(
            id: firstInactiveID,
            network: network,
            stage: TabStage.Created,
            tabKey: key,
          ),
        );
      } else {
        int id = _mainNetSnapshots.values.first.id;
        int time = _mainNetSnapshots.values.first.timestamp;
        for (var entry in _mainNetSnapshots.entries) {
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
            tabKey: key,
          ),
        );
      }
    } else {
      if (_activeTestNetPages.length < maxTabLen) {
        int firstInactiveID = _inactiveTestNetPages.first;
        _activeTestNetPages.add(firstInactiveID);
        _inactiveTestNetPages.remove(firstInactiveID);
        Globals.updateTabValue(
          TabControllerValue(
            id: firstInactiveID,
            network: network,
            stage: TabStage.Created,
            tabKey: key,
          ),
        );
      } else {
        int id = _testNetSnapshots.values.first.id;
        int time = _testNetSnapshots.values.first.timestamp;
        for (var entry in _testNetSnapshots.entries) {
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
            tabKey: key,
          ),
        );
      }
    }
  }

  static void updateSnapshot(
    Network net,
    int id,
    String key, {
    Uint8List data,
    String title,
    String url,
  }) {
    Snapshot _snapshot = Snapshot(
      id: id,
      key: key,
      data: Uint8List.fromList(data),
      title: title,
      url: url,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isAlive: true,
    );
    if (net == Network.MainNet) {
      for (var entry in _mainNetSnapshots.entries) {
        Snapshot snapshot = entry.value;
        if (snapshot.id == id) {
          _mainNetSnapshots[snapshot.key].isAlive = false;
        }
      }
      _mainNetSnapshots[key] = _snapshot;
    } else {
      for (var entry in _testNetSnapshots.entries) {
        Snapshot snapshot = entry.value;
        if (snapshot.id == id) {
          _testNetSnapshots[snapshot.key].isAlive = false;
        }
      }
      _testNetSnapshots[key] = _snapshot;
    }
  }

  static void removeAll(Network network) {
    if (network == Network.MainNet) {
      _mainNetSnapshots.clear();
      _activeMainNetPages.clear();
      _inactiveMainNetPages.clear();
      for (int id = 0; id < maxTabLen; id++) {
        _inactiveMainNetPages.add(id);
      }
    } else {
      _testNetSnapshots.clear();
      _activeTestNetPages.clear();
      _inactiveTestNetPages.clear();
      for (int id = 0; id < maxTabLen; id++) {
        _inactiveTestNetPages.add(id);
      }
    }
    Globals.updateTabValue(
      TabControllerValue(
        id: 0,
        network: network,
        stage: TabStage.RemoveAll,
      ),
    );
  }

  static List<Snapshot> snapshots(Network net) {
    if (net == Network.MainNet) {
      return List.from(_mainNetSnapshots.values);
    }
    return List.from(_testNetSnapshots.values);
  }
}
