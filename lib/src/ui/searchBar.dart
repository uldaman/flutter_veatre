import 'package:flutter/material.dart';

class SearchBarValue {
  IconData icon;
  String defautText;
  String submitedText;
  double progress = 0;
  bool shouldHideRightItem;

  SearchBarValue({
    double progress,
    IconData icon,
    String defautText,
    String submitedText,
    bool shouldHideRightItem,
  }) {
    this.progress = progress ?? 0;
    this.icon = icon;
    this.defautText = defautText ?? 'Search';
    this.submitedText = submitedText ?? '';
    this.shouldHideRightItem = shouldHideRightItem ?? false;
  }
}

class SearchBarController extends ValueNotifier<SearchBarValue> {
  SearchBarController(SearchBarValue value) : super(value);

  void valueWith({
    double progress,
    IconData icon,
    String defautText,
    String submitedText,
    bool shouldHideRightItem,
  }) {
    this.value = SearchBarValue(
      progress: progress ?? this.value.progress,
      icon: icon ?? this.value.icon,
      defautText: defautText ?? this.value.defautText,
      submitedText: submitedText ?? this.value.submitedText,
      shouldHideRightItem:
          shouldHideRightItem ?? this.value.shouldHideRightItem,
    );
  }
}

class SearchBar extends StatefulWidget {
  final SearchBarController searchBarController;
  final void Function(String value) onSubmitted;
  final Future<void> Function() onCancelInput;
  final Future<void> Function() onStartSearch;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onStop;
  final double width;

  SearchBar({
    this.searchBarController,
    this.onSubmitted,
    this.onCancelInput,
    this.onStartSearch,
    this.onRefresh,
    this.onStop,
    this.width,
  });

  @override
  SearchBarState createState() => SearchBarState();
}

