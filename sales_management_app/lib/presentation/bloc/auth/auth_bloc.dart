import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sales_management_app/domain/entities/user.dart';
import 'package:sales_management_app/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  void _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.username, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }

  void _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final isLoggedIn = await authRepository.isLoggedIn();
    if (isLoggedIn) {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
        return;
      }
    }
    emit(AuthUnauthenticated());
  }
}