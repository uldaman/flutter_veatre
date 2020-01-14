import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:webview_flutter/webview_flutter.dart' as FlutterWebView;

import 'package:veatre/common/net.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/validators.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/models/dapp.dart';
import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/activities.dart';
import 'package:veatre/src/ui/createOrImportWallet.dart';
import 'package:veatre/src/ui/mainUI.dart';
import 'package:veatre/src/ui/createBookmark.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/tabViews.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/ui/sign_dialog/transaction_dialog.dart';
import 'package:veatre/src/ui/signCertificate.dart';
import 'package:veatre/src/ui/snapshotCard.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/searchBar.dart';
import 'package:veatre/src/ui/apps.dart';

class WebView extends StatefulWidget {
  final int id;
  final Network network;
  final String initialURL;
  final bool offstage;
  final String tabKey;

  WebView({
    @required this.id,
    @required this.network,
    @required this.initialURL,
    @required this.offstage,
    @required this.tabKey,
  });

  @override
  WebViewState createState() => WebViewState();
}

class WebViewState extends State<WebView> with AutomaticKeepAliveClientMixin {
  String key;
  int id;
  int _bookmarkID;
  bool _isKeyboardVisible = false;
  bool _canBack = false;
  bool _canForward = false;
  bool _isOnFocus = false;
  double _progress = 0;
  bool _offstage;
  String _currentURL;
  Future<dynamic> Function(Widget) _showSovereignDialog;

  final GlobalKey captureKey = GlobalKey();
  FlutterWebView.WebViewController controller;
  Completer<BlockHead> _head = new Completer();
  SearchBarController searchBarController = SearchBarController(
    SearchBarValue(
      shouldCancelInput: true,
      rightView: null,
      leftView: Icon(
        MaterialCommunityIcons.magnify,
        size: 20,
      ),
    ),
  );
  Activity latestActivity;
  bool btnEnabled = true;
  bool showSnapshot = false;

