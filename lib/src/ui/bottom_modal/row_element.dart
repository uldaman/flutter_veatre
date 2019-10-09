import 'package:flutter/material.dart';

class RowElement extends StatelessWidget {
  RowElement({
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
    List<Widget> _children = [
      SizedBox(
        width: 88,
        child: Text(
          prefix,
          style: TextStyle(
            color: Theme.of(context).accentTextTheme.title.color,
          ),
        ),
      ),
    ];
    if (content != null) {
      _children.add(
        Expanded(
          child: content,
        ),
      );
    }
    if (onExpand != null) {
      _children.add(
        SizedBox(
          width: 25,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              GestureDetector(
                onTap: onExpand,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).accentTextTheme.title.color,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      _children.add(
        SizedBox(width: 25),
      );
    }
    return Row(
      children: _children,
    );
  }
}
