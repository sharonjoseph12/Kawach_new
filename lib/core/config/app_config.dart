import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';

enum AppEnvironment { dev, prod, staging }

@lazySingleton
class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String geminiApiKey;
  final String sentryDsn;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.geminiApiKey,
    required this.sentryDsn,
  });

  @factoryMethod
  factory AppConfig.dev() => AppConfig(
        environment: AppEnvironment.dev,
        supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
        supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        geminiApiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        sentryDsn: dotenv.env['SENTRY_DSN'] ?? '',
      );

  factory AppConfig.prod() => AppConfig(
        environment: AppEnvironment.prod,
        supabaseUrl: dotenv.env['PROD_SUPABASE_URL'] ?? dotenv.env['SUPABASE_URL'] ?? '',
        supabaseAnonKey: dotenv.env['PROD_SUPABASE_ANON_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        geminiApiKey: dotenv.env['PROD_GEMINI_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'] ?? '',
        sentryDsn: dotenv.env['PROD_SENTRY_DSN'] ?? dotenv.env['SENTRY_DSN'] ?? '',
      );

  bool get isDev => environment == AppEnvironment.dev;
  bool get isProd => environment == AppEnvironment.prod;
}