  @override
  void initState() {
    _showSovereignDialog = () {
      bool isShowing = false;
      return (Widget dialog) async {
        if (isShowing) throw 'request is in progress';
        isShowing = true;
        dynamic result = await showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => dialog,
        );
        isShowing = false;
        if (result == null) throw 'user cancelled';
        return result.encoded;
      };
    }();
    id = widget.id;
    key = widget.tabKey;
    _offstage = widget.offstage;
    _currentURL = widget.initialURL;
    Globals.addBlockHeadHandler(_handleHeadChanged);
    Globals.addBookmarkHandler(_handleBookmark);
    Globals.addTabHandler(_handleTabChanged);
    Globals.addClipboardHandler(_handleClipboard);
    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        setState(() {
          this._isKeyboardVisible = visible;
        });
      },
    );
    updateLatestActivity();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Offstage(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: <Widget>[
            _isOnFocus
                ? FlatButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () async {
                      setState(() {
                        _isOnFocus = false;
                      });
                      updateSearchBar(_currentURL, 1, true);
                    },
                  )
                : Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: IconButton(
                          icon: Icon(
                            _bookmarkID == null
                                ? MaterialCommunityIcons.bookmark_plus_outline
                                : MaterialCommunityIcons.bookmark_plus,
                            size: 20,
                          ),
                          disabledColor: Color(0xFFCCCCCC),
                          color: Theme.of(context).primaryIconTheme.color,
                          onPressed: _currentURL == Globals.initialURL ||
                                  _progress != 1
                              ? null
                              : _bookmarkID == null
                                  ? () async {
                                      final meta = await metaData;
                                      if (meta != null) {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => CreateBookmark(
                                                documentMetaData: meta),
                                            fullscreenDialog: true,
                                          ),
                                        );
                                        await updateBookmarkID(_currentURL);
                                      }
                                    }
                                  : () async {
                                      await BookmarkStorage.delete(_bookmarkID);
                                      Globals.updateBookmark(Bookmark(
                                        id: _bookmarkID,
                                        network: widget.network,
                                      ));
                                      await updateBookmarkID(_currentURL);
                                    },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          MaterialCommunityIcons.settings_outline,
                          size: 20,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return Settings();
                              },
                              settings: RouteSettings(name: Settings.routeName),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ],
          title: searchBar,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              !_isOnFocus && _progress < 1 && _progress > 0
                  ? SizedBox(
                      height: 1,
                      child: LinearProgressIndicator(
                        value: _progress,
                        valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).primaryColor),
                        backgroundColor: Theme.of(context).dividerColor,
                      ),
                    )
                  : Divider(height: 1, thickness: 1),
              Expanded(
                child: RepaintBoundary(
                  key: captureKey,
                  child: Stack(
                    children: [
                      webView,
                      Offstage(
                        child: appView,
                        offstage: !(_currentURL == Globals.initialURL ||
                            _isOnFocus == true),
                      ),
                      Offstage(
                        offstage: !showSnapshot,
                        child: Hero(
                          tag: "snapshot$id${widget.network}",
                          child: SnapshotCard(
                            WebViews.getSnapshot(
                                  key,
                                  network: Globals.network,
                                ) ??
                                Snapshot(),
                            false,
                            isSelected: true,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              _isKeyboardVisible
                  ? SizedBox()
                  : SizedBox(
                      height: 59,
                      child: Column(
                        children: <Widget>[
                          Divider(
                            thickness: 1,
                            height: 1,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: bottomItems,
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
      offstage: _offstage,
    );
  }

  Future<void> _handleLoad(String url) async {
    setState(() {
      _isOnFocus = false;
    });
    if (controller != null) {
      await controller.loadUrl(resolveURL(url));
    }
  }

  Widget get searchBar => SearchBar(
        searchBarController: searchBarController,
        onFocus: () async {
          setState(() {
            _isOnFocus = true;
          });
        },
        onSubmitted: (text) async {
          await _handleLoad(text);
        },
      );

  Widget get appView => DApps(
        network: widget.network,
        onAppSelected: (DApp app) async {
          await _handleLoad(app.url);
        },
        onBookmarkLongPressed: (Bookmark bookmark) async {
          await showCupertinoModalPopup(
              context: context,
              builder: (context) {
                return actionSheet(context, bookmark);
              });
        },
        onBookmarkSelected: (Bookmark bookmark) async {
          await _handleLoad(bookmark.url);
        },
      );

  String get _injectedJS => _initialParamsJS + Globals.connexJS;

  FlutterWebView.WebView get webView => FlutterWebView.WebView(
        initialUrl: widget.initialURL,
        javascriptMode: FlutterWebView.JavascriptMode.unrestricted,
        javascriptHandlers: _javascriptChannels.toSet(),
        injectJavascript: _injectedJS,
        prompt: json.encode(Globals.head(network: widget.network).encoded),
        onURLChanged: (url) async {
          _currentURL = url;
          if (_currentURL != Globals.initialURL) {
            updateSearchBar(url, _progress, !_isOnFocus);
          }
        },
        onWebViewCreated: (FlutterWebView.WebViewController controller) async {
          this.controller = controller;
          updateSearchBar(_currentURL, _progress, !_isOnFocus);
        },
        onPageStarted: (String url) async {
          setState(() {
            _currentURL = url;
          });
          if (controller != null) {
            updateSearchBar(url, 0, !_isOnFocus);
          }
        },
        onPageFinished: (String url) async {
          if (controller != null) {
            await updateBookmarkID(url);
          }
          updateSearchBar(url, 1, !_isOnFocus);
          setState(() {
            _currentURL = url;
            _progress = 1;
          });
        },
        onProgressChanged: (double progress) {
          updateSearchBar(_currentURL, progress, !_isOnFocus);
          setState(() {
            this._progress = progress;
          });
        },
        onCanGoBack: (bool canGoBack) {
          setState(() => _canBack = canGoBack);
        },
        onCanGoForward: (bool canGoForward) {
          setState(() => _canForward = canGoForward);
        },
        navigationDelegate: (FlutterWebView.NavigationRequest request) {
          if (request.url.startsWith('http') ||
              request.url.startsWith('file') ||
              request.url == Globals.initialURL) {
            return FlutterWebView.NavigationDecision.navigate;
          }
          return FlutterWebView.NavigationDecision.prevent;
        },
        onDelegateError: (String error) {
          controller.loadHTMLString('''
            <html >
              <head>
                <meta charset="UTF-8">
              </head>
              <body>
                  <p style="text-align:center;
                    position: absolute;
                    left: 50%;
                    top: 40%;
                    transform: translate(-50%,-50%);
                    font-size: 50px;">$error</p >
                  </p >
              </body>
            </html>
          ''');
        },
      );

  String get _initialParamsJS {
    final genesis = Globals.genesis(widget.network);
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
    ''';
  }

  void updateSearchBar(String url, double progress, bool shouldCancelInput) {
    Uri uri = Uri.parse(url);
    if (url != Globals.initialURL) {
      IconData icon;
      if (uri.scheme.startsWith('https')) {
        icon = Icons.lock;
      } else {
        icon = Icons.lock_open;
      }
      String domain = uri.host;
      searchBarController.valueWith(
        leftView: Icon(
          icon,
          size: 20,
        ),
        shouldCancelInput: shouldCancelInput,
        defautText: domain == "" ? "Search" : domain,
        submitedText: url,
        rightView: !uri.scheme.startsWith("http") || _isOnFocus
            ? null
            : progress == 1
                ? IconButton(
                    icon: Icon(
                      MaterialCommunityIcons.refresh,
                      size: 20,
                    ),
                    onPressed: () async {
                      setState(() {
                        _isOnFocus = false;
                      });
                      await controller.reload();
                    })
                : IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                    ),
                    onPressed: () async {
                      setState(() {
                        _isOnFocus = false;
                      });
                      await controller.stopLoading();
                    }),
      );
    } else {
      searchBarController.valueWith(
        leftView: Icon(
          Icons.search,
          size: 20,
        ),
        defautText: 'Search',
        rightView: null,
        shouldCancelInput: shouldCancelInput,
        submitedText: _currentURL,
      );
    }
  }

  String resolveURL(String url) {
    if (isAddress(url) || isHash(url)) {
      if (!url.startsWith('0x')) {
        url = '0x$url';
      }
      return "https://${widget.network == Network.MainNet ? 'explore' : '/explore-testnet'}.vechain.org/search?content=$url";
    }
    RegExp domainRegExp = RegExp(
        r"^(?=^.{3,255}$)[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+$");
    if (domainRegExp.hasMatch(url)) {
      return "http://$url";
    }
    try {
      Uri uri = Uri.parse(url);
      if (uri.scheme.startsWith('http')) {
        return uri.toString();
      }
      return Uri.encodeFull("https://cn.bing.com/search?q=$url");
    } catch (e) {
      return Uri.encodeFull("https://cn.bing.com/search?q=$url");
    }
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
              ? Config.mainnet
              : Config.testnet;
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
            List<String> wallets =
                await WalletStorage.wallets(network: widget.network);
            return wallets.contains(arguments[1]);
          }
          List<WalletEntity> walletEntities =
              await WalletStorage.readAll(network: widget.network);
          if (walletEntities.length == 0) {
            bool isConfirmd = await customAlert(
              context,
              title: Text('No wallet available'),
              content: Text('Create or import a new wallet?'),
              confirmAction: () async {
                Navigator.of(context).pop(true);
              },
            );
            if (isConfirmd) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateOrImportWallet(
                    fromRouteName: MainUI.routeName,
                  ),
                  fullscreenDialog: true,
                  settings: RouteSettings(name: '/CreateOrImportWallet'),
                ),
              );
              List<WalletEntity> walletEntities =
                  await WalletStorage.readAll(network: widget.network);
              if (walletEntities.length > 0) {
                return handleSign(arguments);
              }
            }
            throw 'user cancelled';
          }
          return handleSign(arguments);
        }
      },
    );
    return [head, net, vendor];
  }

  Future<dynamic> handleSign(dynamic arguments) async {
    if (arguments[0] == 'signTx') {
      SigningTxOptions options =
          SigningTxOptions.fromJSON(arguments[2], _currentURL);
      await _validate(options.signer);
      List<SigningTxMessage> txMessages = [];
      for (Map<String, dynamic> txMsg in arguments[1]) {
        txMessages.add(SigningTxMessage.fromJSON(txMsg));
      }
      return _showSovereignDialog(
        TransactionDialog(
          options: options,
          txMessages: txMessages,
        ),
      );
    } else if (arguments[0] == 'signCert') {
      SigningCertMessage certMessage =
          SigningCertMessage.fromJSON(arguments[1]);
      SigningCertOptions options =
          SigningCertOptions.fromJSON(arguments[2], _currentURL);
      await _validate(options.signer);
      return _showSovereignDialog(SignCertificate(certMessage, options));
    }
    throw 'unsupported method';
  }

  List<Widget> get bottomItems {
    final snapshotLength = WebViews.snapshots(network: widget.network).length;
    final tabLength = snapshotLength == 0
        ? 1
        : snapshotLength +
            ((Globals.tabValue.stage == TabStage.Created ||
                        Globals.tabValue.stage == TabStage.Coverred) &&
                    !showSnapshot
                ? 1
                : 0);
    return [
      Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: bottomItem(
          MaterialCommunityIcons.chevron_left,
          onPressed: _canBack && _currentURL != Globals.initialURL
              ? controller?.goBack
              : null,
        ),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: bottomItem(
          MaterialCommunityIcons.chevron_right,
          onPressed: _canForward ? controller?.goForward : null,
        ),
      ),
      bottomItem(
        tabIcon(tabLength),
        size: 28,
        onPressed: () async {
          WebViews.updateSnapshot(
            id,
            key,
            widget.network,
            title: await controller?.getTitle(),
            data: await takeScreenshot(),
            url: _currentURL,
          );
          setState(() => showSnapshot = true);
          final size = captureKey.currentContext.size;
          await Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 300),
              pageBuilder: (context, animation, _) {
                return FadeTransition(
                  opacity: animation,
                  child: TabViews(
                    id: id,
                    currentTabKey: key,
                    url: _currentURL,
                    size: size,
                  ),
                );
              },
              fullscreenDialog: true,
            ),
          );
          setState(() => showSnapshot = false);
        },
      ),
      Stack(
        alignment: Alignment.topRight,
        children: <Widget>[
          latestActivity != null &&
                  !latestActivity.hasShown &&
                  latestActivity?.status == ActivityStatus.Reverted
              ? Icon(
                  Icons.error,
                  size: 12,
                )
              : SizedBox(),
          bottomItem(
            MaterialCommunityIcons.arrow_up_bold_circle_outline,
            size: 28,
            onPressed: () async {
              String url = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Activities(),
                  fullscreenDialog: true,
                ),
              );
              await updateLatestActivity();
              if (url != null) {
                await _handleLoad(url);
              }
            },
          ),
        ],
      ),
      bottomItem(
        MaterialCommunityIcons.cards_outline,
        size: 28,
        onPressed: () async {
          final url = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ManageWallets(),
              fullscreenDialog: true,
              settings: RouteSettings(name: ManageWallets.routeName),
            ),
          );
          if (url != null) {
            await _handleLoad(url);
          }
        },
      ),
    ];
  }

  IconData tabIcon(int tabLength) {
    switch (tabLength) {
      case 0:
        return MaterialCommunityIcons.numeric_0_box_multiple_outline;
      case 1:
        return MaterialCommunityIcons.numeric_1_box_multiple_outline;
      case 2:
        return MaterialCommunityIcons.numeric_2_box_multiple_outline;
      case 3:
        return MaterialCommunityIcons.numeric_3_box_multiple_outline;
      case 4:
        return MaterialCommunityIcons.numeric_4_box_multiple_outline;
      case 5:
        return MaterialCommunityIcons.numeric_5_box_multiple_outline;
      case 6:
        return MaterialCommunityIcons.numeric_6_box_multiple_outline;
      case 7:
        return MaterialCommunityIcons.numeric_7_box_multiple_outline;
      case 8:
        return MaterialCommunityIcons.numeric_8_box_multiple_outline;
      case 9:
        return MaterialCommunityIcons.numeric_9_box_multiple_outline;
      default:
        return MaterialCommunityIcons.numeric_9_plus_box_multiple_outline;
    }
  }

  Widget bottomItem(
    IconData iconData, {
    double size = 40,
    Future<void> Function() onPressed,
  }) {
    return IconButton(
      icon: Icon(
        iconData,
        size: size,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      color: Color(0xFF666666),
      disabledColor: Color(0xFFCCCCCC),
      onPressed: onPressed != null
          ? () async {
              if (btnEnabled) {
                try {
                  btnEnabled = false;
                  await onPressed();
                } finally {
                  btnEnabled = true;
                }
              }
            }
          : null,
    );
  }

  Future<DocumentMetaData> get metaData async {
    if (controller != null) {
      final result =
          await controller.evaluateJavascript("window.__getMetaData__();");
      print('result $result');
      return DocumentMetaData.fromJSON(json.decode(result));
    }
    return null;
  }

  Future<Uint8List> takeScreenshot() async {
    if (_isOnFocus || _currentURL == Globals.initialURL) {
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

  Widget _sheet(
    String text,
    Color color,
    Future<void> Function() onPressed,
  ) {
    return Container(
      child: FlatButton(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 17,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () async {
          await onPressed();
        },
      ),
      height: 46,
    );
  }

  CupertinoActionSheet actionSheet(BuildContext context, Bookmark bookmark) {
    return CupertinoActionSheet(
      title: Align(
        alignment: Alignment.center,
        child: Text(
          bookmark.url,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).primaryTextTheme.display1.color,
            fontSize: 17,
          ),
        ),
      ),
      actions: <Widget>[
        _sheet(
          'Copy URL',
          Theme.of(context).primaryColor,
          () async {
            await Clipboard.setData(new ClipboardData(text: bookmark.url));
            Navigator.of(context).pop();
          },
        ),
        _sheet(
          'Edit',
          Theme.of(context).primaryColor,
          () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateBookmark(
                  eidtBookmarkID: bookmark.id,
                  documentMetaData: DocumentMetaData(
                    icon: bookmark.favicon,
                    title: bookmark.title,
                    url: bookmark.url,
                  ),
                ),
                fullscreenDialog: true,
              ),
            );
            Navigator.of(context).pop();
          },
        ),
        _sheet(
          'Remove',
          Theme.of(context).errorColor,
          () async {
            await BookmarkStorage.delete(bookmark.id);
            Globals.updateBookmark(bookmark);
            Navigator.of(context).pop();
          },
        ),
      ],
      cancelButton: _sheet(
        'Cancel',
        Theme.of(context).primaryColor,
        () async {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> updateBookmarkID(String url) async {
    Bookmark bookmark = await BookmarkStorage.queryByURL(
      url,
      network: widget.network,
    );
    if (bookmark != null) {
      setState(() {
        _bookmarkID = bookmark.id;
      });
    } else {
      setState(() {
        _bookmarkID = null;
      });
    }
  }

  Future<void> updateLatestActivity() async {
    final activity = await ActivityStorage.latest(network: widget.network);
    setState(() {
      latestActivity = activity;
    });
  }

  Future<void> _validate(String signer) async {
    List<String> wallets = await WalletStorage.wallets(network: widget.network);
    if (signer != null && !wallets.contains(signer)) {
      throw 'signer does not exist';
    }
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    Globals.removeTabHandler(_handleTabChanged);
    Globals.removeBookmarkHandler(_handleBookmark);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _handleHeadChanged() async {
    final blockHeadForNetwork = Globals.blockHeadForNetwork;
    if (blockHeadForNetwork.network == widget.network && !_head.isCompleted) {
      if (controller != null) {
        await controller
            .setPrompt(json.encode(blockHeadForNetwork.head.encoded));
      }
      await updateLatestActivity();
      _head.complete(blockHeadForNetwork.head);
    }
  }

  Future<void> _loadHomePage() async {
    await controller?.goHomePage();
    setState(() {
      _canBack = false;
      _canForward = false;
    });
  }

  void _handleTabChanged() async {
    final tabValue = Globals.tabValue;
    key = tabValue.tabKey;
    if (tabValue.network == widget.network) {
      if (tabValue.stage == TabStage.RemoveAll) {
        setState(() {
          _offstage = true;
        });
        await _loadHomePage();
      } else {
        if (tabValue.id == id) {
          if (tabValue.stage == TabStage.Removed ||
              tabValue.stage == TabStage.Coverred) {
            await _loadHomePage();
          } else if (tabValue.stage == TabStage.SelectedInAlive) {
            await _loadHomePage();
            await controller.loadUrl(tabValue.url);
          }
          setState(() {
            _offstage = !(tabValue.stage == TabStage.SelectedInAlive ||
                tabValue.stage == TabStage.SelectedAlive ||
                tabValue.stage == TabStage.Coverred ||
                tabValue.stage == TabStage.Created);
          });
        } else if (!_offstage) {
          setState(() {
            _offstage = true;
          });
        }
      }
    }
  }

  Future<void> _handleBookmark() async {
    if (Globals.bookmark.network == Globals.network) {
      await updateBookmarkID(_currentURL);
    }
  }

  Future<void> _handleClipboard() async {
    final data = Globals.clipboardValue.data;
    final uri = Uri.parse(_currentURL);
    final isOnExplore = uri.host == 'explore.vechain.org' ||
        uri.host == 'explore-testnet.vechain.org';
    if (!_offstage &&
        Globals.network == widget.network &&
        !(_currentURL.indexOf(data) != -1 && isOnExplore)) {
      await customAlert(
        context,
        title: Text(
          "Search ${isAddress(data) ? 'Address' : 'Hash'}",
        ),
        content: Text(data),
        confirmAction: () async {
          Navigator.of(context).pop();
          await _handleLoad(data);
        },
      );
    }
  }
}
