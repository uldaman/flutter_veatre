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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:veatre/src/ui/activities.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:webview_flutter/webview_flutter.dart' as FlutterWebView;
import 'package:veatre/common/globals.dart';
import 'package:veatre/common/net.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/models/dapp.dart';
import 'package:veatre/src/models/certificate.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/createBookmark.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/tabViews.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/ui/signCertificateDialog.dart';
import 'package:veatre/src/ui/signTxDialog.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/searchBar.dart';
import 'package:veatre/src/ui/apps.dart';
import 'package:veatre/src/storage/walletStorage.dart';

class WebView extends StatefulWidget {
  final Key key;
  final int id;
  final Network network;
  final Appearance appearance;
  final String initialURL;

  WebView({
    @required this.key,
    @required this.id,
    @required this.network,
    @required this.appearance,
    @required this.initialURL,
  }) : super(key: key);

  @override
  WebViewState createState() => WebViewState();
}

class WebViewState extends State<WebView> with AutomaticKeepAliveClientMixin {
  String key;
  bool isKeyboardVisible = false;
  int bookmarkID;
  bool canBack = false;
  bool canForward = false;
  bool isStartSearch = false;
  int id;
  double progress = 0;
  bool canBookmarked = false;
  String _currentURL;
  Appearance _appearance;

