import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/ui/activities.dart';
import 'package:veatre/src/ui/network.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class Settings extends StatefulWidget {
  static const routeName = '/settings';

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  String _network = '';

  @override
  void initState() {
    super.initState();
    setNet();
  }

  Future<void> setNet() async {
    bool isMainNet = await NetworkStorage.isMainNet;
    setState(() {
      _network = isMainNet ? 'MainNet' : 'TestNet';
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    widgets.addAll([
      buildCell(
        FontAwesomeIcons.wallet,
        'Wallets',
        () async {
          await Navigator.of(context).pushNamed(ManageWallets.routeName);
        },
      ),
      buildCell(
        Icons.alarm,
        'Activities',
        () async {
          final headController = await Globals.headControllerForCurrentNet;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Activities(headController: headController),
            ),
          );
        },
      ),
      buildCell(
        Icons.network_check,
        'Network',
        () async {
          await Navigator.of(context).pushNamed(Networks.routeName);
          await setNet();
        },
      ),
    ]);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: widgets,
      ),
    );
  }

  Widget buildCell(IconData icon, String title, Function() onTap) {
    return Container(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          child: Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 15),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.lightBlue[200],
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 15),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      title == 'Network' ? Text(_network) : SizedBox(),
                      Icon(
                        FontAwesomeIcons.angleRight,
                        size: 20,
                        color: Colors.grey,
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      height: 60,
    );
  }
}
