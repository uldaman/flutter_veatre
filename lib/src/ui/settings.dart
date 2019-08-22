import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/storage/appearanceStorage.dart';
import 'package:veatre/src/ui/apperance.dart';
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
  Network _network = Network.MainNet;
  Appearance _appearance = Appearance.light;

  @override
  void initState() {
    super.initState();
    initNet();
    initAppearance();
  }

  Future<void> initNet() async {
    final net = await NetworkStorage.network;
    setState(() {
      _network = net;
    });
  }

  Future<void> initAppearance() async {
    final appearance = await AppearanceStorage.appearance;
    setState(() {
      _appearance = appearance;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    widgets.addAll([
      buildCell(
        FontAwesomeIcons.wallet,
        'Wallets',
        '',
        () async {
          await Navigator.of(context).pushNamed(ManageWallets.routeName);
        },
      ),
      buildCell(
        Icons.alarm,
        'Activities',
        '',
        () async {
          final network = await NetworkStorage.network;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Activities(network: network),
            ),
          );
        },
      ),
      buildCell(
        Icons.network_check,
        'Network',
        _network == Network.MainNet ? 'MainNet' : 'TestNet',
        () async {
          await Navigator.of(context).pushNamed(Networks.routeName);
          await initNet();
        },
      ),
      buildCell(
        Icons.network_check,
        'Theme',
        _appearance == Appearance.light ? 'Light' : 'Dark',
        () async {
          await Navigator.of(context).pushNamed(Appearances.routeName);
          await initAppearance();
        },
      ),
    ]);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.only(top: 10),
        children: widgets,
      ),
    );
  }

  Widget buildCell(
      IconData icon, String title, String subTitle, Function() onTap) {
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
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 15),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.title.color,
                    fontSize: 18,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      subTitle == '' ? SizedBox() : Text(subTitle),
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
