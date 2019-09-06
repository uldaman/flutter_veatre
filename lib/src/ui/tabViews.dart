import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/webViews.dart';

class TabViews extends StatefulWidget {
  final int id;
  final Network network;
  final Appearance appearance;
  final double ratio;

  TabViews({
    this.id,
    this.network,
    this.appearance,
    this.ratio,
  });

  @override
  TabViewsState createState() => TabViewsState();
}

class TabViewsState extends State<TabViews> {
  int selectedTab;
  List<Snapshot> snapshots;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.id;
    snapshots = WebViews.snapshots(widget.network);
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
                    WebViews.create(widget.network);
                    Navigator.of(context).pop();
                  },
                ),
                WebViews.canCreateMore(widget.network)
                    ? IconButton(
                        icon: Icon(
                          Icons.add,
                          color: Colors.blue,
                          size: 35,
                        ),
                        onPressed: () {
                          WebViews.create(widget.network);
                          Navigator.of(context).pop();
                        },
                      )
                    : SizedBox(),
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
                        network: widget.network,
                        stage: TabStage.Selected,
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
            color: snapshot.id == selectedTab ? Colors.blue : Colors.black87,
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
                        if (snapshots.length == 1) {
                          WebViews.remove(widget.network, snapshot.id);
                          WebViews.create(widget.network);
                          Navigator.of(context).pop();
                          return;
                        }
                        WebViews.remove(widget.network, snapshot.id);
                        setState(() {
                          snapshots = WebViews.snapshots(widget.network);
                        });
                        if (index == 0) {
                          selectedTab = snapshots[index + 1].id;
                        } else if (selectedTab == snapshot.id) {
                          selectedTab = snapshots[index - 1].id;
                        }
                        Globals.updateTabValue(
                          TabControllerValue(
                            id: snapshot.id,
                            network: widget.network,
                            stage: TabStage.Removed,
                          ),
                        );
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
                onTap: () {
                  Globals.updateTabValue(
                    TabControllerValue(
                      id: snapshot.id,
                      network: widget.network,
                      stage: TabStage.Selected,
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
