import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
        initialUrl: initialUrl,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
          new Factory<OneSequenceGestureRecognizer>(
            () => new EagerGestureRecognizer(),
          ),
        ].toSet(),
        onWebViewCreated: (InAppWebViewController controller) {
          controller.addJavaScriptHandler("debugLog", (arguments) async {
            debugPrint("debugLog: " + arguments.join(","));
          });
          controller.addJavaScriptHandler("errorLog", (arguments) async {
            debugPrint("errorLog: " + arguments.join(","));
          });
          controller.addJavaScriptHandler("Thor", (arguments) async {
            print('Thor arguments $arguments');
            dynamic data = await driver.callMethod(arguments);
            print("Thor response $data");
            return data;
          });
          controller.addJavaScriptHandler("navigatedInPage", (arguments) async {
            onWebChanged.emit();
          });
          controller.addJavaScriptHandler("Vendor", (arguments) async {
            print('Vendor arguments $arguments');
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
          onBlockChainChanged.on((head) {
            controller.injectScriptCode('window.block_head=$head');
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
      ),
    );
  }
}
