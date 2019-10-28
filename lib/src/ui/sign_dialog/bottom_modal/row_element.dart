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
    return Row(
      children: <Widget>[
        SizedBox(
          width: 88,
          child: Text(
            prefix,
            style: TextStyle(
              color: Theme.of(context).accentTextTheme.title.color,
            ),
          ),
        ),
        Expanded(
          child: onExpand != null
              ? GestureDetector(
                  onTap: onExpand,
                  child: _buildContent(context),
                )
              : _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      children: <Widget>[
        content != null
            ? Expanded(
                child: content,
              )
            : Spacer(),
        onExpand != null
            ? Padding(
                padding: EdgeInsets.only(left: 12.5),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).accentTextTheme.title.color,
                  size: 15,
                ),
              )
            : SizedBox(width: 25),
      ],
    );
  }
}
