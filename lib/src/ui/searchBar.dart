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
  final BuildContext context;

  final SearchBarController searchBarController;
  final void Function(String value) onSubmitted;
  final Future<void> Function() onStartSearch;

  SearchBar(
    this.context, {
    this.searchBarController,
    this.onSubmitted,
    this.onStartSearch,
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
  TextEditingController _searchTextEditingController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _handleValueChanged();
    widget.searchBarController.addListener(_handleValueChanged);
  }

  void _handleValueChanged() async {
    SearchBarValue value = widget.searchBarController.value;
    setState(() {
      if (value.submitedText != '' && showTextField) {
        showTextField = false;
      }
    });
    setState(() {
      leftView = value.leftView;
      rightView = value.rightView;
      defautText = value.defautText;
      showTextField = !value.shouldCancelInput;
      _searchTextEditingController.text = value.submitedText;
    });
  }

  @override
  void dispose() {
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
        hintText: 'Search',
      ),
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
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Card(
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
                      padding: EdgeInsets.only(left: 5),
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
                        if (widget.onStartSearch != null) {
                          await widget.onStartSearch();
                        }
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
