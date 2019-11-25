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
    final Color primaryColor = Theme.of(context).primaryColor;
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
                    duration: const Duration(milliseconds: 200),
                    child: _isShowUnlockWidget(snapshot.data)
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
                                      '点击进行生物识别',
                                      style: TextStyle(color: primaryColor),
                                    )
                                  ],
                                ),
                                onPressed: _redirectToAuthenticate,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isShowUnlockWidget(AuthenticationState state) {
    if (state is Unauthenticated && state.authType == AuthType.password)
      return true;
    if (state is Authenticated && !state.didAuthenticate && !state.notAvailable)
      return true;
    return false;
  }

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
        title: Text('生物识别'),
        content: Text('去设置生物识别权限'),
        confirmAction: () async {
          SystemSetting.goto(SettingTarget.LOCATION);
          Navigator.of(context).pop();
        },
      );
}
