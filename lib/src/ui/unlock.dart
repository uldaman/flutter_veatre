import 'dart:convert';
import 'package:flutter/material.dart';
import "package:pointycastle/api.dart" as api;
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                        color: Colors.red,
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
    );
  }

  Future<void> selectCode(String code) async {
    if (passcodes.length < 6) {
      setState(() {
        errorMsg = '';
      });
      setState(() {
        passcodes.add(code);
      });
      if (passcodes.length == 6) {
        String passwordHash = await Config.passwordHash;
        String password = passcodes.join("");
        if (passwordHash !=
            bytesToHex(
                new api.Digest("SHA-512").process(utf8.encode(password)))) {
          Globals.clearMasterPasscodes();
          setState(() {
            passcodes.clear();
            errorMsg = 'Passcode mismatch';
          });
        } else {
          Globals.updateMasterPasscodes(password);
          if (!widget.everLaunched) {
            await Navigator.pushNamed(context, MainUI.routeName);
          } else {
            Navigator.of(context).pop();
          }
        }
      }
    }
  }
}
