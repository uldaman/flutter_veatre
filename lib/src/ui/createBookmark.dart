import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';

class CreateBookmark extends StatefulWidget {
  final int eidtBookmarkID;
  final DocumentMetaData documentMetaData;
  CreateBookmark({this.documentMetaData, this.eidtBookmarkID});

  @override
  CreateBookmarkState createState() {
    return CreateBookmarkState();
  }
}

class CreateBookmarkState extends State<CreateBookmark> {
  TextEditingController titleEditingController;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
    titleEditingController =
        TextEditingController(text: widget.documentMetaData.title);
  }

  void _handleFocus() {
    if (_focusNode.hasFocus) {
      final text = titleEditingController.text;
      titleEditingController.value = titleEditingController.value.copyWith(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: FlatButton(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          padding: EdgeInsets.all(0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Close',
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Bookmark'),
        backgroundColor: Theme.of(context).backgroundColor,
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Save',
            ),
            onPressed: () async {
              Bookmark bookmark = Bookmark(
                favicon: widget.documentMetaData.icon,
                title: titleEditingController.text,
                url: widget.documentMetaData.url,
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
                            padding: EdgeInsets.only(top: 8, right: 15),
                            child: Container(
                              height: 60,
                              child: TextField(
                                autofocus: true,
                                focusNode: _focusNode,
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
                            padding:
                                EdgeInsets.only(top: 5, left: 10, right: 15),
                            child: Text(
                              widget.documentMetaData.url,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .display2
                                      .color),
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
