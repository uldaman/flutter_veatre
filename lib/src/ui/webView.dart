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
import 'package:veatre/src/ui/signCertificate.dart';
import 'package:webview_flutter/webview_flutter.dart' as FlutterWebView;
import 'package:veatre/common/net.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
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
import 'package:veatre/src/ui/transition.dart';
import 'package:veatre/src/ui/createBookmark.dart';
import 'package:veatre/src/ui/settings.dart';
import 'package:veatre/src/ui/tabViews.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/ui/sign_dialog/transaction_dialog.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/searchBar.dart';
import 'package:veatre/src/ui/apps.dart';

class WebView extends StatefulWidget {
  final int id;
  final Network network;
  final Appearance appearance;
  final String initialURL;

  WebView({
    @required this.id,
    @required this.network,
    @required this.appearance,
    @required this.initialURL,
  });

  @override
  WebViewState createState() => WebViewState();
}

class WebViewState extends State<WebView> with AutomaticKeepAliveClientMixin {
  String key;
  int id;
  bool isKeyboardVisible = false;
  bool canBack = false;
  bool canForward = false;
  bool isStartSearch = false;
  double progress = 0;
  bool canBookmarked = false;
  String _currentURL;
  Appearance _appearance;
  int bookmarkID;

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
  Activity latestActivity;

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
    updateLatestActivity();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          leading: null,
          centerTitle: true,
          automaticallyImplyLeading: false,
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
                      updateSearchBar(_currentURL, 1);
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
                                        await slide(
                                          context,
                                          CreateBookmark(
                                            documentMetaData: meta,
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
              isKeyboardVisible
                  ? SizedBox()
                  : SizedBox(
                      height: 46,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: bottomItems,
                      ),
                    ),
            ],
          ),
        ),
      ),
      onWillPop: () async {
        return !Navigator.of(context).userGestureInProgress;
      },
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

  String get _initialParamsJS {
    final genesis = Globals.genesis;
    final initialHead = Globals.head(network: widget.network);
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
              await slide(
                context,
                CreateOrImportWallet(
                  fromRouteName: MainUI.routeName,
                ),
                routeName: '/CreateOrImportWallet',
              );
            }
            return null;
          }
          dynamic result;
          if (arguments[0] == 'signTx') {
            SigningTxOptions options =
                SigningTxOptions.fromJSON(arguments[2], _currentURL);
            await _validate(options.signer);
            List<SigningTxMessage> txMessages = [];
            for (Map<String, dynamic> txMsg in arguments[1]) {
              txMessages.add(SigningTxMessage.fromJSON(txMsg));
            }
            result = await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => TransactionDialog(
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
            result = await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => SignCertificate(certMessage, options),
            );
          }
          if (result == null) {
            throw 'user cancelled';
          }
          return result.encoded;
        }
        throw 'unsupported method';
      },
    );
    return [head, net, vendor];
  }

  List<Widget> get bottomItems {
    return [
      bottomItem(
        Icons.arrow_back_ios,
        onPressed: canBack
            ? () async {
                if (canBack && controller != null) {
                  return controller.goBack();
                }
              }
            : null,
      ),
      bottomItem(
        Icons.arrow_forward_ios,
        onPressed: canForward
            ? () async {
                if (canForward && controller != null) {
                  return controller.goForward();
                }
              }
            : null,
      ),
      bottomItem(
        Icons.filter_none,
        onPressed: () async {
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
          await slide(
            context,
            TabViews(
              id: id,
              currentTabKey: key,
              url: _currentURL,
              ratio: size.width / size.height,
              appearance: _appearance,
            ),
          );
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
            FontAwesomeIcons.arrowAltCircleUp,
            onPressed: () async {
              String url = await slide(context, Activities());
              await updateLatestActivity();
              if (url != null) {
                await _handleLoad(url);
              }
            },
          ),
        ],
      ),
      bottomItem(
        FontAwesomeIcons.wallet,
        onPressed: () async {
          final url = await slide(
            context,
            ManageWallets(),
            routeName: ManageWallets.routeName,
          );
          if (url != null) {
            await _handleLoad(url);
          }
        },
      ),
    ];
  }

  Widget bottomItem(
    IconData iconData, {
    double size = 30,
    VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        iconData,
        size: size,
      ),
      color: Colors.blue,
      disabledColor: Colors.grey[300],
      onPressed: onPressed,
    );
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
              await slide(
                context,
                CreateBookmark(
                  eidtBookmarkID: bookmark.id,
                  documentMetaData: DocumentMetaData(
                    icon: bookmark.favicon,
                    title: bookmark.title,
                    url: bookmark.url,
                  ),
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

  Future<void> updateBookmarkID(String url) async {
    Bookmark bookmark = await BookmarkStorage.queryByURL(
      url,
      network: widget.network,
    );
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
    print('dispose ');
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    Globals.removeAppearanceHandler(_handleAppearanceChanged);
    Globals.removeTabHandler(_handleTabChanged);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _handleHeadChanged() async {
    final blockHeadForNetwork = Globals.blockHeadForNetwork;
    if (blockHeadForNetwork.network == widget.network && !_head.isCompleted) {
      await updateLatestActivity();
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
}
