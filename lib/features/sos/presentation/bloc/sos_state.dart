import 'package:equatable/equatable.dart';
import '../../domain/entities/sos_alert.dart';

abstract class SosState extends Equatable {
  const SosState();
  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {}

class SosTriggering extends SosState {}

class SosActive extends SosState {
  final SosAlert alert;
  final double currentLat;
  final double currentLng;
  final int evidenceCount;

  const SosActive({
    required this.alert,
    required this.currentLat,
    required this.currentLng,
    this.evidenceCount = 0,
  });

  @override
  List<Object?> get props => [alert, currentLat, currentLng, evidenceCount];
}

class SosCancelling extends SosState {}

class SosResolved extends SosState {}

class SosError extends SosState {
  final String message;
  const SosError(this.message);
  @override
  List<Object?> get props => [message];
}
