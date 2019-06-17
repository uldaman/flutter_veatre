import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:veatre/common/event.dart';
import 'package:veatre/common/event_bus.dart';
import 'package:veatre/common/search_widget.dart';
import 'package:veatre/common/signTxDialog.dart';
import 'package:veatre/common/signCertificateDialog.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/storage/storage.dart';

import 'package:veatre/common/net.dart';
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
        onWebViewCreated: (InAppWebViewController controller) {
          Net net = Net();
          Driver driver = Driver(net);
          controller.addJavaScriptHandler("debugLog", (arguments) async {
            debugPrint("debugLog: " + arguments.join(","));
          });
          // controller.addJavaScriptHandler("webChanged", (arguments) async {
          //   bus.emit("webChanged");
          //   print("webChanged");
          //   List<WalletEntity> walletEntities = await WalletStorage.readAll();
          //   if (walletEntities.length == 0) {
          //     await customAlert(
          //       context,
          //       title: Text('No wallet available'),
          //       content: Text('Create a new wallet?'),
          //       confirmAction: () async {
          //         await Navigator.of(context)
          //             .pushNamed(ManageWallets.routeName);
          //         Navigator.pop(context);
          //       },
          //       cancelAction: () async {
          //         Navigator.pop(context);
          //       },
          //     );
          //   } else {
          //     dynamic clauses = [
          //       {
          //         'to': '0x87bBd37455ef0B2A04e63Ae49c5Ca5ec55371986',
          //         'value': '100000000000000000000',
          //         'data': '0x',
          //         'comment': 'Transfer 100 VET'
          //       },
          //       {
          //         'to': '0xf2c109c9b3A24583Fb8D71832194580Bf33e26fa',
          //         'value': '100000000000000000000',
          //         'data': '0x',
          //         'comment': 'Transfer 100 VET'
          //       },
          //     ];
          //     List<RawClause> rawClauses = [];
          //     for (Map<String, dynamic> clause in clauses) {
          //       rawClauses.add(RawClause.fromJSON(clause));
          //     }
          //     var res = await showDialog(
          //       context: context,
          //       barrierDismissible: false,
          //       builder: (context) {
          //         return SignCertificateDialog();
          //         // return SignTxDialog(rawClauses: rawClauses);
          //       },
          //     );

          //     print("res $res");
          //   }
          // });
          controller.addJavaScriptHandler("Thor", (arguments) async {
            print('Thor arguments $arguments');
            return driver.callMethod(arguments);
          });
          controller.addJavaScriptHandler("Vendor", (arguments) async {
            print('Vendor arguments $arguments');
            return driver.callMethod(arguments);
          });
          onBlockChainChanged.on((status) {
            controller.injectScriptCode('window.block_chain_status=$status');
          });
          widget.onWebViewCreated(controller);
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
