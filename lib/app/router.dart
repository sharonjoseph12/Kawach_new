import 'package:flutter/material.dart';
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
import 'package:kawach/features/splash/presentation/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_state.dart';

class AppRouter {
  AppRouter._();

  /// Smooth fade + slide transition for normal pages
  static CustomTransitionPage _fadeSlide(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
    );
  }

  /// Dramatic zoom transition for SOS page
  static CustomTransitionPage _zoomIn(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide-from-right for detail pages
  static CustomTransitionPage _slideRight(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  static final router = GoRouter(
    // Start at splash
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final location = state.matchedLocation;

      // Always allow splash
      if (location == '/splash') return null;

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
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashPage(),
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadeSlide(const HomePage(), state),
      ),
      GoRoute(
        path: '/phone',
        pageBuilder: (context, state) => _fadeSlide(const PhoneInputPage(), state),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) {
          final phone = state.extra as String? ?? '';
          if (phone.isEmpty) {
            return _fadeSlide(const PhoneInputPage(), state);
          }
          return _fadeSlide(OTPPage(phone: phone), state);
        },
      ),
      GoRoute(
        path: '/sos_active',
        pageBuilder: (context, state) => _zoomIn(const SosActivePage(), state),
      ),
      GoRoute(
        path: '/guardians',
        pageBuilder: (context, state) => _slideRight(const GuardiansPage(), state),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => _fadeSlide(const MapPage(), state),
      ),
      GoRoute(
        path: '/safe-walk',
        pageBuilder: (context, state) => _slideRight(const SafeWalkPage(), state),
      ),
      GoRoute(
        path: '/fake-call',
        pageBuilder: (context, state) => _fadeSlide(const FakeCallPage(), state),
        routes: [
          GoRoute(
            path: 'incoming',
            pageBuilder: (context, state) {
              final callerName = state.extra as String? ?? 'Mom';
              return _zoomIn(FakeCallIncomingPage(callerName: callerName), state);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/guardian-ai',
        pageBuilder: (context, state) => _slideRight(const GuardianAIPage(), state),
      ),
      GoRoute(
        path: '/evidence',
        pageBuilder: (context, state) => _slideRight(const EvidenceVaultPage(), state),
      ),
      GoRoute(
        path: '/community',
        pageBuilder: (context, state) => _fadeSlide(const CommunityPage(), state),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _slideRight(const SettingsPage(), state),
      ),
      GoRoute(
        path: '/sos-history',
        pageBuilder: (context, state) => _slideRight(const SosHistoryPage(), state),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _slideRight(const ProfileSetupPage(), state),
      ),
      GoRoute(
        path: '/diagnostics',
        pageBuilder: (context, state) => _slideRight(const DiagnosticsPage(), state),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeSlide(const OnboardingPage(), state),
      ),
    ],
  );
}
