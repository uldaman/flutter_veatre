import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BottomModal extends StatelessWidget {
  BottomModal({
    Key key,
    @required this.title,
    this.bottomActionButton,
    this.content,
  }) : super(key: key);

  final String title;
  final Widget bottomActionButton;
  final Widget content;
  final double _screenPercentage = 0.8;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _screenPercentage,
      maxChildSize: _screenPercentage,
      minChildSize: _screenPercentage,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.only(top: 8, bottom: 34, left: 26, right: 26),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
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
    if (content != null) {
      _children.add(Expanded(child: content));
    } else {
      _children.add(Spacer());
    }
    if (bottomActionButton != null) {
      _children.add(bottomActionButton);
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
            decoration: ShapeDecoration(shape: StadiumBorder()),
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
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: Navigator.of(context).pop,
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 17,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
