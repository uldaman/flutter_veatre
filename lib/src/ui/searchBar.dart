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
  final BuildContext context;

  final SearchBarController searchBarController;
  final void Function(String value) onSubmitted;
  final Future<void> Function() onCancelInput;
  final Future<void> Function() onStartSearch;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onStop;

  SearchBar(
    this.context, {
    this.searchBarController,
    this.onSubmitted,
    this.onCancelInput,
    this.onStartSearch,
    this.onRefresh,
    this.onStop,
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
  TextEditingController _searchTextEditingController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    double width = MediaQuery.of(widget.context).size.width;
    animation = new Tween(begin: width - 32, end: width - 120)
        .animate(animationController);
    _handleValueChanged();
    widget.searchBarController.addListener(_handleValueChanged);
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (_focusNode.hasFocus) {
      _searchTextEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchTextEditingController.text.length,
      );
    }
  }

  void _handleValueChanged() async {
    SearchBarValue value = widget.searchBarController.value;
    setState(() {
      if (value.submitedText != '' && showTextField) {
        showTextField = false;
        animationController.reverse();
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
    _focusNode.removeListener(_handleFocus);
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextField searchTextField = TextField(
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).textTheme.body1.color,
      ),
      controller: _searchTextEditingController,
      focusNode: _focusNode,
      decoration: InputDecoration(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        hintText: 'Search',
      ),
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
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: Card(
                    margin: EdgeInsets.all(0),
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
                                                          color:
                                                              Theme.of(context)
                                                                  .iconTheme
                                                                  .color,
                                                        ),
                                                  Text(
                                                    defautText,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .title
                                                          .color,
                                                      fontSize: 14,
                                                    ),
                                                  ),
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
                                                          if (widget
                                                                  .onRefresh !=
                                                              null) {
                                                            await widget
                                                                .onStop();
                                                          }
                                                        },
                                                      )
                                                    : IconButton(
                                                        icon: Icon(
                                                          Icons.refresh,
                                                          color:
                                                              Colors.blue[500],
                                                          size: 20,
                                                        ),
                                                        onPressed: () async {
                                                          if (widget
                                                                  .onRefresh !=
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
                                        height: 4,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              left: 5, right: 5),
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
                  ),
                );
              },
            ),
            !showTextField
                ? SizedBox()
                : FlatButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).accentTextTheme.title.color,
                        fontSize: 12,
                      ),
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
  }
}
