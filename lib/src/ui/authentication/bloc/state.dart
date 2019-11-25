abstract class AuthenticationState {}

enum AuthType { biometrics, password }

class Uninitialized extends AuthenticationState {}

class Unauthenticated extends AuthenticationState {
  Unauthenticated(this.authType);
  final AuthType authType;
}

class Authenticated extends AuthenticationState {
  Authenticated(this.didAuthenticate, {this.notAvailable: false});
  final bool didAuthenticate;
  final bool notAvailable;
}
