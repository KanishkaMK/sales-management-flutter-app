import 'package:sales_management_app/presentation/bloc/auth/auth_bloc.dart';

class LoginViewModel {
  final AuthBloc authBloc;

  LoginViewModel({required this.authBloc});

  void login(String username, String password) {
    authBloc.add(LoginEvent(username: username, password: password));
  }

  void checkAuthStatus() {
    authBloc.add(CheckAuthStatusEvent());
  }
}