import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/mainUI.dart';

class ReEnterPassword extends StatefulWidget {
  final String passwordHash;
  final String fromRoute;
  ReEnterPassword({@required this.passwordHash, this.fromRoute});

  @override
  ReEnterPasswordState createState() {
    return ReEnterPasswordState();
  }
}

class ReEnterPasswordState extends State<ReEnterPassword> {
  List<String> passcodes = [];
  String errorMsg = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 30,
                ),
                child: SizedBox(
                  width: 200,
                  child: Text(
                    'Re-Enter your passcode',
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 60,
                child: Text(
                  'The passcode is the six-digit code you inputed.This passcode is used to access your application and wallets.You can change the passcode in Setting in future.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).primaryTextTheme.display2.color,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
                          color: Colors.red,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  )
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
    );
  }

  Future<void> selectCode(String code) async {
    if (passcodes.length < 6) {
      passcodes.add(code);
      setState(() {
        errorMsg = '';
      });
      if (passcodes.length == 6) {
        String password = passcodes.join("");
        String passwordHash = bytesToHex(sha512(bytesToHex(sha256(password))));
        if (passwordHash != widget.passwordHash) {
          Globals.clearMasterPasscodes();
          passcodes.clear();
          setState(() {
            errorMsg = 'Passcode mismatch';
          });
        } else if (widget.fromRoute != null) {
          try {
            await Config.changePassword(
              Globals.masterPasscodes,
              password,
              passwordHash,
            );
            final keychainPass = await Globals.getKeychainPass();
            if (keychainPass != null) {
              Globals.setKeychainPass(bytesToHex(Globals.masterPasscodes));
            }
            await Globals.updateMasterPasscodes(password);
            Navigator.of(context)
                .popUntil(ModalRoute.withName(widget.fromRoute));
          } catch (e) {
            alert(context, Text('Change passcodes failed'), e.toString());
          }
        } else {
          await Config.setMasterPassHash(passwordHash);
          await Globals.updateMasterPasscodes(password);
          await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => MainUI(),
              settings: RouteSettings(name: MainUI.routeName),
            ),
            (route) => route == null,
          );
        }
      }
    }
  }
}
