import 'package:permission_handler/permission_handler.dart';
import 'package:injectable/injectable.dart';

class HealthCheck {
  final String label;
  final String description;
  final bool isHealthy;

  HealthCheck({
    required this.label,
    required this.description,
    required this.isHealthy,
  });
}

@LazySingleton()
class SystemHealthService {
  Future<List<HealthCheck>> performFullDiagnostics() async {
    final checks = <HealthCheck>[];

    // 1. Location Background
    final locationStatus = await Permission.locationAlways.status;
    checks.add(HealthCheck(
      label: 'Background Location',
      description: 'Required for constant SOS tracking even if app is closed.',
      isHealthy: locationStatus.isGranted,
    ));

    // 2. Microphone
    final micStatus = await Permission.microphone.status;
    checks.add(HealthCheck(
      label: 'Microphone Output',
      description: 'Required for covert audio evidence capture during SOS.',
      isHealthy: micStatus.isGranted,
    ));

    // 3. Camera (Covert)
    final camStatus = await Permission.camera.status;
    checks.add(HealthCheck(
      label: 'Covert Camera Activation',
      description: 'Used to take silent front-camera burst photos automatically.',
      isHealthy: camStatus.isGranted,
    ));

    // 4. Bluetooth Mesh Network
    final bleStatus = await Permission.bluetooth.status;
    final bleScanStatus = await Permission.bluetoothScan.status;
    checks.add(HealthCheck(
      label: 'Offline BLE Mesh',
      description: 'Allows SOS broadcast without 4G/Cellular coverage.',
      isHealthy: bleStatus.isGranted && bleScanStatus.isGranted,
    ));

    // 5. Battery Optimization Exempt
    // Denied means we are restricted (bad). Granted means we can ignore battery limits (good).
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    checks.add(HealthCheck(
      label: 'Unrestricted Background Run',
      description: 'Prevents the OS from killing the safety tracking to save battery.',
      isHealthy: batteryStatus.isGranted,
    ));

    return checks;
  }
}
