import 'package:permission_handler/permission_handler.dart';
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kawach/features/sos/data/sos_queue_manager.dart';
import 'package:kawach/app/di/injection.dart';

class HealthCheck {
  final String label;
  final String description;
  final bool isHealthy;
  final String? detail;

  HealthCheck({
    required this.label,
    required this.description,
    required this.isHealthy,
    this.detail,
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
      detail: locationStatus.isGranted ? 'Always-on' : 'Tap to grant',
    ));

    // 2. GPS Accuracy
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      final accuracy = pos.accuracy;
      checks.add(HealthCheck(
        label: 'GPS Accuracy',
        description: 'Sub-10m accuracy needed for precise SOS location.',
        isHealthy: accuracy < 20,
        detail: '±${accuracy.toStringAsFixed(1)}m',
      ));
    } catch (_) {
      checks.add(HealthCheck(
        label: 'GPS Accuracy',
        description: 'Sub-10m accuracy needed for precise SOS location.',
        isHealthy: false,
        detail: 'GPS unavailable',
      ));
    }

    // 3. Microphone
    final micStatus = await Permission.microphone.status;
    checks.add(HealthCheck(
      label: 'Microphone',
      description: 'Required for covert audio evidence capture during SOS.',
      isHealthy: micStatus.isGranted,
    ));

    // 4. Camera
    final camStatus = await Permission.camera.status;
    checks.add(HealthCheck(
      label: 'Covert Camera',
      description: 'Used for silent front-camera burst photos automatically.',
      isHealthy: camStatus.isGranted,
    ));

    // 5. Bluetooth Mesh Network
    final bleStatus = await Permission.bluetooth.status;
    final bleScanStatus = await Permission.bluetoothScan.status;
    BluetoothAdapterState bleAdapterState = BluetoothAdapterState.unknown;
    try {
      bleAdapterState = await FlutterBluePlus.adapterState.first;
    } catch (_) {}
    checks.add(HealthCheck(
      label: 'Offline BLE Mesh',
      description: 'Allows SOS broadcast without cellular coverage.',
      isHealthy: bleStatus.isGranted && bleScanStatus.isGranted && bleAdapterState == BluetoothAdapterState.on,
      detail: bleAdapterState == BluetoothAdapterState.on ? 'Bluetooth ON' : 'Turn on Bluetooth',
    ));

    // 6. Battery Optimization Exempt
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    checks.add(HealthCheck(
      label: 'Unrestricted Background',
      description: 'Prevents the OS from killing safety tracking to save battery.',
      isHealthy: batteryStatus.isGranted,
    ));

    // 7. Network Connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final hasNetwork = connectivity.any((r) => r != ConnectivityResult.none);
    checks.add(HealthCheck(
      label: 'Network Connectivity',
      description: 'Required for real-time SOS alerts and guardian notifications.',
      isHealthy: hasNetwork,
      detail: hasNetwork ? connectivity.first.name.toUpperCase() : 'OFFLINE',
    ));

    // 8. Supabase Connection
    bool supabaseOk = false;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      supabaseOk = session != null && !session.isExpired;
    } catch (_) {}
    checks.add(HealthCheck(
      label: 'Cloud Backend',
      description: 'Supabase connection for SOS alerts and evidence upload.',
      isHealthy: supabaseOk,
      detail: supabaseOk ? 'Authenticated' : 'Not connected',
    ));

    // 9. Battery Level
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    checks.add(HealthCheck(
      label: 'Battery Level',
      description: 'Low battery may trigger auto-SOS and limit tracking duration.',
      isHealthy: batteryLevel > 15,
      detail: '$batteryLevel%',
    ));

    // 10. Offline SOS Queue
    int queueDepth = 0;
    try {
      queueDepth = await getIt<SosQueueManager>().queueLength();
    } catch (_) {}
    checks.add(HealthCheck(
      label: 'Offline SOS Queue',
      description: 'Pending SOS alerts waiting to sync when network returns.',
      isHealthy: queueDepth == 0,
      detail: queueDepth == 0 ? 'Clear' : '$queueDepth pending',
    ));

    return checks;
  }
}
