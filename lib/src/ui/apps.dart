import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/models/dapp.dart';
import 'package:veatre/src/api/dappAPI.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:veatre/src/storage/configStorage.dart';

typedef onAppSelectedCallback = Future<void> Function(DApp app);
typedef onBookmarkSelectedCallback = Future<void> Function(Bookmark bookmark);
typedef onBookmarkLongPressedCallback = Future<void> Function(
    Bookmark bookmark);

class DApps extends StatefulWidget {
  final onAppSelectedCallback onAppSelected;
  final onBookmarkSelectedCallback onBookmarkSelected;
  final onBookmarkLongPressedCallback onBookmarkLongPressed;
  final Network network;

  DApps({
    this.onAppSelected,
    this.onBookmarkSelected,
    this.onBookmarkLongPressed,
    @required this.network,
  });

  @override
  DAppsState createState() {
    return DAppsState();
  }
}

class DAppsState extends State<DApps> {
  final int crossAxisCount = 4;
  final double crossAxisSpacing = 15;
  final double mainAxisSpacing = 15;
  List<Bookmark> bookmarks = [];
  List<DApp> recommendedApps = Globals.apps;

  @override
  void initState() {
    super.initState();
    updateBookmarks();
    syncApps();
    Globals.addBookmarkHandler(_handleBookmark);
  }

  Future<void> _handleBookmark() async {
    if (mounted && Globals.bookmark.network == Globals.network) {
      await updateBookmarks();
    }
  }

  Future<void> syncApps() async {
    if (Globals.apps.length == 0) {
      try {
        Globals.apps = await DAppAPI.list();
      } catch (e) {
        print("syncApps error: $e");
      }
      if (mounted) {
        setState(() {
          recommendedApps = Globals.apps;
        });
      }
    }
  }

  Future<void> updateBookmarks() async {
    List<Bookmark> bookmarks =
        await BookmarkStorage.queryAll(network: widget.network);
    if (mounted) {
      setState(() {
        this.bookmarks = bookmarks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(0),
        children: <Widget>[
          bookmarks.length > 0
              ? Padding(
                  child: Text(
                    'Bookmarks',
                    style: Theme.of(context).primaryTextTheme.subtitle,
                  ),
                  padding: EdgeInsets.all(15),
                )
              : SizedBox(),
          bookmarks.length > 0 ? bookmarkApps : SizedBox(),
          recommendedApps.length > 0
              ? Padding(
                  child: Text(
                    'Recommends',
                    style: Theme.of(context).primaryTextTheme.subtitle,
                  ),
                  padding: EdgeInsets.all(15),
                )
              : SizedBox(),
          recommendedApps.length > 0 ? recommendApps : SizedBox(),
        ],
      ),
    );
  }

  Widget get recommendApps => GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(15),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: recommendedApps.length,
        itemBuilder: (context, index) {
          return Column(
            children: <Widget>[
              SizedBox(
                width: _size,
                child: FlatButton(
                  onPressed: () async {
                    if (widget.onAppSelected != null) {
                      widget.onAppSelected(recommendedApps[index]);
                    }
                  },
                  child: image(recommendedApps[index].logo),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  recommendedApps[index].name ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          );
        },
      );

  double get _size =>
      (MediaQuery.of(context).size.width -
          crossAxisCount * crossAxisSpacing -
          40) /
      crossAxisCount;

  Widget get bookmarkApps => GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(15),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: 0.9,
        ),
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            child: Column(
              children: <Widget>[
                Stack(
                  overflow: Overflow.visible,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: 18,
                        ),
                        SizedBox(
                          width: _size - 36,
                          height: _size - 36,
                          child: image(bookmarks[index].favicon),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    bookmarks[index].title ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: Theme.of(context).primaryTextTheme.display2.color,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            onLongPressStart: (detail) async {
              if (widget.onBookmarkLongPressed != null) {
                widget.onBookmarkLongPressed(bookmarks[index]);
              }
            },
            onTapUp: (detail) async {
              if (widget.onBookmarkSelected != null) {
                widget.onBookmarkSelected(bookmarks[index]);
              }
            },
          );
        },
      );
  CachedNetworkImage image(String url) => CachedNetworkImage(
        fit: BoxFit.fill,
        imageUrl: url,
        placeholder: (context, url) => SizedBox.fromSize(
          size: Size.square(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) {
          print('CachedNetworkImage error: $error');
          return Icon(
            Icons.star,
            color: Colors.blue,
            size: _size - 36,
          );
        },
      );

  @override
  void dispose() {
    Globals.removeBookmarkHandler(_handleBookmark);
    super.dispose();
  }
}
