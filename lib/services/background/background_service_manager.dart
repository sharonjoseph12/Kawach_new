import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:kawach/features/evidence/data/evidence_audio_pipeline.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:telephony/telephony.dart';

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

    ActivityType currentActivity = ActivityType.UNKNOWN;
    try {
      FlutterActivityRecognition.instance.activityStream.listen((activity) {
        currentActivity = activity.type;
        debugPrint('Activity changed: ${activity.type}');
      });
    } catch (_) {}

    // ── Main GPS monitoring loop ──────────────────────────────────────────────
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (currentActivity == ActivityType.STILL) {
        return; // Hibernate to save battery
      }
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
              
              await _insertBackgroundSos(
                uid: uid,
                lat: pos?.latitude ?? 0.0,
                lng: pos?.longitude ?? 0.0,
                batteryLevel: batteryLevel,
                triggerType: 'dead_battery',
                origin: 'background_isolate_critical_battery',
              );
              
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

          // Broadcast location update for live guardian tracking (UI only)
          service.invoke('locationUpdate', {
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          });

          // THE LOCAL BLACK-BOX PROTOCOL
          // Save locally instead of uploading to cloud to reduce surveillance anxiety
          try {
            final prefs = await SharedPreferences.getInstance();
            final historyJson = prefs.getStringList('black_box_gps_history') ?? [];
            
            final newPoint = jsonEncode({
              'lat': position.latitude,
              'lng': position.longitude,
              'time': DateTime.now().toIso8601String(),
            });
            
            historyJson.add(newPoint);
            
            // Keep only the last 15 minutes (approx 60 points at 15s intervals)
            if (historyJson.length > 60) {
              historyJson.removeAt(0);
            }
            
            await prefs.setStringList('black_box_gps_history', historyJson);
          } catch (_) {}
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
            
            await _insertBackgroundSos(
              uid: uid,
              lat: pos?.latitude ?? 0.0,
              lng: pos?.longitude ?? 0.0,
              batteryLevel: await battery.batteryLevel,
              triggerType: 'hard_fall',
              origin: 'background_isolate',
            );
            
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

    // ── AI Anomaly Detection (Gemini) ──────────────────────────────────────────
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final batteryLevel = await battery.batteryLevel;
        Position? pos;
        try { pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low).timeout(const Duration(seconds: 5)); } catch (_) {}
        
        final uid = Supabase.instance.client.auth.currentUser?.id;
        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY');
        
        if (uid != null && apiKey.isNotEmpty) {
          final model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: apiKey,
          );
          
          final prompt = '''
Analyze this ambient user data for anomalies:
Location: ${pos?.latitude}, ${pos?.longitude}
Battery: $batteryLevel%
Time: ${DateTime.now().toIso8601String()}

If the user is in extreme danger based on patterns, return [TRIGGER_SOS]. Otherwise return [SAFE].
''';
          final response = await model.generateContent([Content.text(prompt)]);
          if (response.text?.contains('[TRIGGER_SOS]') == true) {
             // trigger SOS
             await _insertBackgroundSos(
              uid: uid,
              lat: pos?.latitude ?? 0.0,
              lng: pos?.longitude ?? 0.0,
              batteryLevel: batteryLevel,
              triggerType: 'ai_behavioral',
              origin: 'background_isolate',
            );
            await flutterLocalNotificationsPlugin.show(
              892,
              'KAWACH: AI Guardian Alert!',
              'AI detected anomalous behavioral patterns. SOS triggered.',
              const NotificationDetails(android: AndroidNotificationDetails('kawach_alerts', 'High Priority Alerts', importance: Importance.max, priority: Priority.high, color: Colors.red)),
            );
          }
        }
      } catch (e, st) {
        await Sentry.captureException(e, stackTrace: st, hint: Hint.withMap({'context': 'ai_anomaly_detection'}));
      }
    });

    // ── AI Anomaly Detection (Gemini) ──────────────────────────────────────────
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final batteryLevel = await battery.batteryLevel;
        Position? pos;
        try { pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low).timeout(const Duration(seconds: 5)); } catch (_) {}
        
        final uid = Supabase.instance.client.auth.currentUser?.id;
        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY');
        
        if (uid != null && apiKey.isNotEmpty) {
          final model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: apiKey,
          );
          
          final prompt = '''
Analyze this ambient user data for anomalies:
Location: ${pos?.latitude}, ${pos?.longitude}
Battery: $batteryLevel%
Time: ${DateTime.now().toIso8601String()}

If the user is in extreme danger based on patterns, return [TRIGGER_SOS]. Otherwise return [SAFE].
''';
          final response = await model.generateContent([Content.text(prompt)]);
          if (response.text?.contains('[TRIGGER_SOS]') == true) {
             // trigger SOS
             await _insertBackgroundSos(
              uid: uid,
              lat: pos?.latitude ?? 0.0,
              lng: pos?.longitude ?? 0.0,
              batteryLevel: batteryLevel,
              triggerType: 'ai_behavioral',
              origin: 'background_isolate',
            );
            await flutterLocalNotificationsPlugin.show(
              892,
              'KAWACH: AI Guardian Alert!',
              'AI detected anomalous behavioral patterns. SOS triggered.',
              const NotificationDetails(android: AndroidNotificationDetails('kawach_alerts', 'High Priority Alerts', importance: Importance.max, priority: Priority.high, color: Colors.red)),
            );
          }
        }
      } catch (e, st) {
        await Sentry.captureException(e, stackTrace: st, hint: Hint.withMap({'context': 'ai_anomaly_detection'}));
      }
    });
}

