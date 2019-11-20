import 'package:flutter/material.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/reEnterPassword.dart';

class EnterPassword extends StatefulWidget {
  final bool canBack;
  final String fromRoute;
  EnterPassword({this.canBack, this.fromRoute});

  @override
  EnterPasswordState createState() {
    return EnterPasswordState();
  }
}

class EnterPasswordState extends State<EnterPassword> {
  List<String> passcodes = [];
  bool canback;

  @override
  void initState() {
    this.canback = widget.canBack ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            canback
                ? Column(
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
                              'Enter your passcode',
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
                    ],
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 60,
                        left: 30,
                      ),
                      child: SizedBox(
                        width: 200,
                        child: Text(
                          'Enter your passcode',
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
                        '',
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> selectCode(String code) async {
    if (passcodes.length < 6) {
      setState(() {
        passcodes.add(code);
      });
      if (passcodes.length == 6) {
        String password = passcodes.join("");
        String passwordHash = bytesToHex(sha512(bytesToHex(sha256(password))));
        await Navigator.push(
          context,
          new MaterialPageRoute(
            builder: (context) => new ReEnterPassword(
              passwordHash: passwordHash,
              fromRoute: widget.fromRoute,
            ),
          ),
        );
        setState(() {
          passcodes.clear();
        });
      }
    }
  }
}
