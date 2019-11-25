import 'package:flutter/material.dart';
import 'package:flutter_bloc_cracker/flutter_bloc_cracker.dart';
import 'package:veatre/src/ui/authentication/bloc/bloc.dart';
import 'package:veatre/src/ui/authentication/bloc/event.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';
import 'package:veatre/src/ui/authentication/unlock.dart';
import 'package:veatre/src/ui/mainUI.dart';

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
                    duration: const Duration(milliseconds: 500),
                    child: _isShowUnlockWidget(snapshot.data)
                        ? Unlock(canCancel: widget.canCancel)
                        : Container(),
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
    if (state is Unauthenticated &&
        state.authenticationType == AuthenticationType.password) return true;
    if (state is Authenticated && !state.didAuthenticate) return true;
    return false;
  }

  void _subscribeBloc() => _bloc.state.listen((state) {
        if (state is Unauthenticated &&
            state.authenticationType == AuthenticationType.biometrics)
          _redirectToAuthenticate();

        if (state is Authenticated && state.didAuthenticate)
          _redirectToMainUi();
      });

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
}
