import 'package:flutter/material.dart';
import 'package:veatre/src/ui/webViews.dart';

class SnapshotCard extends StatelessWidget {
  SnapshotCard(
    this.snapshot,
    this.showTitle, {
    this.isSelected = false,
    this.onClosed,
    this.onSelected,
  });

  final Snapshot snapshot;
  final bool showTitle;
  final bool isSelected;
  final Function onClosed;
  final Function onSelected;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (showTitle)
      children.add(
        Expanded(
          child: title(
            context,
            snapshot,
            close: onClosed,
          ),
          flex: 1,
        ),
      );
    children.add(
      Expanded(
        flex: 9,
        child: GestureDetector(
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: snapshot.data != null
                ? Image(
                    gaplessPlayback: true,
                    alignment: Alignment.topCenter,
                    fit: BoxFit.fitWidth,
                    image: MemoryImage(snapshot.data),
                  )
                : SizedBox(),
          ),
          onTapUp: (tap) {
            if (onSelected != null) {
              onSelected();
            }
          },
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          width: 1,
          color:
              isSelected ? Theme.of(context).primaryColor : Color(0xFF666666),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget title(BuildContext context, Snapshot snapshot, {Function close}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Text(
              snapshot.title == null || snapshot.title == ''
                  ? 'New Tab'
                  : snapshot.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryTextTheme.title.color,
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(
              Icons.close,
              size: 17,
            ),
          ),
          onTapUp: (d) => close(),
        ),
      ],
    );
  }
}
