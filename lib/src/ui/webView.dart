import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:veatre/common/driver.dart';
import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/ui/signCertificateDialog.dart';
import 'package:veatre/src/ui/signTxDialog.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/searchBar.dart';
import 'package:veatre/src/ui/apps.dart';
import 'package:veatre/src/storage/walletStorage.dart';

typedef onWebViewChangedCallback = void Function(
    InAppWebViewController controller);

class HeadController extends ValueNotifier<Block> {
  HeadController(Block value) : super(value);
}

class WalletsController extends ValueNotifier<List<String>> {
  WalletsController(List<String> value) : super(value);
}

class WebView extends StatefulWidget {
  final Key key;
  final Block genesis;
  final Driver driver;
  final HeadController headController;
  final WalletsController walletsController;
  final onWebViewChangedCallback onWebViewChanged;

  WebView({
    this.key,
    this.genesis,
    this.driver,
    this.headController,
    this.walletsController,
    this.onWebViewChanged,
  }) : super(key: key);

  @override
  WebViewState createState() => WebViewState();
}

class WebViewState extends State<WebView> with AutomaticKeepAliveClientMixin {
  String currentURL = 'about:blank';
  bool isStartSearch = false;

  SearchBarController searchBarController = SearchBarController(
    SearchBarValue(
      shouldHidRefresh: true,
      icon: Icons.search,
    ),
  );
  final GlobalKey captureKey = GlobalKey();
  InAppWebViewController controller;

  @override
  void initState() {
    super.initState();
    widget.headController.addListener(_handleHeadChanged);
    widget.walletsController.addListener(_handleWalletsChanged);
  }

  void _handleHeadChanged() {
    if (controller != null) {
      controller.injectScriptCode(_headJS(widget.headController.value));
    }
  }

