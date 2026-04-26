import 'package:equatable/equatable.dart';
import '../../domain/entities/sos_alert.dart';

abstract class SosState extends Equatable {
  const SosState();
  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {}

class SosTriggering extends SosState {
  final int countdown;
  const SosTriggering({this.countdown = 15});
  
  @override
  List<Object?> get props => [countdown];
}

class SosActive extends SosState {
  final SosAlert alert;
  final double currentLat;
  final double currentLng;
  final int evidenceCount;
  final String? primaryGuardianPhone;

  const SosActive({
    required this.alert,
    required this.currentLat,
    required this.currentLng,
    this.evidenceCount = 0,
    this.primaryGuardianPhone,
  });

  @override
  List<Object?> get props => [alert, currentLat, currentLng, evidenceCount, primaryGuardianPhone];
}

class SosCancelling extends SosState {}

class SosResolved extends SosState {}

class SosError extends SosState {
  final String message;
  const SosError(this.message);
  @override
  List<Object?> get props => [message];
}
