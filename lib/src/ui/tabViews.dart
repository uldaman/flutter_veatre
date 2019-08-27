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
  TabViews({
    this.id,
    this.network,
    this.appearance,
  });

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
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
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
        itemCount: WebViews.snapshots(widget.network).length,
        itemBuilder: (context, index) {
          return snapshotCard(index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).primaryColor,
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
                WebViews.removeAllTabs(widget.network);
              });
              WebViews.newWebView(
                network: widget.network,
                appearance: widget.appearance,
              );
              Navigator.of(context).pop();
              break;
            case 1:
              WebViews.newWebView(
                network: widget.network,
                appearance: widget.appearance,
              );
              Navigator.of(context).pop();
              break;
            case 2:
              Globals.updateTabValue(
                TabControllerValue(
                  id: selectedTab,
                  network: widget.network,
                  stage: TabStage.Selected,
                ),
              );
              Navigator.of(context).pop();
              break;
          }
        },
      ),
    );
  }

  Widget snapshotCard(int index) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
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
                            WebViews.snapshots(widget.network)[index].title ??
                                '',
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
                          if (index == selectedTab) {
                            selectedTab = index - 1;
                          } else if (index < selectedTab) {
                            selectedTab--;
                          }
                          setState(() {
                            WebViews.removeTab(widget.network, index);
                          });
                          Globals.updateTabValue(
                            TabControllerValue(
                              id: index,
                              network: widget.network,
                              stage: TabStage.Removed,
                            ),
                          );
                          if (WebViews.snapshots(widget.network).length == 0) {
                            WebViews.newWebView(
                              network: widget.network,
                              appearance: widget.appearance,
                            );
                            Navigator.of(context).pop();
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
                        image: WebViews.snapshots(widget.network)[index].data ==
                                null
                            ? AssetImage('assets/blank.png')
                            : MemoryImage(
                                WebViews.snapshots(widget.network)[index].data),
                      ),
                    ),
                  ),
                  onTap: () {
                    Globals.updateTabValue(
                      TabControllerValue(
                        id: index,
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
