import 'package:flutter/material.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/common/globals.dart';

class SnapshotCard extends StatelessWidget {
  SnapshotCard(this.snapshot, this.showTitle);
  final Snapshot snapshot;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (showTitle)
      children.add(
        Expanded(
          child: title(
            context,
            snapshot,
            // close: () async {
            //   WebViews.removeSnapshot(snapshot.key);
            //   setState(() {
            //     snapshots = WebViews.snapshots();
            //   });
            //   if (snapshots.length == 0) {
            //     WebViews.removeWebview(snapshot.id);
            //     WebViews.create();
            //     Navigator.of(context).pop();
            //     return;
            //   }
            //   if (snapshot.isAlive) {
            //     WebViews.removeWebview(
            //       snapshot.id,
            //     );
            //   }
            //   if (index > 0) {
            //     if (_currentIndex >= index) {
            //       _currentIndex--;
            //     }
            //   } else if (_currentIndex != 0) {
            //     _currentIndex--;
            //   }
            //   selectedTab = snapshots[_currentIndex].id;
            //   isSelectedTabAlive = snapshots[_currentIndex].isAlive;
            //   url = snapshots[_currentIndex].url;
            //   selectedTabKey = snapshots[_currentIndex].key;
            //   if (snapshot.isAlive) {
            //     Globals.updateTabValue(
            //       TabControllerValue(
            //         id: snapshot.id,
            //         url: url,
            //         network: Globals.network,
            //         stage: TabStage.Removed,
            //         tabKey: selectedTabKey,
            //       ),
            //     );
            //   }
            // },
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
            // setState(() {
            //   _currentIndex = index;
            // });
            Globals.updateTabValue(
              TabControllerValue(
                id: snapshot.id,
                network: Globals.network,
                url: snapshot.url,
                stage: snapshot.isAlive
                    ? TabStage.SelectedAlive
                    : TabStage.SelectedInAlive,
                tabKey: snapshot.key,
              ),
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          width: 2,
          color: Color(0xFF666666),
          // color: selectedTabKey == snapshot.key
          //     ? Theme.of(context).primaryColor
          //     : Color(0xFF666666),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget title(BuildContext context, Snapshot snapshot, {Function close}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                snapshot.title == '' ? 'New Tab' : snapshot.title,
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
      ),
    );
  }
}
