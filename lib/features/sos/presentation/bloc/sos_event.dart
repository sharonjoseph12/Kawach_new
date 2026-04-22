import 'package:equatable/equatable.dart';


abstract class SosEvent extends Equatable {
  const SosEvent();
  @override
  List<Object?> get props => [];
}

class SosTriggerPressed extends SosEvent {
  final String triggerType;
  const SosTriggerPressed(this.triggerType);
  @override
  List<Object?> get props => [triggerType];
}

class SosCancelPressed extends SosEvent {
  final String reason;
  const SosCancelPressed(this.reason);
  @override
  List<Object?> get props => [reason];
}

class SosLocationUpdated extends SosEvent {
  final double lat;
  final double lng;
  const SosLocationUpdated(this.lat, this.lng);
  @override
  List<Object?> get props => [lat, lng];
}

class SosEvidenceCaptureDone extends SosEvent {
  final String evidenceId;
  const SosEvidenceCaptureDone(this.evidenceId);
  @override
  List<Object?> get props => [evidenceId];
}