  void _handleWalletsChanged() {
    if (controller != null) {
      controller.injectScriptCode(_walletsJS(widget.walletsController.value));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        title: searchBar,
      ),
      body: RepaintBoundary(
        key: captureKey,
        child: Stack(
          children: [
            webView,
            currentURL == 'about:blank' || isStartSearch == true
                ? appView
                : SizedBox(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLoad(String url) async {
    setState(() {
      isStartSearch = false;
    });
    setState(() {
      currentURL = resolveURL(url);
    });
    if (currentURL != 'about:blank') {
      updateSearchBar(0, currentURL);
    } else {
      setState(() {
        searchBarController.valueWith(
          progress: 0,
          icon: Icons.search,
          defautText: 'Search',
          shouldHidRefresh: true,
          submitedText: currentURL,
        );
      });
    }
    if (controller != null) {
      await controller.loadUrl(currentURL);
    }
  }

  Widget get searchBar => SearchBar(
        searchBarController: searchBarController,
        onStartSearch: () async {
          setState(() {
            isStartSearch = true;
          });
        },
        onSubmitted: (text) async {
          await _handleLoad(text);
        },
        onCancelInput: () async {
          setState(() {
            isStartSearch = false;
          });
        },
        onRefresh: () async {
          print("onRefresh");
          setState(() {
            isStartSearch = false;
          });
          if (this.controller != null) {
            await controller.reload();
          }
        },
      );

  Widget get appView => Apps(
        key: LabeledGlobalKey('apps'),
        onAppSelected: (app) async {
          await _handleLoad(app['url']);
        },
      );

  InAppWebView get webView => InAppWebView(
        initialUrl: currentURL,
        initialOptions: {
          "domStorageEnabled": true,
          "databaseEnabled": true,
          "useShouldOverrideUrlLoading": true,
          "mixedContentMode": "MIXED_CONTENT_ALWAYS_ALLOW",
        },
        initialJs: _headJS(widget.headController.value) +
            _genesisJS(widget.genesis) +
            _walletsJS(widget.walletsController.value),
        onWebViewCreated: (InAppWebViewController controller) async {
          setState(() {
            this.controller = controller;
          });
          if (widget.onWebViewChanged != null) {
            widget.onWebViewChanged(controller);
          }
          if (currentURL != 'about:blank') {
            updateSearchBar(0, currentURL);
          }
          controller.addJavaScriptHandler("Thor", (arguments) async {
            debugPrint('Thor arguments $arguments');
            dynamic data = await widget.driver.callMethod(arguments);
            debugPrint("Thor response $data");
            return data;
          });
          controller.addJavaScriptHandler("navigatedInPage", (arguments) async {
            if (widget.onWebViewChanged != null) {
              widget.onWebViewChanged(controller);
            }
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
                  SigningTxOptions.fromJSON(arguments[2], currentURL);
              return _showSigningDialog(
                SignTxDialog(
                  txMessages: txMessages,
                  options: options,
                ),
              );
            } else if (arguments[0] == 'signCert') {
              SigningCertMessage certMessage =
                  SigningCertMessage.fromJSON(arguments[1]);
              SigningCertOptions options =
                  SigningCertOptions.fromJSON(arguments[2], currentURL);
              return _showSigningDialog(
                SignCertificateDialog(
                  certMessage: certMessage,
                  options: options,
                ),
              );
            }
            throw ArgumentError('unsupported method');
          });
        },
        onLoadStart: (InAppWebViewController controller, String url) async {
          setState(() {
            currentURL = url;
          });
          if (currentURL != 'about:blank') {
            updateSearchBar(0, currentURL);
          } else {
            setState(() {
              searchBarController.valueWith(
                progress: 0,
                icon: Icons.search,
                defautText: 'Search',
                shouldHidRefresh: true,
                submitedText: currentURL,
              );
            });
          }
          if (widget.onWebViewChanged != null) {
            widget.onWebViewChanged(controller);
          }
        },
        onLoadStop: (InAppWebViewController controller, String url) async {
          setState(() {
            currentURL = url;
          });
          if (currentURL != 'about:blank') {
            updateSearchBar(1, currentURL);
          } else {
            setState(() {
              searchBarController.valueWith(
                progress: 0,
                icon: Icons.search,
                shouldHidRefresh: true,
                submitedText: currentURL,
              );
            });
          }
          if (widget.onWebViewChanged != null) {
            widget.onWebViewChanged(controller);
          }
        },
        onProgressChanged:
            (InAppWebViewController controller, int progress) async {
          if (currentURL != 'about:blank') {
            updateSearchBar(progress / 100, currentURL);
          } else {
            setState(() {
              searchBarController.valueWith(
                progress: 0,
                icon: Icons.search,
                shouldHidRefresh: true,
                submitedText: currentURL,
              );
            });
          }
        },
        onConsoleMessage:
            (InAppWebViewController controller, ConsoleMessage consoleMessage) {
          debugPrint("""
console output:
sourceURL: ${consoleMessage.sourceURL}
lineNumber: ${consoleMessage.lineNumber}
message: ${consoleMessage.message}
messageLevel: ${consoleMessage.messageLevel}
                  """);
        },
        shouldOverrideUrlLoading:
            (InAppWebViewController controller, String url) async {
          print("shouldOverrideUrlLoading $url");
          if (url.startsWith('http')) {
            await controller.loadUrl(url);
          } else {
            print("unknown url $url");
          }
        },
      );

  Future<dynamic> _showSigningDialog(Widget siginingDialog) async {
    dynamic result = await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, a, b) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset.zero).animate(a),
          child: siginingDialog,
        );
      },
    );
    if (result == null) {
      throw ArgumentError('user cancelled');
    }
    return result.encoded;
  }

  String _walletsJS(List<String> wallets) {
    String js = 'window.wallets=[';
    for (String address in wallets) {
      js += "'$address',";
    }
    js += "];";
    return js;
  }

  String _headJS(Block head) {
    return '''
      window.block_head={
        id: '${head.id}',
        number:${head.number},
        timestamp:${head.timestamp},
        parentID:'${head.parentID}'
      };''';
  }

  String _genesisJS(Block genesis) {
    return '''
      window.genesis={
        number:${genesis.number},
        id:'${genesis.id}',
        size:${genesis.size},
        timestamp:${genesis.timestamp},
        parentID:'${genesis.parentID}',
        gasLimit:${genesis.gasLimit},
        beneficiary:'${genesis.beneficiary}',
        gasUsed: ${genesis.gasUsed},
        totalScore:${genesis.totalScore},
        txsRoot:'${genesis.txsRoot}',
        txsFeatures:${genesis.txsFeatures},
        stateRoot:'${genesis.stateRoot}',
        receiptsRoot:'${genesis.receiptsRoot}',
        signer:'${genesis.signer}',
        transactions:${genesis.transactions},
        isTrunk:${genesis.isTrunk}
      };''';
  }

  void updateSearchBar(double progress, String url) {
    Uri uri = Uri.parse(url);
    IconData icon;
    if (uri.scheme == 'https') {
      icon = Icons.lock;
    } else {
      icon = Icons.lock_open;
    }
    setState(() {
      searchBarController.valueWith(
        progress: progress,
        icon: icon,
        defautText: getDomain(uri),
        submitedText: url,
      );
    });
  }

  String getDomain(Uri uri) {
    String host = uri.host;
    List<String> components = host.split('.');
    if (components.length < 3) {
      return host;
    }
    return "${components[1]}.${components[2]}";
  }

  String resolveURL(String url) {
    RegExp urlRegExp = RegExp(
        r"^(?=^.{3,255}$)(http(s)?:\/\/)?(www\.)?[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+(:\d+)*(\/\w+\.\w+)*([\?&]\w+=\w*)*$");
    if (urlRegExp.hasMatch(url)) {
      if (url.startsWith("http")) {
        return Uri.encodeFull(url);
      }
      return Uri.encodeFull("http://$url");
    }
    RegExp domainRegExp = RegExp(
        r"^(?=^.{3,255}$)[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+$");
    if (domainRegExp.hasMatch(url)) {
      return "http://$url";
    }
    Uri uri = Uri.parse(url);
    if (uri.hasScheme) {
      return Uri.encodeFull(url);
    }
    return Uri.encodeFull("https://cn.bing.com/search?q=$url");
  }
}