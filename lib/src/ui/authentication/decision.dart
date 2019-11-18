import 'package:flutter/material.dart';
import 'package:veatre/src/ui/authentication/bloc/bloc.dart';
import 'package:veatre/src/ui/authentication/bloc/event.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';
import 'package:veatre/src/ui/authentication/unlock.dart';
import 'package:veatre/src/ui/mainUI.dart';

class Decision extends StatefulWidget {
  @override
  _DecisionState createState() => _DecisionState();
}

class _DecisionState extends State<Decision> {
  final AuthenticationBloc _bloc = AuthenticationBloc();

  @override
  void initState() {
    _bloc.emit(Initialize());
    super.initState();
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
                builder: (context, snapshot) {
                  final AuthenticationState state = snapshot.data;

                  if (state is Unauthenticated &&
                      state.authenticationType == AuthenticationType.biometrics)
                    _redirectToAuthenticate();

                  if (state is Authenticated && state.didAuthenticate)
                    _redirectToMainUi();

                  return Expanded(child: Unlock());
                },
              ),
            ],
          ),
        ),
      ),
    );
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
          ? navigator.pop()
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
