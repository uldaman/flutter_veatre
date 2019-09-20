import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/webViews.dart';
import 'package:veatre/src/utils/common.dart';

class TabViews extends StatefulWidget {
  final int id;
  final Network network;
  final Appearance appearance;
  final double ratio;
  final String url;
  final String currentTabKey;

  TabViews({
    this.id,
    this.network,
    this.appearance,
    this.ratio,
    this.url,
    this.currentTabKey,
  });

  @override
  TabViewsState createState() => TabViewsState();
}

class TabViewsState extends State<TabViews> {
  List<Snapshot> snapshots;
  int selectedTab;
  bool isSelectedTabAlive = true;
  String url;
  String selectedTabKey;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.id;
    url = widget.url;
    snapshots = WebViews.snapshots(widget.network);
    selectedTabKey = widget.currentTabKey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('Tabs'),
        leading: SizedBox(),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(15),
              physics: ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: widget.ratio,
              ),
              itemCount: snapshots.length,
              itemBuilder: (context, index) {
                return snapshotCard(index);
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 20),
            color: Theme.of(context).primaryColor,
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.blue,
                    size: 30,
                  ),
                  onPressed: () {
                    WebViews.removeAll(widget.network);
                    setState(() {
                      snapshots = WebViews.snapshots(widget.network);
                    });
                    WebViews.create(widget.network, randomHex(32));
                    Navigator.of(context).pop();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.blue,
                    size: 35,
                  ),
                  onPressed: () {
                    WebViews.create(widget.network, randomHex(32));
                    Navigator.of(context).pop();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.done,
                    color: Colors.blue,
                    size: 35,
                  ),
                  onPressed: () {
                    Globals.updateTabValue(
                      TabControllerValue(
                        id: selectedTab,
                        url: url,
                        network: widget.network,
                        stage: isSelectedTabAlive
                            ? TabStage.SelectedAlive
                            : TabStage.SelectedInAlive,
                        tabKey: selectedTabKey,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget snapshotCard(int index) {
    Snapshot snapshot = snapshots[index];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(2, 2),
            color:
                selectedTabKey == snapshot.key ? Colors.blue : Colors.black87,
          )
        ],
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 40, right: 40),
                        child: Text(
                          snapshot.title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                      ),
                      onPressed: () async {
                        WebViews.removeSnapshot(widget.network, snapshot.key);
                        if (snapshots.length == 1) {
                          WebViews.removeWebview(widget.network, snapshot.id);
                          WebViews.create(widget.network, randomHex(32));
                          Navigator.of(context).pop();
                          return;
                        }
                        if (snapshot.isAlive) {
                          WebViews.removeWebview(widget.network, snapshot.id);
                        }
                        setState(() {
                          snapshots = WebViews.snapshots(widget.network);
                        });
                        if (index == 0) {
                          selectedTab = snapshots[index + 1].id;
                          isSelectedTabAlive = snapshots[index + 1].isAlive;
                          url = snapshots[index + 1].url;
                          selectedTabKey = snapshots[index + 1].key;
                        } else if (selectedTab == snapshot.id) {
                          selectedTab = snapshots[index - 1].id;
                          isSelectedTabAlive = snapshots[index - 1].isAlive;
                          url = snapshots[index - 1].url;
                          selectedTabKey = snapshots[index - 1].key;
                        }
                        if (snapshot.isAlive) {
                          Globals.updateTabValue(
                            TabControllerValue(
                              id: snapshot.id,
                              url: url,
                              network: widget.network,
                              stage: TabStage.Removed,
                              tabKey: selectedTabKey,
                            ),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 0),
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    image: DecorationImage(
                      alignment: Alignment.topCenter,
                      fit: BoxFit.fitWidth,
                      image: snapshot.data == null
                          ? AssetImage('assets/blank.png')
                          : MemoryImage(snapshot.data),
                    ),
                  ),
                ),
                onTapUp: (tap) {
                  Globals.updateTabValue(
                    TabControllerValue(
                      id: snapshot.id,
                      network: widget.network,
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
          )
        ],
      ),
    );
  }
}
