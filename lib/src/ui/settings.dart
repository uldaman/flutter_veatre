import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/enterPassword.dart';
import 'package:veatre/src/ui/apperance.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/network.dart';

class Settings extends StatefulWidget {
  static const routeName = '/settings';

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  Network _network = Network.MainNet;
  Appearance _appearance = Appearance.light;
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initNet();
    initAppearance();
  }

  Future<void> initNet() async {
    final net = await Config.network;
    setState(() {
      _network = net;
    });
  }

  Future<void> initAppearance() async {
    final appearance = await Config.appearance;
    setState(() {
      _appearance = appearance;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    widgets.addAll([
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
        Icons.face,
        'Theme',
        _appearance == Appearance.light ? 'Light' : 'Dark',
        () async {
          await Navigator.of(context).pushNamed(Appearances.routeName);
          await initAppearance();
        },
      ),
      buildCell(
        Icons.lock,
        'Change Passcode',
        '',
        () async {
          String password = await verifyPassword();
          if (password != null) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                return EnterPassword(
                  canBack: true,
                  fromRoute: Settings.routeName,
                );
              }),
            );
          }
        },
      ),
    ]);
    return Scaffold(
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
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 15),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
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
                        Icons.arrow_forward_ios,
                        size: 16,
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

  Future<String> verifyPassword() async {
    String password = await customAlert(context,
        title: Text('Input Master Code'),
        content: Column(
          children: <Widget>[
            Text(
              'Please input the master code to continue',
              style: TextStyle(fontSize: 14),
            ),
            Padding(
              padding: EdgeInsets.only(top: 15),
              child: TextField(
                autofocus: true,
                controller: passwordController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(hintText: 'Master code'),
              ),
            ),
          ],
        ), confirmAction: () async {
      String password = passwordController.text;
      String passwordHash = await Config.passwordHash;
      String hash = bytesToHex(sha512(password));
      if (hash != passwordHash) {
        Navigator.of(context).pop();
        return alert(context, Text('Incorrect Master Code'),
            'Please input correct master code');
      } else {
        Globals.updateMasterPasscodes(password);
        Navigator.of(context).pop(password);
      }
    });
    passwordController.clear();
    return password;
  }
}