  final GlobalKey captureKey = GlobalKey();
  FlutterWebView.WebViewController controller;
  Completer<BlockHead> _head = new Completer();
  SearchBarController searchBarController = SearchBarController(
    SearchBarValue(
      shouldCancelInput: true,
      rightView: null,
      leftView: Icon(
        Icons.search,
        size: 20,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    id = widget.id;
    key = randomHex(32);
    _currentURL = widget.initialURL;
    _appearance = widget.appearance;
    Globals.addBlockHeadHandler(_handleHeadChanged);
    Globals.addAppearanceHandler(_handleAppearanceChanged);
    Globals.addTabHandler(_handleTabChanged);
    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        setState(() {
          this.isKeyboardVisible = visible;
        });
      },
    );
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

  void _handleTabChanged() async {
    final tabValue = Globals.tabValue;
    if (tabValue.network == widget.network) {
      key = tabValue.tabKey;
      if (tabValue.stage == TabStage.RemoveAll) {
        await controller.loadHTMLString("", null);
      }
      if (tabValue.id == id) {
        if (tabValue.stage == TabStage.Removed ||
            tabValue.stage == TabStage.Coverred) {
          await controller.loadHTMLString("", null);
        } else if (tabValue.stage == TabStage.SelectedInAlive) {
          await controller.loadUrl(tabValue.url);
        }
      }
    }
  }

  Future<void> updateBookmarkID(String url) async {
    Bookmark bookmark = await BookmarkStorage.queryByURL(widget.network, url);
    if (bookmark != null) {
      setState(() {
        bookmarkID = bookmark.id;
      });
    } else {
      setState(() {
        bookmarkID = null;
      });
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
        actions: <Widget>[
          isStartSearch
              ? FlatButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () async {
                    searchBarController.valueWith(
                      shouldCancelInput: true,
                    );
                    setState(() {
                      isStartSearch = false;
                    });
                  },
                )
              : Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: IconButton(
                        icon: Icon(
                          bookmarkID == null
                              ? Icons.bookmark_border
                              : Icons.bookmark,
                          size: 20,
                        ),
                        disabledColor: Colors.grey[500],
                        color: Colors.grey,
                        onPressed: _currentURL == Globals.initialURL
                            ? null
                            : bookmarkID == null
                                ? () async {
                                    final meta = await metaData;
                                    if (meta != null) {
                                      await _present(
                                        CreateBookmark(
                                          documentMetaData: meta,
                                          network: widget.network,
                                        ),
                                      );
                                      await updateBookmarkID(_currentURL);
                                    }
                                  }
                                : () async {
                                    await BookmarkStorage.delete(bookmarkID);
                                    await updateBookmarkID(_currentURL);
                                  },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () async {
                        await _present(Settings());
                      },
                    ),
                  ],
                ),
        ],
        title: searchBar,
      ),
      body: Column(
        children: <Widget>[
          !isStartSearch && progress < 1 && progress > 0
              ? SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                  ),
                )
              : SizedBox(),
          Expanded(
            child: RepaintBoundary(
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
          ),
        ],
      ),
      bottomNavigationBar: isKeyboardVisible ? SizedBox() : bottomNavigationBar,
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
                return actionSheet(bookmark);
              });
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
            updateSearchBar(url, progress);
          }
        },
        onWebViewCreated: (FlutterWebView.WebViewController controller) async {
          this.controller = controller;
          updateSearchBar(_currentURL, progress);
        },
        onPageStarted: (String url) async {
          if (controller != null) {
            await updateBackForwad();
            updateSearchBar(url, 0);
          }
          setState(() {
            _currentURL = url;
            isStartSearch = false;
          });
        },
        onPageFinished: (String url) async {
          if (controller != null) {
            await updateBookmarkID(url);
            await updateBackForwad();
            await controller
                .evaluateJavascript(_darkMode(_appearance == Appearance.dark));
          }
          updateSearchBar(url, 1);
          setState(() {
            _currentURL = url;
            progress = 1;
            isStartSearch = false;
          });
        },
        onProgressChanged: (double progress) {
          updateSearchBar(_currentURL, progress);
          setState(() {
            this.progress = progress;
          });
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
        this.canBack = canBack && _currentURL != Globals.initialURL;
        this.canForward = canForward;
      });
    }
  }

  void updateSearchBar(String url, double progress) {
    Uri uri = Uri.parse(url);
    if (url != Globals.initialURL) {
      IconData icon;
      if (uri.scheme.startsWith('https')) {
        icon = Icons.lock;
      } else {
        icon = Icons.lock_open;
      }
      String domain = getDomain(uri);
      searchBarController.valueWith(
        leftView: Icon(
          icon,
          color: Theme.of(context).primaryIconTheme.color,
          size: 20,
        ),
        defautText: domain == "" ? "Search" : domain,
        submitedText: url,
        rightView: !uri.scheme.startsWith("http")
            ? null
            : !isStartSearch && progress == 1
                ? IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).accentTextTheme.title.color,
                      size: 20,
                    ),
                    onPressed: () async {
                      setState(() {
                        isStartSearch = false;
                      });
                      await controller.reload();
                    })
                : IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).accentTextTheme.title.color,
                      size: 20,
                    ),
                    onPressed: () async {
                      setState(() {
                        isStartSearch = false;
                      });
                      await controller.stopLoading();
                    }),
      );
    } else {
      searchBarController.valueWith(
        leftView: Icon(
          Icons.search,
          color: Theme.of(context).accentTextTheme.title.color,
          size: 20,
        ),
        defautText: 'Search',
        rightView: null,
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
              Uint8List captureData = await takeScreenshot();
              String t = await title;
              WebViews.updateSnapshot(
                widget.network,
                id,
                key,
                title: t == "" ? 'New Tab' : t,
                data: captureData,
                url: _currentURL,
              );
              final size = captureKey.currentContext.size;
              await _present(
                TabViews(
                  id: id,
                  currentTabKey: key,
                  url: _currentURL,
                  ratio: size.width / size.height,
                  network: widget.network,
                  appearance: _appearance,
                ),
              );
              break;
            case 3:
              await _present(Activities(network: widget.network));
              break;
            case 4:
              await _present(ManageWallets());
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
        Icons.filter_none,
        active,
        30,
      ),
      bottomNavigationBarItem(
        FontAwesomeIcons.arrowAltCircleUp,
        active,
        30,
      ),
      bottomNavigationBarItem(
        FontAwesomeIcons.wallet,
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

  Widget sheet(Widget child) {
    return Container(
      alignment: Alignment.center,
      child: child,
      height: 45,
    );
  }

  CupertinoActionSheet actionSheet(Bookmark bookmark) {
    return CupertinoActionSheet(
      title: sheet(
        Text(
          bookmark.url,
          style: Theme.of(context).accentTextTheme.title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: <Widget>[
        sheet(
          FlatButton(
            child: Text(
              'Copy URL',
              style: TextStyle(color: Colors.blue, fontSize: 20),
            ),
            onPressed: () async {
              await Clipboard.setData(new ClipboardData(text: bookmark.url));
              Navigator.of(context).pop();
            },
          ),
        ),
        sheet(
          FlatButton(
            child: Text(
              'Edit',
              style: TextStyle(color: Colors.blue, fontSize: 20),
            ),
            onPressed: () async {
              await _present(
                CreateBookmark(
                  eidtBookmarkID: bookmark.id,
                  documentMetaData: DocumentMetaData(
                    icon: bookmark.favicon,
                    title: bookmark.title,
                    url: bookmark.url,
                  ),
                  network: widget.network,
                ),
              );
              Navigator.of(context).pop();
            },
          ),
        ),
        sheet(
          FlatButton(
            child: Text(
              'Remove',
              style: TextStyle(
                color: Colors.red,
                fontSize: 20,
              ),
            ),
            onPressed: () async {
              await BookmarkStorage.delete(bookmark.id);
              Globals.updateBookmark(bookmark);
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
      cancelButton: sheet(
        FlatButton(
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.blue, fontSize: 20),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
