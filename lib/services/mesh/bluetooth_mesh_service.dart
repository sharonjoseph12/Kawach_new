import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service to handle decentralized SOS broadcasting and scanning via BLE
class BluetoothMeshService {
  // A unique namespace UUID for Kawach Mesh beacons
  static const String _kawachBleServiceUuid = '11223344-5566-7788-99aa-bbccddeeff00';

  static bool _isScanning = false;

  /// Starts advertising an SOS beacon.
  /// (In a full production build, this requires the `flutter_ble_peripheral` package 
  ///  or native channel code. Mocked here for structural integrity).
  static Future<void> startDistressBeacon({
    required double lat,
    required double lng,
  }) async {
    debugPrint('🚨 [MESH] Activating BLE Distress Beacon...');
    final payload = jsonEncode({'l': lat, 'g': lng, 'sos': true});
    debugPrint('🚨 [MESH] Broadcasting Payload: $payload on UUID: $_kawachBleServiceUuid');
    
    // Fallback/Mock logic: usually would invoke BLE Peripheral Advertising here.
    // e.g., FlutterBlePeripheral().start(AdvertiseData(...));
  }

  /// Low-power background/foreground scanner looking for other Kawach users' SOS beacons.
  static Future<void> startRescueScanner({
    required Function(double lat, double lng) onDistressSignalReceived,
  }) async {
    if (_isScanning) return;

    if (await FlutterBluePlus.isSupported == false) {
      debugPrint('BLE is not supported on this device.');
      return;
    }

    // Ensure Bluetooth is ON
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      debugPrint('Bluetooth is off. Cannot start Mesh Scanner.');
      return;
    }

    _isScanning = true;
    debugPrint('📡 [MESH] Starting Rescue Scanner...');

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Look for the Kawach Service UUID
        final serviceUuids = r.advertisementData.serviceUuids;
        if (serviceUuids.any((uuid) => uuid.toString() == _kawachBleServiceUuid)) {
          debugPrint('‼️ [MESH] DISTRESS SIGNAL DETECTED FROM PEER!');
          
          // In reality, we extract Manufacturer Data. Using mock extraction:
          try {
            // Mocking extracted coordinates from Manufacturer Data
            // Map<int, List<int>> mData = r.advertisementData.manufacturerData;
            const mockLat = 12.9716;
            const mockLng = 77.5946;
            
            _isScanning = false;
            FlutterBluePlus.stopScan();
            onDistressSignalReceived(mockLat, mockLng);
            break;
          } catch (e) {
            debugPrint('Failed to parse peer payload: $e');
          }
        }
      }
    });

    // Start scanning (Filters help battery life, but open scan used for demo)
    await FlutterBluePlus.startScan(timeout: const Duration(minutes: 5));
  }

  static void stopRescueScanner() {
    _isScanning = false;
    FlutterBluePlus.stopScan();
    debugPrint('📡 [MESH] Rescue Scanner Stopped.');
  }
}
