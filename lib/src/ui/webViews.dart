import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/webView.dart';

class Snapshot {
  int id;
  String title;
  Uint8List data;

  Snapshot({
    this.id,
    this.title,
    this.data,
  });
}

class WebViews {
  static Map<int, Snapshot> _mainNetSnapshots = {};
  static List<WebView> mainNetWebViews = [];

  static Map<int, Snapshot> _testNetSnapshots = {};
  static List<WebView> testNetWebViews = [];

  static final maxTabLen = 10;
  static List<int> _activeMainNetPages = [];
  static List<int> _inactiveMainNetPages = [];

  static List<int> _activeTestNetPages = [];
  static List<int> _inactiveTestNetPages = [];

  static initialWebViews({
    @required Appearance appearance,
  }) {
    for (int id = 0; id < maxTabLen; id++) {
      GlobalObjectKey<WebViewState> mainNetkey =
          GlobalObjectKey<WebViewState>('mainNetWebView$id');
      WebView mainNetWebView = new WebView(
        key: mainNetkey,
        id: id,
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
      GlobalObjectKey<WebViewState> testNetkey =
          GlobalObjectKey<WebViewState>('testNetWebView$id');
      WebView testNetWebView = new WebView(
        key: testNetkey,
        id: id,
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

  static void remove(
    Network network,
    int id,
  ) {
    if (network == Network.MainNet) {
      _activeMainNetPages.remove(id);
      _inactiveMainNetPages.add(id);
      _mainNetSnapshots.remove(id);
    } else {
      _activeTestNetPages.remove(id);
      _inactiveTestNetPages.add(id);
      _testNetSnapshots.remove(id);
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
          ),
        );
      }
    }
  }

  static bool canCreateMore(Network network) {
    if (network == Network.MainNet) {
      return _activeMainNetPages.length < maxTabLen;
    } else {
      return _activeTestNetPages.length < maxTabLen;
    }
  }

  static void newSnapshot(
    Network net,
    int id, {
    Uint8List data,
    String title,
  }) {
    if (net == Network.MainNet) {
      _mainNetSnapshots[id] = Snapshot(
        id: id,
        data: Uint8List.fromList(data),
        title: title,
      );
    } else {
      _testNetSnapshots[id] = Snapshot(
        id: id,
        data: Uint8List.fromList(data),
        title: title,
      );
    }
  }

  static int tabshotLen(Network net) {
    if (net == Network.MainNet) {
      return _mainNetSnapshots.length;
    }
    return _testNetSnapshots.length;
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
