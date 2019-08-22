import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/webView.dart';

class Snapshot {
  String title;
  Uint8List data;

  Snapshot({
    this.title,
    this.data,
  });
}

class WebViews {
  static List<Snapshot> _mainNetSnapshots = [];
  static List<WebView> mainNetWebViews = [];

  static List<Snapshot> _testNetSnapshots = [];
  static List<WebView> testNetWebViews = [];

  static newWebView({
    @required Network network,
    @required Appearance appearance,
    String initialURL,
  }) {
    int id = network == Network.MainNet
        ? mainNetWebViews.length
        : testNetWebViews.length;
    LabeledGlobalKey<WebViewState> key = LabeledGlobalKey<WebViewState>(
        network == Network.MainNet ? 'mainNetWebView$id' : 'testNetWebView$id');
    WebView webView = new WebView(
      key: key,
      id: id,
      network: network,
      initialURL: initialURL ?? Globals.initialURL,
      appearance: appearance,
    );
    if (network == Network.MainNet) {
      _mainNetSnapshots.add(Snapshot());
      mainNetWebViews.add(webView);
    } else {
      _testNetSnapshots.add(Snapshot());
      testNetWebViews.add(webView);
    }
    Globals.updateTabValue(
      TabControllerValue(
        id: id,
        network: network,
        stage: TabStage.Created,
      ),
    );
  }

  static void updateSnapshot(
    Network net,
    int id, {
    Uint8List data,
    String title,
  }) {
    if (net == Network.MainNet) {
      _mainNetSnapshots[id] = Snapshot(
        data: data,
        title: title,
      );
    } else {
      _testNetSnapshots[id] = Snapshot(
        data: data,
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

  static void removeTab(Network net, int id) {
    if (net == Network.MainNet) {
      mainNetWebViews.removeAt(id);
      _mainNetSnapshots.removeAt(id);
    } else {
      testNetWebViews.removeAt(id);
      _testNetSnapshots.removeAt(id);
    }
  }

  static void removeAllTabs(Network net) {
    if (net == Network.MainNet) {
      _mainNetSnapshots.clear();
      mainNetWebViews.clear();
    } else {
      _testNetSnapshots.clear();
      testNetWebViews.clear();
    }
  }

  static List<Snapshot> snapshots(Network net) {
    if (net == Network.MainNet) {
      return _mainNetSnapshots;
    }
    return _testNetSnapshots;
  }
}
