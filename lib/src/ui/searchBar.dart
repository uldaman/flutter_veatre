import 'package:flutter/material.dart';

class SearchBarValue {
  Widget leftView;
  Widget rightView;
  String defautText;
  String submitedText;
  bool shouldCancelInput;

  SearchBarValue({
    Widget leftView,
    Widget rightView,
    String defautText,
    String submitedText,
    bool shouldCancelInput,
  }) {
    this.leftView = leftView;
    this.rightView = rightView;
    this.defautText = defautText ?? 'Search';
    this.submitedText = submitedText ?? '';
    this.shouldCancelInput = shouldCancelInput ?? false;
  }
}

class SearchBarController extends ValueNotifier<SearchBarValue> {
  SearchBarController(SearchBarValue value) : super(value);

  void valueWith({
    Widget leftView,
    Widget rightView,
    String defautText,
    String submitedText,
    bool shouldCancelInput,
  }) {
    this.value = SearchBarValue(
      leftView: leftView ?? this.value.leftView,
      rightView: rightView,
      defautText: defautText ?? this.value.defautText,
      submitedText: submitedText ?? this.value.submitedText,
      shouldCancelInput: shouldCancelInput ?? this.value.shouldCancelInput,
    );
  }
}

class SearchBar extends StatefulWidget {
  final SearchBarController searchBarController;
  final void Function(String value) onSubmitted;
  final Future<void> Function() onFocus;

  SearchBar({
    this.searchBarController,
    this.onSubmitted,
    this.onFocus,
  });

  @override
  SearchBarState createState() => SearchBarState();
}

class SearchBarState extends State<SearchBar>
    with SingleTickerProviderStateMixin {
  bool showTextField = false;
  Widget leftView;
  Widget rightView;
  String defautText;
  final _searchTextEditingController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _handleValueChanged();
    _focusNode.addListener(_handleFocus);
    widget.searchBarController.addListener(_handleValueChanged);
    super.initState();
  }

  void _handleFocus() async {
    if (_focusNode.hasFocus) {
      final text = _searchTextEditingController.text;
      _searchTextEditingController.value =
          _searchTextEditingController.value.copyWith(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      );
      if (widget.onFocus != null) {
        await widget.onFocus();
      }
    }
  }

  void _handleValueChanged() async {
    SearchBarValue value = widget.searchBarController.value;
    setState(() {
      leftView = value.leftView;
      rightView = value.rightView;
      defautText = value.defautText;
      if (showTextField == value.shouldCancelInput) {
        showTextField = !value.shouldCancelInput;
      }
      if (!showTextField) {
        _searchTextEditingController.value =
            _searchTextEditingController.value.copyWith(
          text: value.submitedText,
          selection: _searchTextEditingController.value.selection,
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    widget.searchBarController.removeListener(_handleValueChanged);
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
      decoration: InputDecoration(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.only(bottom: 8),
        hintText: 'Search',
      ),
      focusNode: _focusNode,
      autofocus: true,
      enableInteractiveSelection: true,
      textInputAction: TextInputAction.go,
      onSubmitted: (text) async {
        setState(() {
          showTextField = false;
        });
        if (widget.onSubmitted != null) {
          widget.onSubmitted(text);
        }
      },
    );
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Card(
        color: Colors.grey[300],
        elevation: 0,
        margin: EdgeInsets.all(0),
        child: Row(
          children: <Widget>[
            leftView == null
                ? SizedBox()
                : Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: leftView,
                  ),
            Expanded(
              child: showTextField
                  ? Padding(
                      padding: EdgeInsets.only(left: 5, top: 0),
                      child: searchTextField,
                    )
                  : FlatButton(
                      padding: EdgeInsets.only(left: 5),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          defautText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.title.color,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          showTextField = true;
                        });
                      },
                    ),
            ),
            showTextField
                ? IconButton(
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.grey,
                      size: 14,
                    ),
                    onPressed: () {
                      _searchTextEditingController.clear();
                    },
                  )
                : rightView == null ? SizedBox() : rightView,
          ],
        ),
      ),
    );
  }
}
