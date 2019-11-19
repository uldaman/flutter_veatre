import 'package:flutter_bloc_cracker/flutter_bloc_cracker.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';
import 'package:local_auth/local_auth.dart';

class AuthenticationBloc extends BlocCrackerBase<AuthenticationState> {
  final LocalAuthentication localAuth = LocalAuthentication();
  @override
  AuthenticationState get initialState => Uninitialized();
}