Future<void> _flushSosQueue() async {
    try {
      // Flush offline encrypted audio files
      await EvidenceAudioPipeline().uploadPending();
      
      // Read from the same StringList that SosQueueManager writes to
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList('kawach_sos_offline_queue') ?? [];
      if (queue.isEmpty) return;
      
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      
      final remaining = <String>[];
      
      for (final entry in queue) {
        try {
          final Map<String, dynamic> data = jsonDecode(entry);
          await _insertBackgroundSos(
            uid: uid,
            lat: (data['latitude'] as num?)?.toDouble() ?? 0.0,
            lng: (data['longitude'] as num?)?.toDouble() ?? 0.0,
            batteryLevel: (data['battery_pct'] as num?)?.toInt() ?? 0,
            triggerType: data['trigger_type'] as String? ?? 'offline_queue',
            origin: 'offline_queue',
          );
        } catch (e) {
          remaining.add(entry); // keep failed ones for next retry
        }
      }
      
      await prefs.setStringList('kawach_sos_offline_queue', remaining);
    } catch (_) {
      // Silently ignore if flushing fails; retry next cycle
    }
  }

/// Standardized SOS insert for background isolate — ensures consistent columns.
Future<void> _insertBackgroundSos({
  required String uid,
  required double lat,
  required double lng,
  required int batteryLevel,
  required String triggerType,
  required String origin,
}) async {
  // Push the actual SOS alert
  await Supabase.instance.client.from('sos_alerts').insert({
    'user_id': uid,
    'latitude': lat,
    'longitude': lng,
    'battery_pct': batteryLevel,
    'trigger_type': triggerType,
    'status': 'triggered',
    'origin': origin,
    'created_at': DateTime.now().toIso8601String(),
  });

  // Now that SOS is triggered, push the live location to the cloud tracker
  try {
    await Supabase.instance.client.from('sos_live_location').upsert({
      'user_id': uid,
      'latitude': lat,
      'longitude': lng,
      'battery_pct': batteryLevel,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  } catch (_) {}

  // HACKATHON FIX: Native local SMS fallback to guarantee messages are sent
  try {
    final guardianData = await Supabase.instance.client.from('guardians').select('contact_phone').eq('user_id', uid);
    final telephony = Telephony.instance;
    
    // In background isolates, we cannot request permissions via UI. 
    // We assume it was granted on app startup via main.dart
    bool permissionsGranted = await Permission.sms.isGranted;
    
    if (permissionsGranted) {
      String googleMapsLink = "https://maps.google.com/?q=$lat,$lng";
      String message = "SOS! I am in danger. My battery is $batteryLevel%. Location: $googleMapsLink";
      
      for (var g in guardianData) {
        final phone = g['contact_phone'] as String?;
        if (phone != null && phone.isNotEmpty) {
          await telephony.sendSms(to: phone, message: message);
          debugPrint('KAWACH BACKGROUND: Sent native SMS to $phone');
        }
      }
    } else {
      debugPrint('KAWACH BACKGROUND: SMS permission not granted, skipping native SMS');
    }
  } catch (e) {
    debugPrint('KAWACH BACKGROUND: Native SMS send failed - $e');
  }
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
