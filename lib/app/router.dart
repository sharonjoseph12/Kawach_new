import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kawach/features/auth/presentation/pages/phone_input_page.dart';
import 'package:kawach/features/auth/presentation/pages/otp_page.dart';
import 'package:kawach/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:kawach/features/home/presentation/pages/home_page.dart';
import 'package:kawach/features/sos/presentation/pages/sos_active_page.dart';
import 'package:kawach/features/sos/presentation/pages/sos_history_page.dart';
import 'package:kawach/features/guardians/presentation/pages/guardians_page.dart';
import 'package:kawach/features/map/presentation/pages/map_page.dart';
import 'package:kawach/features/fake_call/presentation/pages/fake_call_page.dart';
import 'package:kawach/features/fake_call/presentation/pages/fake_call_incoming_page.dart';
import 'package:kawach/features/safe_walk/presentation/pages/safe_walk_page.dart';
import 'package:kawach/features/diagnostics/presentation/pages/diagnostics_page.dart';
import 'package:kawach/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:kawach/features/evidence/presentation/pages/evidence_vault_page.dart';
import 'package:kawach/features/settings/presentation/pages/settings_page.dart';
import 'package:kawach/features/ai/guardian_ai/guardian_ai_page.dart';
import 'package:kawach/features/community/presentation/pages/community_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_state.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    // Start at '/' — the redirect logic decides where to go
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final location = state.matchedLocation;

      final prefs = getIt<SharedPreferences>();

      // ── Step 1: Check onboarding ────────────────────────────────────
      final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
      if (!onboardingDone) {
        // Allow staying on onboarding page
        if (location == '/onboarding') return null;
        return '/onboarding';
      }

      // ── Step 2: Check authentication ─────────────────────────────────
      // Use currentUser (persisted by Supabase SDK across app restarts)
      // Do NOT check session.isExpired — Supabase auto-refreshes tokens
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;

      // Not logged in → force to /phone (but allow /otp too)
      if (!isLoggedIn) {
        if (location == '/phone' || location.startsWith('/otp')) return null;
        return '/phone';
      }

      // ── Step 3: Logged in — redirect away from auth pages ───────────
      if (location == '/phone' || location.startsWith('/otp')) {
        return '/';
      }

      // ── Step 4: SOS state resurrection ──────────────────────────────
      try {
        if (getIt<SosBloc>().state is SosActive && location != '/sos_active') {
          return '/sos_active';
        }
      } catch (_) {}

      // ── Step 5: First-time profile setup ────────────────────────────
      if (location != '/profile') {
        final profileDone = prefs.getBool('profile_setup_done') ?? false;
        if (!profileDone) {
          try {
            final res = await Supabase.instance.client
                .from('users_profiles')
                .select('full_name')
                .eq('id', user.id)
                .maybeSingle();
            final name = res?['full_name'] as String?;
            if (name == null || name.trim().isEmpty) {
              return '/profile';
            } else {
              await prefs.setBool('profile_setup_done', true);
            }
          } catch (_) {
            // Network error — don't block the user, let them in
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/phone',
        builder: (context, state) => const PhoneInputPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          if (phone.isEmpty) {
            // Safety: shouldn't happen, but don't crash — show phone page
            return const PhoneInputPage();
          }
          return OTPPage(phone: phone);
        },
      ),
      GoRoute(
        path: '/sos_active',
        builder: (context, state) => const SosActivePage(),
      ),
      GoRoute(
        path: '/guardians',
        builder: (context, state) => const GuardiansPage(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: '/safe-walk',
        builder: (context, state) => const SafeWalkPage(),
      ),
      GoRoute(
        path: '/fake-call',
        builder: (context, state) => const FakeCallPage(),
        routes: [
          GoRoute(
            path: 'incoming',
            builder: (context, state) {
              final callerName = state.extra as String? ?? 'Mom';
              return FakeCallIncomingPage(callerName: callerName);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/guardian-ai',
        builder: (context, state) => const GuardianAIPage(),
      ),
      GoRoute(
        path: '/evidence',
        builder: (context, state) => const EvidenceVaultPage(),
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/sos-history',
        builder: (context, state) => const SosHistoryPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const DiagnosticsPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
    ],
  );
}