class SearchBarState extends State<SearchBar>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;
  Animation<double> animation;

  bool showTextField = false;
  double progress;
  IconData icon;
  String defautText;
  bool shouldHideRightItem;
  final _focusNode = FocusNode();
  TextEditingController _searchTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    animation = new Tween(begin: widget.width - 32, end: widget.width - 120)
        .animate(animationController);

    _handleValueChanged();
    widget.searchBarController.addListener(_handleValueChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _searchTextEditingController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchTextEditingController.text.length,
        );
      }
    });
  }

  void _handleValueChanged() async {
    SearchBarValue value = widget.searchBarController.value;
    setState(() {
      if (value.submitedText != '' && showTextField) {
        showTextField = false;
      }
    });
    setState(() {
      progress = value.progress;
      icon = value.icon;
      defautText = value.defautText;
      shouldHideRightItem = value.shouldHideRightItem;
      _searchTextEditingController.text = value.submitedText;
    });
  }

  @override
  void dispose() {
    widget.searchBarController.removeListener(_handleValueChanged);
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextField searchTextField = TextField(
      style: TextStyle(fontSize: 14),
      controller: _searchTextEditingController,
      focusNode: _focusNode,
      decoration: InputDecoration(border: InputBorder.none, hintText: 'Search'),
      autofocus: true,
      enableInteractiveSelection: true,
      textInputAction: TextInputAction.go,
      onSubmitted: (text) async {
        setState(() {
          showTextField = false;
        });
        await animationController.reverse();
        if (widget.onSubmitted != null) {
          widget.onSubmitted(text);
        }
      },
    );
    return Wrap(
      children: <Widget>[
        Row(
          children: <Widget>[
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  width: animation.value,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: !showTextField
                      ? ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                          child: Wrap(
                            children: <Widget>[
                              Container(
                                height: 40,
                                child: Stack(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: FlatButton(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                icon == null
                                                    ? SizedBox()
                                                    : Icon(
                                                        icon,
                                                        size: 16,
                                                      ),
                                                Text(defautText),
                                              ],
                                            ),
                                            onPressed: () async {
                                              await animationController
                                                  .forward();
                                              setState(() {
                                                showTextField = true;
                                              });
                                              if (widget.onStartSearch !=
                                                  null) {
                                                await widget.onStartSearch();
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                    ),
                                    shouldHideRightItem
                                        ? SizedBox()
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: <Widget>[
                                              !showTextField && progress < 1
                                                  ? IconButton(
                                                      icon: Icon(
                                                        Icons.close,
                                                        color: Colors.grey,
                                                        size: 20,
                                                      ),
                                                      onPressed: () async {
                                                        if (widget.onRefresh !=
                                                            null) {
                                                          await widget.onStop();
                                                        }
                                                      },
                                                    )
                                                  : IconButton(
                                                      icon: Icon(
                                                        Icons.refresh,
                                                        color: Colors.blue[500],
                                                        size: 20,
                                                      ),
                                                      onPressed: () async {
                                                        if (widget.onRefresh !=
                                                            null) {
                                                          await widget
                                                              .onRefresh();
                                                        }
                                                      },
                                                    ),
                                            ],
                                          )
                                  ],
                                ),
                              ),
                              !showTextField && progress < 1 && progress > 0
                                  ? SizedBox(
                                      height: 2,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.only(left: 5, right: 5),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: searchTextField,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchTextEditingController.clear();
                              },
                            )
                          ],
                        ),
                );
              },
            ),
            !showTextField
                ? SizedBox()
                : FlatButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                    onPressed: () async {
                      setState(() {
                        showTextField = false;
                      });
                      await animationController.reverse();
                      if (widget.onCancelInput != null) {
                        await widget.onCancelInput();
                      }
                    },
                  ),
          ],
        ),
      ],
    );
    // return Wrap(
    //   children: <Widget>[
    //     Row(
    //       children: <Widget>[
    //         AnimatedContainer(
    //           duration: Duration(milliseconds: 80),
    //           child: !isTexting
    //               ? Container(
    //                   height: 40,
    //                   child: Stack(
    //                     children: <Widget>[
    //                       Row(
    //                         children: <Widget>[
    //                           Expanded(
    //                             child: FlatButton(
    //                               child: Row(
    //                                 mainAxisAlignment: MainAxisAlignment.center,
    //                                 children: <Widget>[
    //                                   icon == null
    //                                       ? SizedBox()
    //                                       : Icon(
    //                                           icon,
    //                                           size: 16,
    //                                         ),
    //                                   Text(defautText),
    //                                 ],
    //                               ),
    //                               onPressed: () async {
    //                                 setState(() {
    //                                   searchBarWidth = fullWidth - 85;
    //                                 });
    //                                 await Future.delayed(
    //                                     Duration(milliseconds: 100));
    //                                 setState(() {
    //                                   isTexting = true;
    //                                 });
    //                                 if (widget.onStartSearch != null) {
    //                                   await widget.onStartSearch();
    //                                 }
    //                               },
    //                             ),
    //                           ),
    //                         ],
    //                         mainAxisAlignment: MainAxisAlignment.center,
    //                       ),
    //                       shouldHideRightItem
    //                           ? SizedBox()
    //                           : Row(
    //                               mainAxisAlignment: MainAxisAlignment.end,
    //                               children: <Widget>[
    //                                 !isTexting && progress < 1
    //                                     ? IconButton(
    //                                         icon: Icon(
    //                                           Icons.close,
    //                                           color: Colors.grey,
    //                                           size: 20,
    //                                         ),
    //                                         onPressed: () async {
    //                                           if (widget.onRefresh != null) {
    //                                             await widget.onStop();
    //                                           }
    //                                         },
    //                                       )
    //                                     : IconButton(
    //                                         icon: Icon(
    //                                           Icons.refresh,
    //                                           color: Colors.blue[500],
    //                                           size: 20,
    //                                         ),
    //                                         onPressed: () async {
    //                                           if (widget.onRefresh != null) {
    //                                             await widget.onRefresh();
    //                                           }
    //                                         },
    //                                       ),
    //                               ],
    //                             )
    //                     ],
    //                   ),
    //                 )
    //               : Row(
    //                   mainAxisAlignment: MainAxisAlignment.end,
    //                   children: <Widget>[
    //                     Expanded(
    //                       child: Padding(
    //                         padding: EdgeInsets.only(left: 10),
    //                         child: searchTextField,
    //                       ),
    //                     ),
    //                     IconButton(
    //                       icon: Icon(
    //                         Icons.cancel,
    //                         color: Colors.grey,
    //                         size: 20,
    //                       ),
    //                       onPressed: () {
    //                         _searchTextEditingController.clear();
    //                       },
    //                     )
    //                   ],
    //                 ),
    //           width: searchBarWidth,
    //           height: 42,
    //           decoration: BoxDecoration(
    //             color: Colors.grey[300],
    //             borderRadius: BorderRadius.all(
    //               Radius.circular(10),
    //             ),
    //           ),
    //         ),
    //         !isTexting
    //             ? SizedBox()
    //             : FlatButton(
    //                 padding: EdgeInsets.all(0),
    //                 child: Text(
    //                   'Cancel',
    //                   style: TextStyle(color: Colors.blue, fontSize: 12),
    //                 ),
    //                 onPressed: () async {
    //                   setState(() {
    //                     searchBarWidth = MediaQuery.of(context).size.width - 35;
    //                     isTexting = false;
    //                   });
    //                   if (widget.onCancelInput != null) {
    //                     await widget.onCancelInput();
    //                   }
    //                 },
    //               ),
    //       ],
    //     ),
    //     !isTexting && progress < 1 && progress > 0
    //         ? SizedBox(
    //             height: 2,
    //             child: Padding(
    //               padding: EdgeInsets.only(left: 8, right: 8),
    //               child: LinearProgressIndicator(
    //                 value: progress,
    //                 backgroundColor: Colors.transparent,
    //               ),
    //             ),
    //           )
    //         : SizedBox(),
    //   ],
    // );
  }
}
