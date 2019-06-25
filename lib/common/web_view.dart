import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:material_search/material_search.dart';
import 'package:veatre/common/dapp_list.dart';
import 'package:veatre/common/event.dart';
import 'package:veatre/src/ui/signCertificateDialog.dart';
import 'package:veatre/src/ui/signTxDialog.dart';
import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/common/driver.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/common/web_views.dart' as web_view;

String initialUrl = "about:blank";

class CustomWebView extends StatefulWidget {
  final onWebViewCreatedCallback onWebViewCreated;
  final onWebViewLoadStopCallback onLoadStop;

  const CustomWebView({
    Key key,
    this.onWebViewCreated,
    this.onLoadStop,
  }) : super(key: key);

  @override
  _CustomWebViewState createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  double _progress = 0;
  Timer _timer;
  Text _title = Text("Search");

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _progressIndicator(double value) {
    return Padding(
      child: SizedBox(
        height: 3.5,
        child: PhysicalModel(
          child: LinearProgressIndicator(value: value),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(45.0),
          clipBehavior: Clip.hardEdge,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 0.8),
    );
  }

  String _makeHeadJs(Map<String, dynamic> head) {
    return '''
      window.block_head={
        id: '${head["id"]}',
        number:${head["number"]},
        timestamp:${head["timestamp"]},
        parentID:'${head["parentID"]}'
      }''';
  }

  MaterialPageRoute<String> _buildMaterialSearchPage(BuildContext context) {
    return MaterialPageRoute<String>(
      settings: RouteSettings(
        name: 'material_search',
        isInitialRoute: false,
      ),
      builder: (BuildContext context) {
        return Material(
          child: MaterialSearch<String>(
            placeholder: 'Search or enter website name',
            results: dapps
                .map((Map<dynamic, dynamic> dapp) =>
                    MaterialSearchResult<String>(
                      icon: Icons.star_border,
                      value: dapp["url"],
                      text: dapp["title"],
                    ))
                .toList(),
            filter: (dynamic value, String criteria) {
              return value
                  .toLowerCase()
                  .trim()
                  .contains(RegExp(r'' + criteria.toLowerCase().trim() + ''));
            },
            onSelect: (dynamic value) => Navigator.of(context).pop(value),
            onSubmit: (String value) => Navigator.of(context).pop(value),
          ),
        );
      },
    );
  }

  void _onSubmitted(String url) {
    if (url != null && url != "") {
      web_view.loadUrl(Uri.encodeFull(_matchUrl(url.trim())));
    }
  }

  String _matchUrl(String str) {
    final RegExp reg = RegExp(
      r"^(http(s)?:\/\/)?[\w\-]+(\.[\w\-]+)+([\w\-.,@?^=%&:\/~+#]*[\w\-@?^=%&\/~+#])?$",
    );
    if (!reg.hasMatch(str)) {
      return "https://cn.bing.com/search?q=$str";
    }
    if (str.startsWith("http")) {
      return str;
    }
    return "http://$str";
  }

  void _openSearchBox() {
    Navigator.of(context).push(_buildMaterialSearchPage(context)).then(
      (dynamic value) {
        _onSubmitted(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: InkWell(
          child: _title,
          onTap: () => _openSearchBox(),
        ),
        leading: IconButton(
          icon: Icon(Icons.search),
          onPressed: () => _openSearchBox(),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => web_view.refresh(),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          (_progress != 1.0) ? _progressIndicator(_progress) : null,
          Expanded(
            child: InAppWebView(
              initialOptions: {"useShouldOverrideUrlLoading": true},
              initialJs: _makeHeadJs(driver.head),
              initialUrl: initialUrl,
              onWebViewCreated: (InAppWebViewController controller) async {
                controller.addJavaScriptHandler("Thor", (arguments) async {
                  debugPrint('Thor arguments $arguments');
                  dynamic data = await driver.callMethod(arguments);
                  debugPrint("Thor response $data");
                  return data;
                });
                controller.addJavaScriptHandler("navigatedInPage",
                    (arguments) async {
                  onWebChanged.emit();
                });
                controller.addJavaScriptHandler("Vendor", (arguments) async {
                  debugPrint('Vendor arguments $arguments');
                  List<WalletEntity> walletEntities =
                      await WalletStorage.readAll();
                  if (walletEntities.length == 0) {
                    return customAlert(
                      context,
                      title: Text('No wallet available'),
                      content: Text('Create a new wallet?'),
                      confirmAction: () async {
                        await Navigator.of(context)
                            .pushNamed(ManageWallets.routeName);
                        Navigator.pop(context);
                      },
                      cancelAction: () async {
                        Navigator.pop(context);
                      },
                    );
                  }
                  if (arguments[0] == 'signTx') {
                    List<SigningTxMessage> txMessages = [];
                    for (Map<String, dynamic> txMsg in arguments[1]) {
                      txMessages.add(SigningTxMessage.fromJSON(txMsg));
                    }
                    SigningTxOptions options =
                        SigningTxOptions.fromJSON(arguments[2]);
                    SigningTxResponse result = await showGeneralDialog(
                      context: context,
                      barrierDismissible: false,
                      transitionDuration: Duration(milliseconds: 300),
                      pageBuilder: (context, a, b) {
                        return SlideTransition(
                          position: Tween(begin: Offset(0, 1), end: Offset.zero)
                              .animate(a),
                          child: SignTxDialog(
                            txMessages: txMessages,
                            options: options,
                          ),
                        );
                      },
                    );
                    if (result == null) {
                      throw ArgumentError('user cancelled');
                    }
                    return result.encoded;
                  } else if (arguments[0] == 'signCert') {
                    SigningCertMessage certMessage =
                        SigningCertMessage.fromJSON(arguments[1]);
                    SigningCertOptions options =
                        SigningCertOptions.fromJSON(arguments[2]);
                    SigningCertResponse result = await showGeneralDialog(
                      context: context,
                      barrierDismissible: false,
                      transitionDuration: Duration(milliseconds: 300),
                      pageBuilder: (context, a, b) {
                        return SlideTransition(
                          position: Tween(begin: Offset(0, 1), end: Offset.zero)
                              .animate(a),
                          child: SignCertificateDialog(
                            certMessage: certMessage,
                            options: options,
                          ),
                        );
                      },
                    );
                    if (result == null) {
                      throw ArgumentError('user cancelled');
                    }
                    return result.encoded;
                  }
                  throw ArgumentError('unsupported methor');
                });
                _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
                  driver.syncHead().then((head) {
                    controller.injectScriptCode(_makeHeadJs(head));
                  });
                });
                widget.onWebViewCreated(controller);
              },
              onLoadStart:
                  (InAppWebViewController controller, String url) async {
                onWebChanged.emit();
              },
              onLoadStop:
                  (InAppWebViewController controller, String url) async {
                setState(() {
                  _title = Text(url);
                  _progress = 1;
                });
                widget.onLoadStop(controller, url);
              },
              onProgressChanged:
                  (InAppWebViewController controller, int progress) {
                setState(() => _progress = progress / 100);
              },
              onConsoleMessage: (InAppWebViewController controller,
                  ConsoleMessage consoleMessage) {
                String str = """
                  console output:
                    sourceURL: ${consoleMessage.sourceURL}
                    lineNumber: ${consoleMessage.lineNumber}
                    message: ${consoleMessage.message}
                    messageLevel: ${consoleMessage.messageLevel}""";
                debugPrint(str);
              },
              shouldOverrideUrlLoading:
                  (InAppWebViewController controller, String url) {
                controller.loadUrl(url);
              },
            ),
          ),
        ].where((Object o) => o != null).toList(),
      ),
    );
  }
}
