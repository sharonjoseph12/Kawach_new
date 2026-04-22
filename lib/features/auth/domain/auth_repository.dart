import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> sendOTP(String phone);
  Future<Either<Failure, void>> verifyOTP(String phone, String otp);
  Future<Either<Failure, void>> signOut();
  Future<bool> isAuthenticated();
}
