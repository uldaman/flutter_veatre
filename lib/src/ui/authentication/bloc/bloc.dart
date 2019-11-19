import 'package:flutter_bloc_cracker/flutter_bloc_cracker.dart';
import 'package:veatre/src/ui/authentication/bloc/state.dart';

class AuthenticationBloc extends BlocCrackerBase<AuthenticationState> {
  @override
  AuthenticationState get initialState => Uninitialized();
}
