import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:webview_flutter/webview_flutter.dart' as FlutterWebView;
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

  static void createWebView(Network network, Appearance appearance,
      onWebViewChangedCallback onWebViewChanged) {
    int id = network == Network.MainNet
        ? mainNetWebViews.length
        : testNetWebViews.length;
    LabeledGlobalKey<WebViewState> key = LabeledGlobalKey<WebViewState>(
        network == Network.MainNet ? 'mainNetWebView$id' : 'testNetWebView$id');
    WebView webView = new WebView(
      key: key,
      id: id,
      network: network,
      appearance: appearance,
      onWebViewChanged: (controller, network, id, url) async {
        onWebViewChanged(controller, network, id, url);
      },
    );
    if (network == Network.MainNet) {
      _mainNetSnapshots.add(Snapshot());
      mainNetWebViews.add(webView);
    } else {
      _testNetSnapshots.add(Snapshot());
      testNetWebViews.add(webView);
    }
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

  static FlutterWebView.WebViewController _controllerAt(Network net, int id) {
    final key = WebViews._keyAt(net, id);
    if (key != null && key.currentState != null) {
      return key.currentState.controller;
    }
    return null;
  }

  static LabeledGlobalKey<WebViewState> _keyAt(Network net, int id) {
    if (net == Network.MainNet) {
      return mainNetWebViews[id].key;
    }
    return testNetWebViews[id].key;
  }

  static List<Snapshot> snapshots(Network net) {
    if (net == Network.MainNet) {
      return _mainNetSnapshots;
    }
    return _testNetSnapshots;
  }

  static Future<String> getTitle(Network net, int id) async {
    final controller = _controllerAt(net, id);
    if (controller != null) {
      return controller.currentTitle();
    }
    return null;
  }

  static Future<DocumentMetaData> getMetaData(Network net, int id) async {
    final controller = _controllerAt(net, id);
    if (controller != null) {
      final result =
          await controller.evaluateJavascript("window.__getMetaData__();");
      return DocumentMetaData.fromJSON(json.decode(result));
    }
    return null;
  }

  static Future<String> getURL(Network net, int id) async {
    final key = _keyAt(net, id);
    if (key != null && key.currentState != null) {
      return key.currentState.currentURL;
    }
    return null;
  }

  static Future<bool> canGoBack(Network net, int id) async {
    final controller = _controllerAt(net, id);
    if (controller != null) {
      return controller.canGoBack();
    }
    return false;
  }

  static Future<bool> canGoForward(Network net, int id) async {
    final controller = _controllerAt(net, id);
    if (controller != null) {
      return controller.canGoForward();
    }
    return false;
  }

  static Future<void> goBack(Network net, int id) async {
    final controller = _controllerAt(net, id);
    if (controller != null) {
      return controller.goBack();
    }
  }

  static Future<void> goForward(Network net, int id) async {
    final controller = _controllerAt(net, id);
    if (controller != null) {
      return controller.goForward();
    }
  }

  static Future<void> reload(Network net, int id) async {
    try {
      final controller = _controllerAt(net, id);
      if (controller != null) {
        return controller.reload();
      }
    } catch (err) {
      throw err;
    }
  }

  static Future<void> loadUrl(Network net, int id, String url) async {
    try {
      final controller = _controllerAt(net, id);
      if (controller != null) {
        return controller.loadUrl(url);
      }
    } catch (err) {
      throw err;
    }
  }

  static Future<Uint8List> takeScreenshot(Network net, int id) async {
    final key = _keyAt(net, id);
    if (key.currentState == null ||
        key.currentState.isStartSearch ||
        key.currentState.currentURL == Globals.initialURL) {
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
}
