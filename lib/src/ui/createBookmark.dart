import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreateBookmark extends StatefulWidget {
  final Bookmark bookmark;
  CreateBookmark({this.bookmark});

  @override
  CreateBookmarkState createState() {
    return CreateBookmarkState();
  }
}

class CreateBookmarkState extends State<CreateBookmark> {
  TextEditingController titleEditingController;

  @override
  void initState() {
    super.initState();
    titleEditingController = TextEditingController(text: widget.bookmark.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[180],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Bookmark'),
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            child: Text('Save'),
            onPressed: () async {
              final title = titleEditingController.text;
              Bookmark bookmark = Bookmark(
                favicon: widget.bookmark.favicon,
                title: title,
                url: widget.bookmark.url,
                net: widget.bookmark.net,
              );
              await BookmarkStorage.insert(bookmark);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Container(
        color: Colors.white,
        margin: EdgeInsets.only(top: 20),
        child: SizedBox(
          height: 100,
          child: Row(
            children: <Widget>[
              Padding(
                padding:
                    EdgeInsets.only(left: 15, right: 15, bottom: 20, top: 20),
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: widget.bookmark.favicon != null
                      ? CachedNetworkImage(
                          fit: BoxFit.fill,
                          imageUrl: widget.bookmark.favicon ?? '',
                          placeholder: (context, url) => SizedBox.fromSize(
                            size: Size.square(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            print('CachedNetworkImage error: $error');
                            return Image.asset("assets/blank.png");
                          },
                        )
                      : SizedBox(),
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 10, right: 15),
                            child: SizedBox(
                              height: 60,
                              child: TextField(
                                autofocus: true,
                                style: TextStyle(fontSize: 14),
                                maxLines: 1,
                                controller: titleEditingController,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 5, right: 15),
                            child: Text(
                              widget.bookmark.url,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
