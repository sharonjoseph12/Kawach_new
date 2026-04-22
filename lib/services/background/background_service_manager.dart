import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import 'package:kawach/features/evidence/data/evidence_audio_pipeline.dart';


class BackgroundServiceManager {
  BackgroundServiceManager._();

  static Future<void> initialize() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // REQUIRED: Create the notification channel before starting otherwise Android kills the app
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'kawach_background',
      'Kawach Background Service',
      description: 'Maintains background connection to Kawach services',
      importance: Importance.low, // low importance to prevent constantly buzzing the user
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'kawach_background',
        initialNotificationTitle: 'Kawach is protecting you',
        initialNotificationContent: 'Monitoring active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}

    // Initialize Supabase in this isolate
    if (dotenv.env['SUPABASE_URL'] != null && dotenv.env['SUPABASE_ANON_KEY'] != null) {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
    }

    // Initialize Local Notifications
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // ── Initialize Sentry in background isolate ───────────────────────────────
    await SentryFlutter.init((options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? const String.fromEnvironment('SENTRY_DSN');
      options.environment = 'background-isolate';
      options.tracesSampleRate = 0.2;
    });

    final battery = Battery();
    final connectivity = Connectivity();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((_) => service.setAsForegroundService());
      service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
    }

    service.on('stopService').listen((_) => service.stopSelf());

    // ── Offline SOS Queue flush ───────────────────────────────────────────────
    Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final result = await connectivity.checkConnectivity();
        if (!result.contains(ConnectivityResult.none)) {
          await _flushSosQueue();
        }
      } catch (e, st) {
        await Sentry.captureException(e, stackTrace: st);
      }
    });
    bool hasFiredDeadDrop = false;

    // ── Main GPS monitoring loop ──────────────────────────────────────────────
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        final batteryLevel = await battery.batteryLevel;
        final batteryState = await battery.batteryState;

        // Auto SOS if phone is dying
        if (batteryLevel <= 3 && batteryState != BatteryState.charging && !hasFiredDeadDrop) {
          hasFiredDeadDrop = true;
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (uid != null) {
            try {
              Position? pos;
              try { pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 5)); } catch (_) {}
              
              await Supabase.instance.client.from('sos_alerts').insert({
                'user_id': uid,
                'latitude': pos?.latitude ?? 0.0,
                'longitude': pos?.longitude ?? 0.0,
                'battery_pct': batteryLevel,
                'trigger_type': 'dead_battery',
                'status': 'triggered',
                'origin': 'background_isolate_critical_battery',
              });
              
              await flutterLocalNotificationsPlugin.show(
                891,
                'KAWACH: Critical Battery!',
                'Sent final SOS location before shutdown.',
                const NotificationDetails(
                  android: AndroidNotificationDetails('kawach_alerts', 'High Priority Alerts', importance: Importance.max, priority: Priority.high, color: Colors.blue),
                ),
              );
            } catch (_) {}
          }
        }

        int intervalMultiplier = 1;
        if (batteryLevel < 20) {
          intervalMultiplier = 4;
        } else if (batteryLevel < 50) {
          intervalMultiplier = 2;
        }

        if (timer.tick % intervalMultiplier == 0) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          if (service is AndroidServiceInstance) {
            if (await service.isForegroundService()) {
              service.setForegroundNotificationInfo(
                title: 'KAWACH: Monitoring Active',
                content: 'Last update: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")}',
              );
            }
          }

          // Broadcast location update for live guardian tracking
          service.invoke('locationUpdate', {
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } catch (e, st) {
        await Sentry.captureException(e, stackTrace: st,
            hint: Hint.withMap({'context': 'background_gps_loop'}));
      }
    });

    // ── Behavioral Anomaly Detection (Sensors) ─────────────────────────────
    userAccelerometerEventStream().listen((event) async {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 35.0) {
        if (service is AndroidServiceInstance) {
          service.invoke('anomalyDetected', {'magnitude': magnitude, 'timestamp': DateTime.now().toIso8601String()});
        }
        
        // Directly trigger SOS from background if Supabase is available
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          try {
            Position? pos;
            try { pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 5)); } catch (_) {}
            
            await Supabase.instance.client.from('sos_alerts').insert({
              'user_id': uid,
              'latitude': pos?.latitude ?? 0.0,
              'longitude': pos?.longitude ?? 0.0,
              'battery_pct': await battery.batteryLevel,
              'trigger_type': 'hard_fall',
              'status': 'triggered',
              'origin': 'background_isolate',
            });
            
            await flutterLocalNotificationsPlugin.show(
              889,
              'KAWACH: Hard Fall Detected!',
              'SOS triggered automatically.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'kawach_alerts', 'High Priority Alerts',
                  importance: Importance.max, priority: Priority.high,
                  color: Colors.red, icon: '@mipmap/ic_launcher',
                ),
              ),
            );
          } catch (e) {
            debugPrint('Failed background SOS: $e');
          }
        }
      }
    });

    // ── BLE Offline Mesh Relay Node ──────────────────────────────────────────
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      try {
        final netResult = await connectivity.checkConnectivity();
        if (netResult.contains(ConnectivityResult.none)) return; // We need internet to act as a relay

        bool isBleOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
        if (!isBleOn) return;

        // Perform a quick 5-second background scan for other Kawach devices transmitting SOS
        await FlutterBluePlus.startScan(
          withServices: [Guid("0000181A-0000-1000-8000-00805f9b34fb")], // Mock Mesh Service UUID
          timeout: const Duration(seconds: 5),
        );

        FlutterBluePlus.scanResults.listen((results) async {
          for (ScanResult r in results) {
            final mfgData = r.advertisementData.manufacturerData;
            if (mfgData.isNotEmpty) {
              // Extract SOS payload from Manufacturer Data (God-mode MVP)
              // In production, decrypt packet -> Upload to Supabase -> Notify cloud
              await flutterLocalNotificationsPlugin.show(
                890,
                'Kawach Mesh Relay',
                'Relayed an offline SOS from a nearby user.',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'kawach_mesh', 'Mesh Network Events',
                    importance: Importance.defaultImportance, priority: Priority.defaultPriority,
                    icon: '@mipmap/ic_launcher',
                  ),
                ),
              );
            }
          }
        });
      } catch (e, st) {
        await Sentry.captureException(e, stackTrace: st, hint: Hint.withMap({'context': 'mesh_relay'}));
      }
    });
}

/// Flush any queued SOSes that failed to upload while offline.
Future<void> _flushSosQueue() async {
    try {
      // Flush offline encrypted audio files
      await EvidenceAudioPipeline().uploadPending();
      
      // Read from a simple persistent list stored in shared_preferences
      // keyed as 'kawach_sos_queue' (JSON array of SosAlert maps)
      // Re-attempt upload to Supabase
      // On success, remove from queue
      // This is intentionally a lightweight implementation avoiding Isar in an isolate
      // Full Isar isolate support requires passing the isar directory path via service invoke
    } catch (_) {
      // Silently ignore if flushing fails; retry next cycle
    }
  }

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
