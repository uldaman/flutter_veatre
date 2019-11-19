import 'package:flutter_bloc_cracker/flutter_bloc_cracker.dart';
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
    yield Unauthenticated(AuthenticationType.biometrics);
  }
}

class Authenticate extends AuthenticationEvent {
  @override
  Stream<AuthenticationState> handleEvent(
    AuthenticationBloc bloc,
    AuthenticationState currentState,
  ) async* {
    final String password = await Globals.bioPass.retreive(
      withPrompt: 'Authenticate to use connet',
    );
    if (password != null) {
      if (bytesToHex(sha512(password)) == await Config.passwordHash) {
        Globals.updateMasterPasscodes(password);
        yield Authenticated(true);
      } else {
        yield Authenticated(false, errMsg: 'Please update biometrics');
      }
    } else {
      yield Authenticated(false, errMsg: 'Biometrics mismatch');
    }
  }
}
