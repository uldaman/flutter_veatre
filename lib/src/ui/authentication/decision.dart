import 'package:flutter/material.dart';
import 'package:veatre/src/ui/authentication/bloc/bloc.dart';
import 'package:veatre/src/ui/authentication/bloc/event.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';
import 'package:veatre/src/ui/authentication/unlock.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/mainUI.dart';
import 'package:system_setting/system_setting.dart';

class Decision extends StatefulWidget {
  Decision({Key key, this.canCancel: false}) : super(key: key);
  final bool canCancel;

  @override
  _DecisionState createState() => _DecisionState();
}

class _DecisionState extends State<Decision> {
  final AuthenticationBloc _bloc = AuthenticationBloc();

  @override
  void initState() {
    _subscribeBloc();
    _bloc.emit(Initialize());
    super.initState();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  void _subscribeBloc() => _bloc.state.listen((state) {
        if (state is Unauthenticated && state.authType == AuthType.biometrics)
          _redirectToAuthenticate();

        if (state is Authenticated) {
          if (state.didAuthenticate) {
            _redirectToMainUi();
          } else if (!state.didAuthenticate && state.notAvailable) {
            _redirectToAvailable();
          }
        }
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 60),
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
              StreamBuilder<AuthenticationState>(
                stream: _bloc.state,
                initialData: _bloc.initialState,
                builder: (context, snapshot) => Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    child: _switchUnlockWidget(snapshot.data),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get primaryColor => Theme.of(context).primaryColor;

  Widget _switchUnlockWidget(AuthenticationState state) =>
      (state is! Unauthenticated)
          ? Container()
          : (state as Unauthenticated).authType == AuthType.password
              ? Unlock(canCancel: widget.canCancel)
              : Column(
                  children: <Widget>[
                    SizedBox(height: 222),
                    FlatButton(
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.fingerprint,
                            size: 65,
                            color: primaryColor,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Tap to unlock with biometric',
                            style: TextStyle(color: primaryColor),
                          )
                        ],
                      ),
                      onPressed: _redirectToAuthenticate,
                    ),
                    Spacer(),
                    FlatButton(
                      child: Text(
                        'Unlock with master passcodes',
                        style: TextStyle(color: primaryColor),
                      ),
                      onPressed: () =>
                          _bloc.emit(Initialize(usePassword: true)),
                    ),
                  ],
                );

  void _redirectToAuthenticate() =>
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Future.delayed(
          Duration(milliseconds: 200),
          () => _bloc.emit(Authenticate()),
        ),
      );

  void _redirectToMainUi() {
    final navigator = Navigator.of(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => navigator.canPop()
          ? navigator.pop(true)
          : navigator.pushAndRemoveUntil(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => MainUI(),
                settings: RouteSettings(name: MainUI.routeName),
              ),
              (route) => route == null,
            ),
    );
  }

  void _redirectToAvailable() => customAlert(
        context,
        title: Text('Biometric'),
        content: Text('You need to open biometric in the system settings'),
        confirmAction: () async {
          SystemSetting.goto(SettingTarget.LOCATION);
          Navigator.of(context).pop();
        },
      );
}
