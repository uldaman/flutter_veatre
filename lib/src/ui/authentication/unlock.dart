import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/mainUI.dart';

class Unlock extends StatefulWidget {
  Unlock();

  @override
  UnlockState createState() => UnlockState();
}

class UnlockState extends State<Unlock> {
  List<String> passcodes = [];
  String errorMsg = '';

  @override
  void initState() {
    Globals.clearMasterPasscodes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Enter the passcode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryTextTheme.title.color,
                    ),
                  ),
                ),
              ),
              buildPasscodes(context, passcodes, 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 30, top: 10),
                  child: Text(
                    errorMsg,
                    style: TextStyle(
                      fontSize: 17,
                      color: Theme.of(context).errorColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        passcodeKeyboard(
          context,
          onCodeSelected: selectCode,
          onDelete: () async {
            if (passcodes.length > 0) setState(() => passcodes.removeLast());
            if (passcodes.length < 6) setState(() => errorMsg = '');
          },
        ),
      ],
    );
  }

  Future<void> selectCode(String code) async {
    if (passcodes.length < 6) {
      passcodes.add(code);
      setState(() => errorMsg = '');
      if (passcodes.length == 6) {
        String passwordHash = await Config.passwordHash;
        String password = passcodes.join("");
        if (passwordHash != bytesToHex(sha512(password))) {
          Globals.clearMasterPasscodes();
          setState(() => errorMsg = 'Passcode mismatch');
        } else {
          Globals.updateMasterPasscodes(password);
          final navigator = Navigator.of(context);
          navigator.canPop()
              ? navigator.pop()
              : navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => MainUI(),
                    settings: RouteSettings(name: MainUI.routeName),
                  ),
                  (route) => route == null,
                );
        }
        passcodes.clear();
      }
    }
  }
}
