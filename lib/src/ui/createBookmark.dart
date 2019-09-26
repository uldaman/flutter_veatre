import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class CreateBookmark extends StatefulWidget {
  final int eidtBookmarkID;
  final DocumentMetaData documentMetaData;
  final Network network;
  CreateBookmark({this.documentMetaData, this.network, this.eidtBookmarkID});

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
    titleEditingController =
        TextEditingController(text: widget.documentMetaData.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('Bookmark'),
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).textTheme.body1.color,
              ),
            ),
            onPressed: () async {
              Bookmark bookmark = Bookmark(
                favicon: widget.documentMetaData.icon,
                title: titleEditingController.text,
                url: widget.documentMetaData.url,
                network: widget.network,
              );
              if (widget.eidtBookmarkID != null) {
                await BookmarkStorage.update(
                    widget.eidtBookmarkID, bookmark.encoded);
              } else {
                await BookmarkStorage.insert(bookmark);
              }
              Globals.updateBookmark(bookmark);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Card(
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
                  child: widget.documentMetaData.icon != null
                      ? CachedNetworkImage(
                          fit: BoxFit.fill,
                          imageUrl: widget.documentMetaData.icon ?? '',
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
                              size: 60,
                            );
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
                            child: Container(
                              height: 60,
                              child: TextField(
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).textTheme.body1.color,
                                ),
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
                              widget.documentMetaData.url,
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
