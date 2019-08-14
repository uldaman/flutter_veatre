import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/ui/webViews.dart';

enum TabStage {
  Created,
  Selected,
  RemovedAll,
}

class TabResult {
  int id;
  TabStage stage;

  TabResult({this.id, this.stage});
}

class TabViews extends StatefulWidget {
  final int id;
  final Network net;
  TabViews({this.id, this.net});

  @override
  TabViewsState createState() => TabViewsState();
}

class TabViewsState extends State<TabViews> {
  int selectedTab;
  @override
  void initState() {
    super.initState();
    selectedTab = widget.id;
  }

  @override
  Widget build(BuildContext context) {
    double ratio = MediaQuery.of(context).size.width /
        (MediaQuery.of(context).size.height - 20 - 75 - 49);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        title: Text('Tabs'),
        leading: SizedBox(),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(15),
        physics: ClampingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: ratio,
        ),
        itemCount: snapshots(widget.net).length,
        itemBuilder: (context, index) {
          return snapshotCard(index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.close,
              color: Colors.blue,
              size: 30,
            ),
            title: SizedBox(),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add,
              color: Colors.blue,
              size: 35,
            ),
            title: SizedBox(),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.done,
              color: Colors.blue,
              size: 30,
            ),
            title: SizedBox(),
          )
        ],
        onTap: (index) async {
          switch (index) {
            case 0:
              setState(() {
                removeAllTabs(widget.net);
              });
              Navigator.of(context).pop(
                TabResult(
                  stage: TabStage.RemovedAll,
                ),
              );
              break;
            case 1:
              Navigator.of(context).pop(
                TabResult(
                  stage: TabStage.Created,
                ),
              );
              break;
            case 2:
              Navigator.of(context).pop(
                TabResult(
                  id: selectedTab,
                  stage: TabStage.Selected,
                ),
              );
              break;
          }
        },
      ),
    );
  }

  Widget snapshotCard(int index) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          boxShadow: [
            BoxShadow(
              blurRadius: 2,
              offset: Offset(2, 2),
              color: index == selectedTab ? Colors.blue : Colors.black87,
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
                            snapshots(widget.net)[index].title ?? '',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                            ),
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
                          if (index == selectedTab) {
                            selectedTab = index - 1;
                          } else if (index < selectedTab) {
                            selectedTab--;
                          }
                          setState(() {
                            removeTab(widget.net, index);
                          });
                          if (snapshots(widget.net).length == 0) {
                            Navigator.of(context)
                                .pop(TabResult(stage: TabStage.RemovedAll));
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
                        fit: BoxFit.fill,
                        image: snapshots(widget.net)[index].data == null
                            ? AssetImage('assets/blank.png')
                            : MemoryImage(snapshots(widget.net)[index].data),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(
                      TabResult(
                        id: index,
                        stage: TabStage.Selected,
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      );
}
