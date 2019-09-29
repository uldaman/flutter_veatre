import 'package:flutter/material.dart';

class ModalElement extends StatelessWidget {
  ModalElement({
    Key key,
    this.prefix = '',
    this.content,
    this.onExpand,
  }) : super(key: key);

  final String prefix;
  final Widget content;
  final GestureTapCallback onExpand;

  @override
  Widget build(BuildContext context) {
    double contextWidth = MediaQuery.of(context).size.width;
    List<Widget> _children = [
      SizedBox(
        width: contextWidth * 0.25,
        child: Text(
          prefix,
          style: TextStyle(
            color: Theme.of(context).accentTextTheme.title.color,
          ),
        ),
      ),
    ];
    if (content != null) {
      _children.add(Expanded(child: content));
    }
    if (onExpand != null) {
      _children.add(
        SizedBox(
          width: contextWidth * 0.05,
          child: Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).accentTextTheme.title.color,
            size: 15,
          ),
        ),
      );
    } else {
      _children.add(
        SizedBox(width: contextWidth * 0.05),
      );
    }
    return SizedBox(
      // height: 50,
      child: Row(
        children: _children,
      ),
    );
  }
}
