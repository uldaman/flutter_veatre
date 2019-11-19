import 'package:flutter_bloc_cracker/flutter_bloc_cracker.dart';
import 'package:flutter_keychain/flutter_keychain.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/authentication/bloc/bloc.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';
import 'package:veatre/src/utils/common.dart';

abstract class AuthenticationEvent
    extends BlocEvent<AuthenticationState, AuthenticationBloc> {}

class Initialize extends AuthenticationEvent {
  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    if (await FlutterKeychain.get(key: 'password') != null) {
      yield Unauthenticated(AuthenticationType.biometrics);
    } else {
      yield Unauthenticated(AuthenticationType.password);
    }
  }
}

class Authenticate extends AuthenticationEvent {
  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    final bool didAuthenticate = await bloc.localAuth
        .authenticateWithBiometrics(
            localizedReason: 'Authenticate to use connet');

    if (!didAuthenticate) {
      yield Authenticated(false, errMsg: 'Biometrics mismatch');
      return;
    }

    final String password = await FlutterKeychain.get(key: 'password');
    if (bytesToHex(sha512(password)) == await Config.passwordHash) {
      Globals.updateMasterPasscodes(password);
      yield Authenticated(true);
    } else {
      yield Authenticated(false, errMsg: 'Please update biometrics');
    }
  }
}
