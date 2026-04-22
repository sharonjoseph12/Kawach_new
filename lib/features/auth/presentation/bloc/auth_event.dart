import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthSendOTPPressed extends AuthEvent {
  final String phone;
  const AuthSendOTPPressed(this.phone);

  @override
  List<Object> get props => [phone];
}

class AuthVerifyOTPPressed extends AuthEvent {
  final String phone;
  final String otp;
  const AuthVerifyOTPPressed(this.phone, this.otp);

  @override
  List<Object> get props => [phone, otp];
}

class AuthLogoutPressed extends AuthEvent {}

class AuthCheckStatus extends AuthEvent {}
