abstract class AuthenticationState {}

enum AuthenticationType { biometrics, password }

class Uninitialized extends AuthenticationState {}

class Unauthenticated extends AuthenticationState {
  Unauthenticated(this.authenticationType);
  final AuthenticationType authenticationType;
}

class Authenticated extends AuthenticationState {
  Authenticated(this.didAuthenticate);
  final bool didAuthenticate;
}
