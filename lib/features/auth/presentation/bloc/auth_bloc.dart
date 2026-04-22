import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthSendOTPPressed>((event, emit) async {
      emit(AuthLoading());
      final result = await _repository.sendOTP(event.phone);
      result.fold(
        (failure) => emit(AuthFailureState(failure.message)),
        (_) => emit(AuthCodeSent(event.phone)),
      );
    });

    on<AuthVerifyOTPPressed>((event, emit) async {
      emit(AuthLoading());
      final result = await _repository.verifyOTP(event.phone, event.otp);
      result.fold(
        (failure) => emit(AuthFailureState(failure.message)),
        (_) => emit(AuthAuthenticated()),
      );
    });

    on<AuthLogoutPressed>((event, emit) async {
      emit(AuthLoading());
      final result = await _repository.signOut();
      result.fold(
        (failure) => emit(AuthFailureState(failure.message)),
        (_) => emit(AuthUnauthenticated()),
      );
    });

    on<AuthCheckStatus>((event, emit) async {
      final isAuthenticated = await _repository.isAuthenticated();
      if (isAuthenticated) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }
}
