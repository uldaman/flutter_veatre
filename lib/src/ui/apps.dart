import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/api/DappAPI.dart';
import 'package:veatre/src/models/dapp.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';

typedef onAppSelectedCallback = Future<void> Function(DApp app);
typedef onBookmarkSelectedCallback = Future<void> Function(Bookmark bookmark);

class DApps extends StatefulWidget {
  final Network network;
  final onAppSelectedCallback onAppSelected;
  final onBookmarkSelectedCallback onBookmarkSelected;

  DApps({
    this.network,
    this.onAppSelected,
    this.onBookmarkSelected,
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
  List<DApp> recomendedApps = Globals.apps;

  int editBookmark;

  @override
  void initState() {
    super.initState();
    updateBookmarks();
    syncApps();
  }

  Future<void> syncApps() async {
    List<DApp> apps = await DAppAPI.list();
    Globals.apps = apps;
    if (mounted) {
      setState(() {
        recomendedApps = apps;
      });
    }
  }

  Future<void> updateBookmarks() async {
    List<Bookmark> bookmarks = await BookmarkStorage.queryAll(widget.network);
    if (mounted) {
      setState(() {
        this.bookmarks = bookmarks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: GestureDetector(
        child: ListView(
          padding: EdgeInsets.all(0),
          children: <Widget>[
            bookmarks.length > 0
                ? Padding(
                    child: Text(
                      'Bookmarks',
                      style: Theme.of(context).accentTextTheme.title,
                    ),
                    padding: EdgeInsets.all(15),
                  )
                : SizedBox(),
            bookmarks.length > 0 ? bookmarkApps : SizedBox(),
            recomendedApps.length > 0
                ? Padding(
                    child: Text(
                      'Recomends',
                      style: Theme.of(context).accentTextTheme.title,
                    ),
                    padding: EdgeInsets.all(15),
                  )
                : SizedBox(),
            recomendedApps.length > 0 ? recomendApps : SizedBox(),
          ],
        ),
        onTap: () {
          setState(() {
            editBookmark = null;
          });
        },
      ),
    );
  }

  Widget get recomendApps => GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(15),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: recomendedApps.length,
        itemBuilder: (context, index) {
          return Column(
            children: <Widget>[
              SizedBox(
                width: _size,
                child: FlatButton(
                  onPressed: () async {
                    if (widget.onAppSelected != null) {
                      widget.onAppSelected(recomendedApps[index]);
                    }
                  },
                  child: image(recomendedApps[index].logo),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  recomendedApps[index].name ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Theme.of(context).accentTextTheme.title.color,
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
                    editBookmark != null && editBookmark == bookmarks[index].id
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              IconButton(
                                icon: Icon(
                                  Icons.cancel,
                                  color: Colors.grey[500],
                                  size: 18,
                                ),
                                onPressed: () async {
                                  await BookmarkStorage.delete(editBookmark);
                                  editBookmark = null;
                                  await updateBookmarks();
                                },
                              ),
                            ],
                          )
                        : SizedBox()
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    bookmarks[index].title ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            onLongPressStart: (detail) async {
              setState(() {
                editBookmark = bookmarks[index].id;
              });
            },
            onTap: () async {
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
}
