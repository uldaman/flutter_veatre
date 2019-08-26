import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:veatre/common/net.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/models/dapp.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/createBookmark.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/tabViews.dart';
import 'package:veatre/src/ui/webViews.dart';
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

class WebView extends StatefulWidget {
  final Key key;
  final int id;
  final Network network;
  final Appearance appearance;
  final String initialURL;

  WebView({
    this.key,
    this.id,
    @required this.network,
    @required this.appearance,
    @required this.initialURL,
  }) : super(key: key);

  @override
  WebViewState createState() => WebViewState();
}

class WebViewState extends State<WebView> with AutomaticKeepAliveClientMixin {
  bool canBack = false;
  bool canForward = false;
  bool isStartSearch = false;
  String _currentURL;
  final GlobalKey captureKey = GlobalKey();
  FlutterWebView.WebViewController controller;
  Completer<BlockHead> _head = new Completer();
  Appearance _appearance;
  int _id;

  SearchBarController searchBarController = SearchBarController(
    SearchBarValue(
      shouldHideRightItem: true,
      progress: 0,
      icon: Icons.search,
    ),
  );

  @override
  void initState() {
    super.initState();
    _id = widget.id;
    _currentURL = widget.initialURL;
    _appearance = widget.appearance;
    Globals.addBlockHeadHandler(_handleHeadChanged);
    Globals.addAppearanceHandler(_handleAppearanceChanged);
    Globals.addTabHandler(_handleTabChanged);
  }

  void _handleHeadChanged() async {
    final blockHeadForNetwork = Globals.blockHeadForNetwork;
    if (blockHeadForNetwork.network == widget.network && !_head.isCompleted) {
      _head.complete(blockHeadForNetwork.head);
    }
  }

  void _handleAppearanceChanged() async {
    setState(() {
      _appearance = Globals.appearance;
    });
    if (controller != null) {
      await controller
          .evaluateJavascript(_darkMode(_appearance == Appearance.dark));
    }
  }

