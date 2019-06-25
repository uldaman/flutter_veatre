import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/ui/manageWallets.dart';

class Settings extends StatelessWidget {
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    widgets.add(
      buildCell(
        FontAwesomeIcons.wallet,
        'Wallets',
        () {
          Navigator.of(context).pushNamed(ManageWallets.routeName);
        },
      ),
    );
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
        onTap: () {
          onTap();
        },
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
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      FontAwesomeIcons.angleRight,
                      size: 20,
                      color: Colors.grey,
                    ),
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
