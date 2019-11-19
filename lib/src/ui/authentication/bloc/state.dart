abstract class AuthenticationState {}

enum AuthenticationType { biometrics, password }

class Uninitialized extends AuthenticationState {}

class Unauthenticated extends AuthenticationState {
  Unauthenticated(this.authenticationType);
  final AuthenticationType authenticationType;
}

class Authenticated extends AuthenticationState {
  Authenticated(this.didAuthenticate, {this.errMsg: ''});
  final bool didAuthenticate;
  final String errMsg;
}
