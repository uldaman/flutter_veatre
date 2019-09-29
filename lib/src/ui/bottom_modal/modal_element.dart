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
    List<Widget> _children = [
      Expanded(
        flex: 4,
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
          flex: 9,
          child: content,
        ),
      );
    }
    if (onExpand != null) {
      _children.add(
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).accentTextTheme.title.color,
                size: 15,
              ),
            ],
          ),
        ),
      );
    } else {
      _children.add(
        Spacer(flex: 1),
      );
    }
    return Row(
      children: _children,
    );
  }
}
