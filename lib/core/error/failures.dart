abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class BleFailure extends Failure {
  const BleFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}
