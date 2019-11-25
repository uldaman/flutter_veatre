import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart';
import 'package:system_setting/system_setting.dart';

import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/enterPassword.dart';
import 'package:veatre/src/ui/commonComponents.dart';

class Settings extends StatefulWidget {
  static const routeName = '/settings';

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool _bioEnabled = false;
  Network _network = Globals.network;
  Appearance _appearance = Globals.appearance;
  TextEditingController passwordController = TextEditingController();
  final LocalAuthentication localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    updateBioEnabled();
  }

  updateBioEnabled() async {
    final pass = await Globals.getKeychainPass();
    setState(() {
      _bioEnabled = pass != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Text(
                  'Security',
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).accentColor,
                padding: EdgeInsets.only(top: 15, left: 15, right: 15),
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Change Master Code'),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            )
                          ],
                        ),
                      ),
                      onTapUp: (details) async {
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
                    Divider(
                      height: 1,
                      thickness: 1,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text('Enable FaceID/TouchID'),
                          ),
                          CupertinoSwitch(
                            value: _bioEnabled,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) async {
                              if (value) {
                                try {
                                  final isAuthed = await localAuth
                                      .authenticateWithBiometrics(
                                          localizedReason:
                                              'Authenticate to use connet');
                                  if (isAuthed) {
                                    await Globals.setKeychainPass(
                                        bytesToHex(Globals.masterPasscodes));
                                    setState(() {
                                      _bioEnabled = true;
                                    });
                                  } else if (!(await localAuth
                                      .canCheckBiometrics)) {
                                    await _gotoBiometricSettings();
                                  } else {
                                    setState(() {
                                      _bioEnabled = false;
                                    });
                                  }
                                } catch (e) {
                                  print("authenticateWithBiometrics error: $e");
                                  await _gotoBiometricSettings();
                                }
                              } else {
                                await Globals.removeKeychainPass();
                                setState(() {
                                  _bioEnabled = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'Network',
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).accentColor,
                child: Column(
                  children: <Widget>[
                    buildCell(
                      'MainNet',
                      _network == Network.MainNet,
                      () async {
                        await changeNet(Network.MainNet);
                      },
                    ),
                    _divider,
                    buildCell(
                      'TestNet',
                      _network == Network.TestNet,
                      () async {
                        await changeNet(Network.TestNet);
                      },
                    ),
                  ],
                ),
              ),
              // Padding(
              //   padding: EdgeInsets.symmetric(vertical: 15),
              //   child: Text(
              //     'Theme',
              //     style: TextStyle(
              //       color: Theme.of(context).primaryTextTheme.display2.color,
              //     ),
              //   ),
              // ),
              // Container(
              //   color: Theme.of(context).accentColor,
              //   child: Column(
              //     children: <Widget>[
              //       buildCell(
              //         'Light',
              //         _appearance == Appearance.light,
              //         () async {
              //           await changeTheme(Appearance.light);
              //         },
              //       ),
              //       _divider,
              //       buildCell(
              //         'Dark',
              //         _appearance == Appearance.dark,
              //         () async {
              //           await changeTheme(Appearance.dark);
              //         },
              //       ),
              //     ],
              //   ),
              // ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 34),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'App Ver 1.0.0',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .display2
                                  .color,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Connex 1.1.4',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .display2
                                    .color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _divider => Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Divider(
          height: 1,
          thickness: 1,
        ),
      );

  Widget buildCell(String title, bool isSelected, Function() onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              title,
            ),
            isSelected
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }

  Future<void> changeNet(Network network) async {
    if (_network != network) {
      await Config.setNetwork(network);
      setState(() {
        this._network = network;
      });
      Globals.updateNetwork(network);
    }
  }

  Future<void> changeTheme(Appearance appearance) async {
    if (_appearance != appearance) {
      await Config.setAppearance(appearance);
      setState(() {
        _appearance = appearance;
      });
      Globals.updateAppearance(appearance);
    }
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
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(hintText: 'Master code'),
              ),
            ),
          ],
        ), confirmAction: () async {
      String password = passwordController.text;
      String masterPassHash = await Config.masterPassHash;
      String hash = bytesToHex(sha512(bytesToHex(sha256(password))));
      if (hash != masterPassHash) {
        Navigator.of(context).pop();
        return alert(context, Text('Incorrect Master Code'),
            'Please input correct master code');
      } else {
        Navigator.of(context).pop(password);
      }
    });
    passwordController.clear();
    return password;
  }

  Future<void> _gotoBiometricSettings() async {
    await customAlert(
      context,
      title: Text('生物识别'),
      content: Text('去设置生物识别权限'),
      confirmAction: () async {
        SystemSetting.goto(SettingTarget.LOCATION);
        Navigator.of(context).pop();
      },
    );
    setState(() {
      _bioEnabled = false;
    });
  }
}
