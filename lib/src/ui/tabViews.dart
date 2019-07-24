import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/ui/webViews.dart';

typedef onTabCreatedCallback = void Function();
typedef onTabSelectedCallback = void Function(int id);
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
  @override
  TabViewsState createState() => TabViewsState();
}

class TabViewsState extends State<TabViews> {

  @override
  Widget build(BuildContext context) {
    double ratio = MediaQuery.of(context).size.width /
        (MediaQuery.of(context).size.height - 20 - 44 - 48);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        title: Text('Tabs'),
        leading: SizedBox(),
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Close All',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 18,
              ),
            ),
            onPressed: () async {
              setState(() {
                removeAllTabs();
              });
              Navigator.of(context).pop(
                TabResult(
                  stage: TabStage.RemovedAll,
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(15),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: ratio,
              ),
              itemCount: tabShots.length,
              itemBuilder: (context, index) {
                return snapshotCard(index);
              },
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: SizedBox(
                      height: 64,
                      child: IconButton(
                        icon: Icon(
                          Icons.add,
                          color: Colors.blue,
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop(
                            TabResult(
                              stage: TabStage.Created,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
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
            )
          ],
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          children: <Widget>[
            Stack(
              children: <Widget>[
                Container(
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 40, right: 40),
                          child: Text(
                            tabShots[index].title,
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
                Container(
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 15,
                        ),
                        onPressed: () async {
                          setState(() {
                            removeTab(index);
                          });
                          if (tabshotLen == 0) {
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
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: MemoryImage(tabShots[index].data),
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
            )
          ],
        ),
      );
}
