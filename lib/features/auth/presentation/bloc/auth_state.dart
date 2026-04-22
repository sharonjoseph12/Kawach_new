import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSent extends AuthState {
  final String phone;
  const AuthCodeSent(this.phone);

  @override
  List<Object> get props => [phone];
}

class AuthAuthenticated extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthFailureState extends AuthState {
  final String message;
  const AuthFailureState(this.message);

  @override
  List<Object> get props => [message];
}
