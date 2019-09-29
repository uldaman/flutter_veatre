import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BottomModal extends StatelessWidget {
  BottomModal({
    Key key,
    @required this.title,
    this.bottomActionButton,
    this.elements = const <Widget>[],
  }) : super(key: key);

  final String title;
  final Widget bottomActionButton;
  final List<Widget> elements;
  final double _screenPercentage = 0.8;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _screenPercentage,
      maxChildSize: _screenPercentage,
      minChildSize: _screenPercentage,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 26),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildChildren(context),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    List<Widget> _children = [];
    _children.add(_buildSlider(context));
    _children.add(SizedBox(height: 18));
    _children.add(_buildTitle(context));
    _children.add(_buildDivider());
    elements.forEach((element) {
      _children.add(element);
      _children.add(_buildDivider());
    });
    if (bottomActionButton != null) {
      _children.add(_buildBottomActionButton());
    }
    return _children;
  }

  Widget _buildDivider() {
    return Column(
      children: <Widget>[
        SizedBox(height: 8),
        Divider(thickness: 1),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSlider(BuildContext context) {
    return Row(
      children: <Widget>[
        Spacer(
          flex: 3,
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 3,
            decoration: ShapeDecoration(
              shape: StadiumBorder(),
              color: Theme.of(context).accentTextTheme.title.color,
            ),
          ),
        ),
        Spacer(
          flex: 3,
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: Navigator.of(context).pop,
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 17,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButton() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: bottomActionButton,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
