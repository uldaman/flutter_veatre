import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/mainUI.dart';

class Unlock extends StatefulWidget {
  Unlock({Key key, this.canCancel: false}) : super(key: key);
  final bool canCancel;

  @override
  UnlockState createState() => UnlockState();
}

class UnlockState extends State<Unlock> {
  String errorMsg = 'Please enter the master code';
  PassClearController passClearController = PassClearController();
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
              Passcodes(
                controller: passClearController,
                onChanged: (password) async {
                  setState(() => errorMsg = '');
                  if (password.length == 6) {
                    String masterPassHash = await Config.masterPassHash;
                    if (masterPassHash !=
                        bytesToHex(sha512(bytesToHex(sha256(password))))) {
                      setState(() => errorMsg = 'Passcode mismatch');
                    } else {
                      await Globals.updateMasterPasscodes(password);
                      final navigator = Navigator.of(context);
                      navigator.canPop()
                          ? navigator.pop(true)
                          : navigator.pushAndRemoveUntil(
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => MainUI(),
                                settings: RouteSettings(name: MainUI.routeName),
                              ),
                              (route) => route == null,
                            );
                    }
                    passClearController.clear();
                  }
                },
              ),
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
        widget.canCancel
            ? FlatButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () => Navigator.of(context).maybePop(false),
              )
            : Container(),
      ],
    );
  }
}
