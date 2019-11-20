import 'package:flutter/material.dart';
import 'package:flutter_bloc_cracker/flutter_bloc_cracker.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/ui/authentication/bloc/bloc.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';
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
                  child: BlocConsumer<AuthenticationState, AuthenticationBloc>(
                    builder: (_, state, ___, ____) => Text(
                      (state is Authenticated && !state.didAuthenticate)
                          ? state.errMsg
                          : errorMsg,
                      style: TextStyle(
                        fontSize: 17,
                        color: Theme.of(context).errorColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        BlocConsumer<AuthenticationState, AuthenticationBloc>(
          builder: (_, state, ___, ____) {
            String title = '';
            Function() callback;
            if (widget.canCancel) {
              if (state is Authenticated && !state.didAuthenticate) {
                title = 'Cancel';
                callback = () => Navigator.of(context).maybePop(false);
              }
            }
            return FlatButton(
              child: Text(
                title,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onPressed: callback,
            );
          },
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
        String masterPassHash = await Config.masterPassHash;
        String password = passcodes.join("");
        if (masterPassHash !=
            bytesToHex(sha512(bytesToHex(sha256(password))))) {
          Globals.clearMasterPasscodes();
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
        passcodes.clear();
      }
    }
  }
}
