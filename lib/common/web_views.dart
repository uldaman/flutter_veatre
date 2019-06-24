library web_view;

import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:veatre/common/web_view.dart';

int index = 0;
Map<int, InAppWebViewController> _ctrlMap = {};
List<CustomWebView> views = <CustomWebView>[];
Map<int, String> titleMap = {};

int createWebView() {
  int index = views.length;
  CustomWebView wv = CustomWebView(
    key: Key(index.toString()),
    onWebViewCreated: (InAppWebViewController controller) {
      _ctrlMap[index] = controller;
      initialUrl = "about:blank";
    },
    onLoadStop: (InAppWebViewController controller, String url) {
      controller.getTitle().then((title) => titleMap[index] = title);
    },
  );
  views.add(wv);
  return index;
}

Future<bool> canGoBack() async {
  return _ctrlMap[index] != null ? await _ctrlMap[index].canGoBack() : false;
}

Future<bool> canGoForward() async {
  return _ctrlMap[index] != null ? await _ctrlMap[index].canGoForward() : false;
}

void goBack() {
  if (_ctrlMap[index] != null) _ctrlMap[index].goBack();
}

void goForward() {
  if (_ctrlMap[index] != null) _ctrlMap[index].goForward();
}

void loadUrl(String url) {
  if (_ctrlMap[index] != null) _ctrlMap[index].loadUrl(url);
}

void refresh() {
  if (_ctrlMap[index] != null) _ctrlMap[index].reload();
}
