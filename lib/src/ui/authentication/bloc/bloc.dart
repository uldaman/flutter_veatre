import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';
import 'package:veatre/src/utils/common.dart';

class AuthenticationBloc extends BlocBase {
  AuthenticationBloc()
      : _localAuth = LocalAuthentication(),
        _controller = PublishSubject<AuthenticationState>();

  final PublishSubject<AuthenticationState> _controller;
  final LocalAuthentication _localAuth;

  Observable<AuthenticationState> get state => _controller;
  AuthenticationState get initialState => Uninitialized();

  Future<void> initialize({bool usePassword: false}) async =>
      (usePassword || await Globals.getKeychainPass() == null)
          ? _dispath(Unauthenticated(AuthType.password))
          : _dispath(Unauthenticated(AuthType.biometrics));

  Future<void> authenticate() async {
    bool didAuthenticate = false;

    try {
      didAuthenticate = await _localAuth.authenticateWithBiometrics(
        localizedReason: 'Authenticate to use connet',
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        return _dispath(Authenticated(false, notAvailable: true));
      }
    }

    if (!didAuthenticate) {
      return _dispath(Authenticated(false));
    }

    final String masterPass = await Globals.getKeychainPass();
    if (bytesToHex(sha512(masterPass)) != await Config.masterPassHash) {
      return _dispath(Authenticated(false));
    }
    await Globals.setKeychainPass(masterPass);
    return _dispath(Authenticated(true));
  }

  Function(AuthenticationState) get _dispath => _controller.sink.add;

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