  void _handleTabChanged() {
    final tabControllerValue = Globals.tabControllerValue;
    if (tabControllerValue.network == widget.network &&
        tabControllerValue.stage == TabStage.Removed &&
        tabControllerValue.id < _id) {
      _id--;
    }
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    Globals.removeAppearanceHandler(_handleAppearanceChanged);
    Globals.removeTabHandler(_handleTabChanged);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: searchBar,
      ),
      body: RepaintBoundary(
        key: captureKey,
        child: Stack(
          children: [
            webView,
            _currentURL == Globals.initialURL || isStartSearch == true
                ? appView
                : SizedBox(),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  Future<void> _handleLoad(String url) async {
    setState(() {
      isStartSearch = false;
    });
    if (controller != null) {
      await controller.loadUrl(resolveURL(url));
    }
  }

  Widget get searchBar => SearchBar(
        context,
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
            submitedText: _currentURL,
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
        initialUrl: widget.initialURL,
        javascriptMode: FlutterWebView.JavascriptMode.unrestricted,
        javascriptHandlers: _javascriptChannels.toSet(),
        injectJavascript: _initialParamsJS +
            Globals.connexJS +
            _darkMode(
              _appearance == Appearance.dark,
            ),
        onURLChanged: (url) async {
          await updateBackForwad();
          _currentURL = url;
          if (_currentURL != Globals.initialURL) {
            updateSearchBar(null, url);
          }
        },
        onWebViewCreated: (FlutterWebView.WebViewController controller) async {
          this.controller = controller;
          updateSearchBar(0, _currentURL);
        },
        onPageStarted: (String url) async {
          if (controller != null) {
            await updateBackForwad();
            updateSearchBar(null, url);
          }
          setState(() {
            _currentURL = url;
            isStartSearch = false;
          });
        },
        onPageFinished: (String url) async {
          if (controller != null) {
            await updateBackForwad();
            await controller
                .evaluateJavascript(_darkMode(_appearance == Appearance.dark));
          }
          updateSearchBar(1, url);
          setState(() {
            _currentURL = url;
            isStartSearch = false;
          });
        },
        onProgressChanged: (double progress) {
          updateSearchBar(progress, _currentURL);
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

  String _darkMode(bool enable) {
    String mode = enable ? 'true' : 'false';
    return 'window.__NightMode__.setEnabled($mode);';
  }

  Future<void> updateBackForwad() async {
    if (controller != null) {
      bool canBack = await controller.canGoBack();
      bool canForward = await controller.canGoForward();
      setState(() {
        this.canBack = canBack;
        this.canForward = canForward;
      });
    }
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
        submitedText: _currentURL,
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
            List<String> wallets = await WalletStorage.wallets(widget.network);
            print('wallets $wallets');
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
                SigningTxOptions.fromJSON(arguments[2], _currentURL);
            await _validate(options.signer);
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
                SigningCertOptions.fromJSON(arguments[2], _currentURL);
            await _validate(options.signer);
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

  Future<void> _validate(String signer) async {
    List<String> wallets = await WalletStorage.wallets(widget.network);
    if (signer != null && !wallets.contains(signer)) {
      throw 'signer does not exist';
    }
  }

  BottomNavigationBar get bottomNavigationBar => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).primaryColor,
        items: bottomNavigationBarItems,
        onTap: (index) async {
          switch (index) {
            case 0:
              if (canBack && controller != null) {
                return controller.goBack();
              }
              break;
            case 1:
              if (canForward && controller != null) {
                return controller.goForward();
              }
              break;
            case 2:
              if (_currentURL != Globals.initialURL) {
                final meta = await metaData;
                if (meta != null) {
                  await _present(
                    CreateBookmark(
                      documentMetaData: meta,
                      network: widget.network,
                    ),
                  );
                }
              }
              break;
            case 3:
              Uint8List captureData = await takeScreenshot();
              String t = await title;
              WebViews.updateSnapshot(
                widget.network,
                _id,
                title: t == "" ? 'New Tab' : t,
                data: captureData,
              );
              await _present(
                TabViews(
                  id: _id,
                  network: widget.network,
                  appearance: _appearance,
                ),
              );
              // if (tabResult != null) {
              //   if (tabResult.stage == TabStage.Created ||
              //       tabResult.stage == TabStage.RemovedAll) {
              //     int tab = WebViews.newWebView(
              //       network: widget.network,
              //       appearance: _appearance,
              //     );
              //     Globals.updateTab(tab);
              //   } else if (tabResult.stage == TabStage.Selected) {
              //     Globals.updateTab(tabResult.id);
              //   }
              // }
              break;
            case 4:
              await _present(Settings());
              break;
          }
        },
      );

  BottomNavigationBarItem bottomNavigationBarItem(
    IconData iconData,
    Color color,
    double size,
  ) {
    Widget nullWidget = SizedBox(height: 0);
    return BottomNavigationBarItem(
      icon: Icon(
        iconData,
        size: size,
        color: color,
      ),
      title: nullWidget,
    );
  }

  List<BottomNavigationBarItem> get bottomNavigationBarItems {
    Color active = Colors.blue;
    Color inactive = Colors.grey[300];
    return [
      bottomNavigationBarItem(
        Icons.arrow_back_ios,
        canBack ? active : inactive,
        30,
      ),
      bottomNavigationBarItem(
        Icons.arrow_forward_ios,
        canForward ? active : inactive,
        30,
      ),
      bottomNavigationBarItem(
        Icons.star_border,
        _currentURL != Globals.initialURL ? active : inactive,
        40,
      ),
      bottomNavigationBarItem(
        Icons.filter_none,
        active,
        30,
      ),
      bottomNavigationBarItem(
        Icons.more_horiz,
        active,
        30,
      ),
    ];
  }

  Future<DocumentMetaData> get metaData async {
    if (controller != null) {
      final result =
          await controller.evaluateJavascript("window.__getMetaData__();");
      return DocumentMetaData.fromJSON(json.decode(result));
    }
    return null;
  }

  Future<Uint8List> takeScreenshot() async {
    if (isStartSearch || _currentURL == Globals.initialURL) {
      try {
        RenderRepaintBoundary boundary =
            captureKey.currentContext.findRenderObject();
        var image = await boundary.toImage(pixelRatio: 1.0);
        ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
        Uint8List bytes = byteData.buffer.asUint8List();
        return bytes;
      } catch (e) {
        print("takeScreenshot error: $e");
        return null;
      }
    } else if (controller != null) {
      return controller.takeScreenshot();
    }
    return null;
  }

  Future<String> get title async {
    if (controller != null) {
      return controller.currentTitle();
    }
    return null;
  }

  Future<dynamic> _present(Widget widget) async {
    dynamic result = await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (context, a, b) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset.zero).animate(a),
          child: widget,
        );
      },
    );
    return result;
  }
}
