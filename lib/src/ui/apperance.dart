import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';

class Appearances extends StatefulWidget {
  static const routeName = '/appearances';

  @override
  AppearancesState createState() => AppearancesState();
}

class AppearancesState extends State<Appearances> {
  Appearance _appearance = Appearance.light;

  @override
  void initState() {
    super.initState();
    AppearanceStorage.appearance.then((appearance) {
      setState(() {
        _appearance = appearance;
      });
    });
  }

  Future<void> changeTheme() async {
    final toAppearance =
        _appearance == Appearance.light ? Appearance.dark : Appearance.light;
    await AppearanceStorage.set(toAppearance);
    setState(() {
      _appearance = toAppearance;
    });
    Globals.updateAppearance(toAppearance);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    widgets.addAll([
      buildCell(
        'Light',
        _appearance == Appearance.light,
        () async {
          if (_appearance == Appearance.dark) {
            await changeTheme();
          }
        },
      ),
      buildCell(
        'Dark',
        _appearance == Appearance.dark,
        () async {
          if (_appearance == Appearance.light) {
            await changeTheme();
          }
        },
      ),
    ]);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          'Theme',
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: widgets,
      ),
    );
  }

  Widget buildCell(String title, bool show, Function() onTap) {
    return Container(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          child: Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 15),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.body1.color,
                  ),
                ),
              ),
              show
                  ? Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: 15),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.check,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : SizedBox()
            ],
          ),
        ),
      ),
      height: 60,
    );
  }
}