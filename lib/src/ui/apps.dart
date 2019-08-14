import 'package:flutter/material.dart';
import 'package:veatre/src/models/dapp.dart';
import 'package:cached_network_image/cached_network_image.dart';

typedef onAppSelectedCallback = Future<void> Function(Dapp app);

class Apps extends StatelessWidget {
  final List<Dapp> apps;
  final onAppSelectedCallback onAppSelected;

  Apps({Key key, this.apps, this.onAppSelected}) : super(key: key);

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
                  child: CachedNetworkImage(
                    imageUrl: apps[index].logo,
                    placeholder: (context, url) => SizedBox.fromSize(
                      size: Size.square(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        Image.asset("assets/blank.png"),
                  ),
                ),
              ),
              Text(
                apps[index].name.length > 12
                    ? apps[index].name.substring(0, 12)
                    : apps[index].name,
                style: TextStyle(color: Colors.brown, fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }
}
