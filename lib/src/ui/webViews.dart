import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:veatre/main.dart';
import 'package:veatre/src/ui/webView.dart';

class Snapshot {
  String title;
  Uint8List data;

  Snapshot({
    this.title,
    this.data,
  });
}

List<Key> _keys = [];
List<Snapshot> _snapshots = [];
List<WebView> webViews = [];

void createWebView(onWebViewChangedCallback onWebViewChanged) {
  int id = webViews.length;
  LabeledGlobalKey<WebViewState> key =
      LabeledGlobalKey<WebViewState>('webview$id');
  WebView webView = new WebView(
    key: key,
    headValueController: headValueController,
    walletsChangedController: walletsChangedController,
    genesisChangedController: genesisChangedController,
    onWebViewChanged: (controller) async {
      onWebViewChanged(controller);
    },
  );
  _keys.add(key);
  _snapshots.add(Snapshot());
  webViews.add(webView);
}

void updateSnapshot(
  int index, {
  Uint8List data,
  String title,
}) {
  _snapshots[index] = Snapshot(
    data: data,
    title: title,
  );
}

int get tabshotLen => _snapshots.length;

void removeTab(int id) {
  _keys.removeAt(id);
  _snapshots.removeAt(id);
  webViews.removeAt(id);
}

void removeAllTabs() {
  _snapshots.clear();
  webViews.clear();
  _keys.clear();
}

InAppWebViewController _controllerAt(int id) {
  final key = _keyAt(id);
  if (key != null && key.currentState != null) {
    return key.currentState.controller;
  }
  return null;
}

LabeledGlobalKey<WebViewState> _keyAt(int id) {
  return _keys[id];
}

List<Snapshot> get tabShots {
  return _snapshots;
}

Future<String> getTitle(int id) async {
  final controller = _controllerAt(id);
  if (controller != null) {
    return controller.getTitle();
  }
  return null;
}

Future<bool> canGoBack(int id) async {
  final controller = _controllerAt(id);
  if (controller != null) {
    return controller.canGoBack();
  }
  return false;
}

Future<bool> canGoForward(int id) async {
  final controller = _controllerAt(id);
  if (controller != null) {
    return controller.canGoForward();
  }
  return false;
}

Future<void> goBack(int id) async {
  final controller = _controllerAt(id);
  if (controller != null) {
    return controller.goBack();
  }
}

Future<void> goForward(int id) async {
  final controller = _controllerAt(id);
  if (controller != null) {
    return controller.goForward();
  }
}

Future<void> reload(int id) async {
  try {
    final controller = _controllerAt(id);
    if (controller != null) {
      return controller.reload();
    }
  } catch (err) {
    throw err;
  }
}

Future<void> loadUrl(int id, String url) async {
  try {
    final controller = _controllerAt(id);
    if (controller != null) {
      return controller.loadUrl(url);
    }
  } catch (err) {
    throw err;
  }
}

Future<Uint8List> takeScreenshot(int id) async {
  final key = _keyAt(id);
  if (key.currentState.isStartSearch ||
      key.currentState.currentURL == 'about:blank') {
    try {
      RenderRepaintBoundary boundary =
          key.currentState.captureKey.currentContext.findRenderObject();
      var image = await boundary.toImage(pixelRatio: 1.0);
      ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List bytes = byteData.buffer.asUint8List();
      return bytes;
    } catch (e) {
      print("takeScreenshot error: $e");
      return null;
    }
  } else if (key.currentState.controller != null) {
    return key.currentState.controller.takeScreenshot();
  }
  return null;
}
