import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/mainUI.dart';

class Unlock extends StatefulWidget {
  final bool everLaunched;
  Unlock({@required this.everLaunched});

  @override
  UnlockState createState() {
    return UnlockState();
  }
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
    return WillPopScope(
      child: Scaffold(
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                  top: 60,
                ),
                child: Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryTextTheme.title.color,
                    fontSize: 28,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            color:
                                Theme.of(context).primaryTextTheme.title.color,
                          ),
                        ),
                      ),
                    ),
                    buildPasscodes(
                      context,
                      passcodes,
                      6,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 30,
                          top: 10,
                        ),
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
                  if (passcodes.length > 0) {
                    setState(() {
                      passcodes.removeLast();
                    });
                  }
                  if (passcodes.length < 6) {
                    setState(() {
                      errorMsg = '';
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      onWillPop: () async {
        return !Navigator.of(context).userGestureInProgress;
      },
    );
  }

  Future<void> selectCode(String code) async {
    if (passcodes.length < 6) {
      passcodes.add(code);
      setState(() {
        errorMsg = '';
      });
      if (passcodes.length == 6) {
        String passwordHash = await Config.masterPassHash;
        String password = passcodes.join("");
        if (passwordHash != bytesToHex(sha512(bytesToHex(sha256(password))))) {
          Globals.clearMasterPasscodes();
          setState(() {
            errorMsg = 'Passcode mismatch';
          });
        } else {
          await Globals.updateMasterPasscodes(password);
          if (!widget.everLaunched) {
            await Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => MainUI(),
                settings: RouteSettings(name: MainUI.routeName),
              ),
              (route) => route == null,
            );
          } else {
            Navigator.of(context).pop();
          }
        }
        passcodes.clear();
      }
    }
  }
}
