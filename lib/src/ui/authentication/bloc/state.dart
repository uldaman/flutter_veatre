abstract class AuthenticationState {}

enum AuthType { biometrics, password }

class Uninitialized extends AuthenticationState {}

class Unauthenticated extends AuthenticationState {
  Unauthenticated(this.authType, {this.hasAuthority: true});
  final AuthType authType;
  final bool hasAuthority;
}

class Authenticated extends AuthenticationState {
  Authenticated(this.didAuthenticate);
  final bool didAuthenticate;
}
