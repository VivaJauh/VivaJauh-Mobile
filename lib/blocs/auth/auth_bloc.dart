import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/auth_service.dart';
import '../../utils/error_messages.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthService authService})
    : _authService = authService,
      super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthService _authService;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final onboarded = _authService.hasCompletedOnboarding();
    final session = await _authService.restoreSession();

    if (!onboarded) {
      emit(const AuthState(status: AuthStatus.onboarding));
      return;
    }
    emit(
      AuthState(
        status: session != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        session: session,
      ),
    );
  }

  Future<void> _onOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.completeOnboarding();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthStatus.unauthenticated, submitting: true));
    try {
      final session = await _authService.login(
        event.identifier,
        event.password,
      );
      emit(AuthState(status: AuthStatus.authenticated, session: session));
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          error: friendlyErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthStatus.unauthenticated, submitting: true));
    try {
      final session = await _authService.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthState(status: AuthStatus.authenticated, session: session));
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          error: friendlyErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
