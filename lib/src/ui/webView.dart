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
import 'package:veatre/src/ui/signCertificate.dart';
import 'package:webview_flutter/webview_flutter.dart' as FlutterWebView;
import 'package:veatre/common/net.dart';
import 'package:veatre/common/globals.dart';
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
  final bool offstage;
  final String tabKey;
  WebView({
    @required this.id,
    @required this.network,
    @required this.appearance,
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
  bool isKeyboardVisible = false;
  bool canBack = false;
  bool canForward = false;
  bool isStartSearch = false;
  double progress = 0;
  bool canBookmarked = false;
  bool _offstage;
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
        MaterialCommunityIcons.getIconData('magnify'),
        size: 20,
      ),
    ),
  );
  Activity latestActivity;
  bool btnEnabled = true;

  @override
  void initState() {
    super.initState();
    id = widget.id;
    key = widget.tabKey;
    _offstage = widget.offstage;
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
    return Offstage(
      child: WillPopScope(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
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
                                  ? MaterialCommunityIcons.getIconData(
                                      'bookmark-plus-outline',
                                    )
                                  : MaterialCommunityIcons.getIconData(
                                      'bookmark-plus',
                                    ),
                              size: 20,
                            ),
                            disabledColor: Theme.of(context).iconTheme.color,
                            color: Theme.of(context).primaryIconTheme.color,
                            onPressed: _currentURL == Globals.initialURL
                                ? null
                                : bookmarkID == null
                                    ? () async {
                                        final meta = await metaData;
                                        if (meta != null) {
                                          Navigator.of(context).push(
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
                                        await BookmarkStorage.delete(
                                            bookmarkID);
                                        await updateBookmarkID(_currentURL);
                                      },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            MaterialCommunityIcons.getIconData(
                                'settings-outline'),
                            size: 20,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return Settings();
                                },
                                settings:
                                    RouteSettings(name: Settings.routeName),
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
                        height: 1,
                        child: LinearProgressIndicator(
                          value: progress,
                          valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).primaryColor),
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
                        Offstage(
                          child: appView,
                          offstage: !(_currentURL == Globals.initialURL ||
                              isStartSearch == true),
                        ),
                      ],
                    ),
                  ),
                ),
                isKeyboardVisible
                    ? SizedBox()
                    : SizedBox(
                        height: 56,
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
      ),
      offstage: _offstage,
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
        onDelegateError: (String error) {
          controller.loadHTMLString('''
            <html>
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
          ''', _currentURL);
        },
      );

  String get _initialParamsJS {
    final genesis = Globals.genesis(widget.network);
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
                      MaterialCommunityIcons.getIconData('refresh'),
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
      return showDialog(
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
      return showDialog(SignCertificate(certMessage, options));
    }
    throw 'unsupported method';
  }

  Future<dynamic> showDialog(Widget dialog) async {
    dynamic result = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => dialog,
    );
    if (result == null) throw 'user cancelled';
    return result.encoded;
  }

  List<Widget> get bottomItems {
    final snapshotLength = WebViews.snapshots(network: widget.network).length;
    final tabLength = snapshotLength == 0
        ? 1
        : snapshotLength +
            ((Globals.tabValue.stage == TabStage.Created ||
                    Globals.tabValue.stage == TabStage.Coverred)
                ? 1
                : 0);
    return [
      Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: bottomItem(
          MaterialCommunityIcons.getIconData('chevron-left'),
          onPressed: canBack
              ? () async {
                  if (canBack && controller != null) {
                    return controller.goBack();
                  }
                }
              : null,
        ),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: bottomItem(
          MaterialCommunityIcons.getIconData('chevron-right'),
          onPressed: canForward
              ? () async {
                  if (canForward && controller != null) {
                    return controller.goForward();
                  }
                }
              : null,
        ),
      ),
      bottomItem(
        MaterialCommunityIcons.getIconData(
          tabLength > 9
              ? 'numeric-9-plus-box-multiple-outline'
              : 'numeric-$tabLength-box-multiple-outline',
        ),
        size: 28,
        onPressed: () async {
          WebViews.updateSnapshot(
            id,
            key,
            widget.network,
            title: title,
            data: takeScreenshot(),
            url: _currentURL,
          );
          final size = captureKey.currentContext.size;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabViews(
                id: id,
                currentTabKey: key,
                url: _currentURL,
                ratio: size.width / size.height,
                appearance: _appearance,
              ),
              fullscreenDialog: true,
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
            MaterialCommunityIcons.getIconData('arrow-up-bold-circle-outline'),
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
        MaterialCommunityIcons.getIconData('cards'),
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
      color: Theme.of(context).primaryColor,
      disabledColor: Theme.of(context).primaryTextTheme.display3.color,
      onPressed: onPressed != null
          ? () async {
              if (btnEnabled) {
                btnEnabled = false;
                await onPressed();
                btnEnabled = true;
              }
            }
          : null,
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
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).primaryTextTheme.display1.color,
            fontSize: 17,
          ),
        ),
      ),
      actions: <Widget>[
        sheet(
          FlatButton(
            child: Text(
              'Copy URL',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 17,
              ),
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
              style: TextStyle(
                  color: Theme.of(context).primaryColor, fontSize: 17),
            ),
            onPressed: () async {
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
        ),
        sheet(
          FlatButton(
            child: Text(
              'Remove',
              style: TextStyle(
                color: Theme.of(context).errorColor,
                fontSize: 17,
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
            style:
                TextStyle(color: Theme.of(context).primaryColor, fontSize: 17),
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
      if (tabValue.stage == TabStage.Created ||
          tabValue.stage == TabStage.Removed) {
        setState(() {});
      }
      key = tabValue.tabKey;
      if (tabValue.stage == TabStage.RemoveAll) {
        setState(() {
          _offstage = true;
        });
        await controller.loadHTMLString("", null);
      } else {
        if (tabValue.id == id) {
          if (tabValue.stage == TabStage.Removed ||
              tabValue.stage == TabStage.Coverred) {
            await controller.loadHTMLString("", null);
          } else if (tabValue.stage == TabStage.SelectedInAlive) {
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
}
