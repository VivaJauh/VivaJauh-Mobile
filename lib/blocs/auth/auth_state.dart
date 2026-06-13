import 'package:equatable/equatable.dart';

import '../../models/models.dart';

enum AuthStatus { initial, onboarding, unauthenticated, authenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.submitting = false,
    this.error,
  });

  final AuthStatus status;
  final AuthSession? session;
  final bool submitting;
  final String? error;

  @override
  List<Object?> get props => [status, session?.userId, submitting, error];
}
