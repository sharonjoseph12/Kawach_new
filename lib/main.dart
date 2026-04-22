import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:kawach/core/config/app_config.dart';
import 'package:kawach/core/database/local_database.dart';
import 'package:kawach/core/services/logger_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:kawach/services/background/background_service_manager.dart';
import 'package:kawach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:kawach/features/ai/guardian_ai/guardian_chat_service.dart';
import 'package:kawach/app/app.dart';
import 'package:kawach/core/widgets/app_error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('KAWACH: .env load failed — $e');
  }

  // Choose Env (Dev/Prod) based on build flavor
  final config = kReleaseMode ? AppConfig.prod() : AppConfig.dev();

  debugPrint('KAWACH: Config loaded. Supabase URL: ${config.supabaseUrl}');

  // Initialize HydratedBloc Storage
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );
  debugPrint('KAWACH: HydratedBloc ready');

  // Initialize Firebase (optional — needs google-services.json)
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
    debugPrint('KAWACH: Firebase ready');
  } catch (e) {
    debugPrint('KAWACH: Firebase skipped — $e');
  }

  // Initialize Supabase (skip if placeholder URL)
  try {
    if (config.supabaseUrl.isNotEmpty && !config.supabaseUrl.contains('YOUR_PROJECT')) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
      );
      debugPrint('KAWACH: Supabase ready');
    } else {
      debugPrint('KAWACH: Supabase skipped — placeholder URL detected');
    }
  } catch (e) {
    debugPrint('KAWACH: Supabase init failed — $e');
  }

  // Initialize Dependency Injection
  configureDependencies();
  debugPrint('KAWACH: DI ready');

  // Manual Register of AppConfig
  if (!getIt.isRegistered<AppConfig>()) {
    getIt.registerSingleton<AppConfig>(config);
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerSingleton<SharedPreferences>(prefs);
  }
  debugPrint('KAWACH: SharedPreferences ready');

  // Initialize Local DB
  try {
    await getIt<LocalDatabase>().initialize();
    debugPrint('KAWACH: LocalDB ready');
  } catch (e) {
    debugPrint('KAWACH: LocalDB failed — $e');
  }

  // Initialize Background Service
  try {
    await BackgroundServiceManager.initialize();
    debugPrint('KAWACH: BackgroundService ready');
  } catch (e) {
    debugPrint('KAWACH: BackgroundService failed — $e');
  }

  // Request Permissions on Startup
  await _requestAllPermissions();
  debugPrint('KAWACH: Permissions requested');

  // Flutter Error Boundary
  FlutterError.onError = (details) {
    debugPrint('KAWACH ERROR: ${details.exception}');
    if (getIt.isRegistered<LoggerService>()) {
      getIt<LoggerService>().error('Flutter Error', details.exception, details.stack);
    }
  };

  // Initialize Sentry (non-blocking — skip if no DSN)
  if (config.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = config.sentryDsn;
        options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
        options.enableAutoPerformanceTracing = true;
      },
      appRunner: () => _launchApp(),
    );
  } else {
    debugPrint('KAWACH: Sentry skipped — no DSN');
    _launchApp();
  }
}

void _launchApp() {
  // Listen for Supabase session expiry / sign-out and force re-login
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    if (event == AuthChangeEvent.signedOut ||
        event == AuthChangeEvent.tokenRefreshed && data.session == null) {
      // Clear persisted bloc state to avoid stale data on next login
      HydratedBloc.storage.clear();
      // Reset AI chat session so previous user's history doesn't leak
      if (getIt.isRegistered<GuardianChatService>()) {
        getIt<GuardianChatService>().resetSession();
      }
    }
  });

  runApp(
    AppErrorBoundary(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<AuthBloc>()),
          BlocProvider(create: (context) => getIt<SosBloc>()),
        ],
        child: const KawachApp(),
      ),
    ),
  );
}

Future<void> _requestAllPermissions() async {
  await [
    Permission.locationAlways,
    Permission.microphone,
    Permission.camera,
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.notification,
  ].request();

  // Android specific: ignore battery optimizations
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}
