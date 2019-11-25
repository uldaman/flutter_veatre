import 'package:flutter/services.dart';
import 'package:flutter_bloc_cracker/flutter_bloc_cracker.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/authentication/bloc/bloc.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

abstract class AuthenticationEvent
    extends BlocEvent<AuthenticationState, AuthenticationBloc> {}

class Initialize extends AuthenticationEvent {
  Initialize({this.usePassword: false});
  final bool usePassword;

  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    if (usePassword || await Globals.getKeychainPass() == null) {
      yield Unauthenticated(AuthType.password);
    } else {
      yield Unauthenticated(AuthType.biometrics);
    }
  }
}

class Authenticate extends AuthenticationEvent {
  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    bool didAuthenticate = false;

    try {
      didAuthenticate = await bloc.localAuth.authenticateWithBiometrics(
          localizedReason: 'Authenticate to use connet');
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        yield Authenticated(false, notAvailable: true);
        return;
      }
    }

    if (!didAuthenticate) {
      yield Authenticated(false);
      return;
    }

    final String masterPass = await Globals.getKeychainPass();
    if (bytesToHex(sha512(masterPass)) == await Config.masterPassHash) {
      await Globals.setKeychainPass(masterPass);
      yield Authenticated(true);
    } else {
      yield Authenticated(false);
    }
  }
}
