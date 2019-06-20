import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:veatre/common/event.dart';
import 'package:veatre/common/search_widget.dart';
import 'package:veatre/src/ui/signCertificateDialog.dart';
import 'package:veatre/src/ui/signTxDialog.dart';
import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/common/driver.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/ui/alert.dart';

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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _progressIndicator(double value) {
    return Padding(
      child: SizedBox(
        height: 2.5,
        child: PhysicalModel(
          child: LinearProgressIndicator(value: value),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(45.0),
          clipBehavior: Clip.hardEdge,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.8),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SearchWidget(),
              (_progress != 1.0) ? _progressIndicator(_progress) : null,
            ].where((Object o) => o != null).toList(),
          ),
          padding: EdgeInsets.only(bottom: 3.0),
        ),
      ),
      body: InAppWebView(
          initialOptions: {"useShouldOverrideUrlLoading": true},
          initialJs: _makeHeadJs(driver.head),
          initialUrl: initialUrl,
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
          onWebViewCreated: (InAppWebViewController controller) async {
            controller.addJavaScriptHandler("debugLog", (arguments) async {
              debugPrint("debugLog: " + arguments.join(","));
            });
            controller.addJavaScriptHandler("errorLog", (arguments) async {
              debugPrint("errorLog: " + arguments.join(","));
            });
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
              List<WalletEntity> walletEntities = await WalletStorage.readAll();
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
                SigningTxResponse result = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return SignTxDialog(
                      txMessages: txMessages,
                      options: options,
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
                SigningCertResponse result = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return SignCertificateDialog(
                      certMessage: certMessage,
                      options: options,
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
          onLoadStart: (InAppWebViewController controller, String url) async {
            onWebChanged.emit();
          },
          onLoadStop: (InAppWebViewController controller, String url) async {
            widget.onLoadStop(controller, url);
          },
          onProgressChanged: (InAppWebViewController controller, int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          shouldOverrideUrlLoading:
              (InAppWebViewController controller, String url) {
            controller.loadUrl(url);
          }),
    );
  }
}
