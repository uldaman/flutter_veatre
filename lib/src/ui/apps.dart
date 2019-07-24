import 'package:flutter/material.dart';
import 'package:veatre/common/dapp_list.dart';

typedef onAppSelectedCallback = Future<void> Function(dynamic app);

class Apps extends StatelessWidget {
  final onAppSelectedCallback onAppSelected;

  Apps({Key key, this.onAppSelected}) : super(key: key);

  final int crossAxisCount = 4;
  final double crossAxisSpacing = 15;
  final double mainAxisSpacing = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        padding: EdgeInsets.all(15),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          return Column(
            children: <Widget>[
              SizedBox(
                width: (MediaQuery.of(context).size.width -
                        crossAxisCount * crossAxisSpacing -
                        40) /
                    crossAxisCount,
                child: FlatButton(
                  onPressed: () async {
                    if (onAppSelected != null) {
                      onAppSelected(apps[index]);
                    }
                  },
                  child: apps[index]["icon"],
                ),
              ),
              Text(
                apps[index]["title"],
                style: TextStyle(
                  color: Colors.brown,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
