import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.identifier, required this.password});

  final String identifier;
  final String password;

  @override
  List<Object?> get props => [identifier, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
