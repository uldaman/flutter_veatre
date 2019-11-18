import 'package:flutter_bloc_cracker/flutter_bloc_cracker.dart';
import 'package:veatre/src/ui/authentication/bloc/bloc.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';

abstract class AuthenticationEvent
    extends BlocEvent<AuthenticationState, AuthenticationBloc> {}

class Initialize extends AuthenticationEvent {
  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    bloc.localAuth.canCheckBiometrics.then(
      // 回调函数中无法 yield, 所以绕一下
      (canCheckBiometrics) => bloc.emit(_Initialize(canCheckBiometrics)),
    );
  }
}

class _Initialize extends AuthenticationEvent {
  _Initialize(this._canCheckBiometrics);
  final bool _canCheckBiometrics;

  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    yield Unauthenticated(
      _canCheckBiometrics
          ? AuthenticationType.biometrics
          : AuthenticationType.password,
    );
  }
}

class Authenticate extends AuthenticationEvent {
  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    bloc.localAuth
        .authenticateWithBiometrics(
            localizedReason: 'Authenticate to use connet')
        .then(
          (didAuthenticate) => bloc.emit(_Authenticate(didAuthenticate)),
        );
  }
}

class _Authenticate extends AuthenticationEvent {
  _Authenticate(this._didAuthenticate);
  final bool _didAuthenticate;

  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    yield Authenticated(_didAuthenticate);
  }
}
