import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:kawach/core/error/failures.dart';
import 'package:kawach/features/auth/domain/auth_repository.dart';
import 'auth_remote_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, void>> sendOTP(String phone) async {
    try {
      await _remoteDataSource.sendOTP(phone);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOTP(String phone, String otp) async {
    try {
      await _remoteDataSource.verifyOTP(phone, otp);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _remoteDataSource.isAuthenticated();
  }
}
