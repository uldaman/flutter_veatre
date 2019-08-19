import 'dart:async';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:veatre/common/net.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/models/dapp.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:webview_flutter/webview_flutter.dart' as FlutterWebView;
import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/ui/signCertificateDialog.dart';
import 'package:veatre/src/ui/signTxDialog.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/searchBar.dart';
import 'package:veatre/src/ui/apps.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/common/globals.dart';

typedef onWebViewChangedCallback = void Function(
    FlutterWebView.WebViewController controller);

class WebView extends StatefulWidget {
  final Key key;
  final Network network;
  final onWebViewChangedCallback onWebViewChanged;

  WebView({
    this.key,
    this.network,
    this.onWebViewChanged,
  }) : super(key: key);

  @override
  WebViewState createState() => WebViewState();
}

class WebViewState extends State<WebView> with AutomaticKeepAliveClientMixin {
  bool isStartSearch = false;
  String currentURL = Globals.initialURL;
  SearchBarController searchBarController = SearchBarController(
    SearchBarValue(
      shouldHideRightItem: true,
      progress: 0,
      icon: Icons.search,
    ),
  );
  final GlobalKey captureKey = GlobalKey();
  FlutterWebView.WebViewController controller;
  Completer<BlockHead> _head = new Completer();

  @override
  void initState() {
    super.initState();
    Globals.watchBlockHead((blockHeadForNetwork) async {
      if (blockHeadForNetwork.network == widget.network && !_head.isCompleted) {
        _head.complete(blockHeadForNetwork.head);
      }
    });
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
            currentURL == Globals.initialURL || isStartSearch == true
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
    currentURL = resolveURL(url);
    updateSearchBar(0, currentURL);
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
          searchBarController.valueWith(
            submitedText: currentURL,
          );
          setState(() {
            isStartSearch = false;
          });
        },
        onRefresh: () async {
          setState(() {
            isStartSearch = false;
          });
          if (this.controller != null) {
            await controller.reload();
          }
        },
        onStop: () async {
          setState(() {
            isStartSearch = false;
          });
          if (this.controller != null) {
            await controller.stopLoading();
          }
        },
      );

  Widget get appView => DApps(
        network: widget.network,
        onAppSelected: (DApp app) async {
          await _handleLoad(app.url);
        },
        onBookmarkSelected: (Bookmark bookmark) async {
          await _handleLoad(bookmark.url);
        },
      );

  FlutterWebView.WebView get webView => FlutterWebView.WebView(
        initialUrl: currentURL,
        javascriptMode: FlutterWebView.JavascriptMode.unrestricted,
        javascriptHandlers: _javascriptChannels.toSet(),
        injectJavascript: _initialParamsJS + Globals.connexJS,
        onURLChanged: (url) {
          currentURL = url;
          if (widget.onWebViewChanged != null) {
            widget.onWebViewChanged(controller);
          }
          if (currentURL != Globals.initialURL) {
            updateSearchBar(null, currentURL);
          }
        },
        onWebViewCreated: (FlutterWebView.WebViewController controller) async {
          this.controller = controller;
          if (widget.onWebViewChanged != null) {
            widget.onWebViewChanged(controller);
          }
          updateSearchBar(0, currentURL);
        },
        onPageStarted: (String url) {
          currentURL = url;
          updateSearchBar(0, currentURL);
          if (widget.onWebViewChanged != null) {
            widget.onWebViewChanged(controller);
          }
          setState(() {
            isStartSearch = false;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            currentURL = url;
          });
          updateSearchBar(1, currentURL);
          if (widget.onWebViewChanged != null) {
            widget.onWebViewChanged(controller);
          }
          setState(() {
            isStartSearch = false;
          });
        },
        onProgressChanged: (double progress) {
          updateSearchBar(progress, currentURL);
        },
        navigationDelegate: (FlutterWebView.NavigationRequest request) {
          if (request.url.startsWith('http') ||
              request.url == Globals.initialURL) {
            return FlutterWebView.NavigationDecision.navigate;
          }
          return FlutterWebView.NavigationDecision.prevent;
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
      throw 'user cancelled';
    }
    return result.encoded;
  }

  String get _initialParamsJS {
    final genesis = Globals.genesis(widget.network);
    final initialHead = Globals.head(widget.network);
    return '''
    window.genesis = {
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
    };
    window.initialHead = {
        id: '${initialHead.id}',
        number:${initialHead.number},
        timestamp:${initialHead.timestamp},
        parentID:'${initialHead.parentID}'
    };
    ''';
  }

  void updateSearchBar(double progress, String url) {
    if (url != Globals.initialURL) {
      Uri uri = Uri.parse(url);
      IconData icon;
      if (uri.scheme == 'https') {
        icon = Icons.lock;
      } else {
        icon = Icons.lock_open;
      }
      searchBarController.valueWith(
        progress: progress,
        icon: icon,
        defautText: getDomain(uri),
        submitedText: url,
        shouldHideRightItem: false,
      );
    } else {
      searchBarController.valueWith(
        progress: 0,
        icon: Icons.search,
        defautText: 'Search',
        shouldHideRightItem: true,
        submitedText: currentURL,
      );
    }
  }

  String getDomain(Uri uri) {
    String host = uri.host;
    List<String> components = host.split('.');
    if (components.length <= 3) {
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

  List<FlutterWebView.JavascriptHandler> get _javascriptChannels {
    FlutterWebView.JavascriptHandler head = FlutterWebView.JavascriptHandler(
      name: 'Head',
      onMessageReceived: (List<dynamic> arguments) async {
        final head = await _head.future;
        _head = new Completer();
        return head.encoded;
      },
    );
    FlutterWebView.JavascriptHandler net = FlutterWebView.JavascriptHandler(
      name: 'Net',
      onMessageReceived: (List<dynamic> arguments) async {
        if (arguments.length >= 3) {
          String baseURL = widget.network == Network.MainNet
              ? NetworkStorage.mainnet
              : NetworkStorage.testnet;
          dynamic data = await Net.http(
              arguments[0], "$baseURL/${arguments[1]}", arguments[2]);
          return data;
        }
        return null;
      },
    );

    FlutterWebView.JavascriptHandler vendor = FlutterWebView.JavascriptHandler(
      name: 'Vendor',
      onMessageReceived: (List<dynamic> arguments) async {
        if (arguments.length > 0) {
          if (arguments[0] == 'owned' && arguments.length == 2) {
            List<String> wallets = Globals.walletsFor(widget.network);
            return wallets.contains(arguments[1]);
          }
          List<WalletEntity> walletEntities =
              await WalletStorage.readAll(widget.network);
          if (walletEntities.length == 0) {
            return customAlert(
              context,
              title: Text('No wallet available'),
              content: Text('Create or import a new wallet?'),
              confirmAction: () async {
                await Navigator.of(context).pushNamed(ManageWallets.routeName);
                Navigator.pop(context);
              },
            );
          }
          if (arguments[0] == 'signTx') {
            SigningTxOptions options =
                SigningTxOptions.fromJSON(arguments[2], currentURL);
            _validate(options.signer);
            List<SigningTxMessage> txMessages = [];
            for (Map<String, dynamic> txMsg in arguments[1]) {
              txMessages.add(SigningTxMessage.fromJSON(txMsg));
            }
            return _showSigningDialog(
              SignTxDialog(
                network: widget.network,
                txMessages: txMessages,
                options: options,
              ),
            );
          } else if (arguments[0] == 'signCert') {
            SigningCertMessage certMessage =
                SigningCertMessage.fromJSON(arguments[1]);
            SigningCertOptions options =
                SigningCertOptions.fromJSON(arguments[2], currentURL);
            _validate(options.signer);
            return _showSigningDialog(
              SignCertificateDialog(
                network: widget.network,
                certMessage: certMessage,
                options: options,
              ),
            );
          }
        }
        throw 'unsupported method';
      },
    );
    return [head, net, vendor];
  }

  void _validate(String signer) {
    if (signer != null &&
        !Globals.walletsFor(widget.network).contains(signer)) {
      throw 'signer does not exist';
    }
  }
}
