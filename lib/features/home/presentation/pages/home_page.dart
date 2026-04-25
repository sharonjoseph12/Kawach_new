import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:kawach/features/auth/data/profile_repository.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_event.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_state.dart';
import '../widgets/sos_button.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/quick_actions_bar.dart';
import 'package:kawach/features/map/widgets/route_safety_sheet.dart';
import 'package:kawach/features/ai/audio/wake_word_service.dart';
import 'package:kawach/services/silent_sos/shake_detector.dart';
import 'package:kawach/services/silent_sos/gesture_sos_detector.dart';
import 'package:kawach/services/silent_sos/power_button_detector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WakeWordService _wakeWordService;
  late ShakeDetector _shakeDetector;
  late GestureSosDetector _gestureDetector;
  final _battery = Battery();
  int _batteryLevel = 100;
  String _userName = 'Sharon';

  @override
  void initState() {
    super.initState();
    _startWakeWordEngine();
    _startPhysicalTriggers();
    _loadUserData();
  }

  void _startPhysicalTriggers() {
    _shakeDetector = ShakeDetector(onShakeDetected: _triggerSosFromPhysical);
    _shakeDetector.start();
    _gestureDetector = GestureSosDetector(onTrigger: _triggerSosFromPhysical);
    _gestureDetector.start();
    PowerButtonDetector.sosTriggered.listen((_) => _triggerSosFromPhysical());
  }

  void _triggerSosFromPhysical() {
    if (mounted) {
      final currentState = context.read<SosBloc>().state;
      if (currentState is! SosActive && currentState is! SosTriggering) {
        context.read<SosBloc>().add(const SosTriggerPressed('physical_hardware'));
      }
    }
  }

  Future<void> _loadUserData() async {
    final name = await ProfileRepository().getDisplayName();
    final level = await _battery.batteryLevel;
    if (mounted) {
      setState(() {
        _userName = name;
        _batteryLevel = level;
      });
    }
  }

  Future<void> _startWakeWordEngine() async {
    _wakeWordService = WakeWordService();
    final isAvailable = await _wakeWordService.initialize();
    if (isAvailable) {
      _wakeWordService.startListening(
        onWakeWordDetected: () {
          if (mounted) {
            context.read<SosBloc>().add(const SosTriggerPressed('wake_word'));
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _wakeWordService.stopListening();
    _shakeDetector.stop();
    _gestureDetector.stop();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SosBloc, SosState>(
      listener: (context, state) {
        if (state is SosActive) {
          if (mounted) context.push('/sos_active');
        } else if (state is SosError) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: GestureOverlayWrapper(
        onTrigger: _triggerSosFromPhysical,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
          color: AppColors.background,
          child: SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.secondary],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text(_userName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.health_and_safety, color: AppColors.safe),
                        onPressed: () => context.push('/diagnostics'),
                      ),
                      const RiskIndicator(risk: 'moderate'),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ── Active Protection Dashboard ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.safe.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVE PROTECTION', style: GoogleFonts.orbitron(fontSize: 10, letterSpacing: 1.5, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _StatusIndicator(label: 'AI Guardian', isActive: true),
                            const _StatusIndicator(label: 'Mesh Node', isActive: true),
                            _StatusIndicator(label: 'Battery Saver', isActive: _batteryLevel > 15),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Battery warning (< 15%) ───────────────────────────
                if (_batteryLevel < 15)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.battery_alert, color: AppColors.danger, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Battery at $_batteryLevel% — SOS may fail if phone dies', style: const TextStyle(color: AppColors.danger, fontSize: 12))),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // ── SOS Button ────────────────────────────────────────
                BlocBuilder<SosBloc, SosState>(
                  builder: (context, state) {
                    final isActive = state is SosTriggering;
                    return Column(
                      children: [
                        SOSButton(
                          onTrigger: () {
                            context.read<SosBloc>().add(const SosTriggerPressed('manual'));
                          },
                        ),
                        const SizedBox(height: 12),
                        if (isActive)
                          Shimmer.fromColors(
                            baseColor: AppColors.danger,
                            highlightColor: Colors.white,
                            child: Text('TRIGGERING SOS...', style: GoogleFonts.orbitron(fontSize: 12, letterSpacing: 2)),
                          )
                        else
                          Text('PROTECTED BY KAWACH', style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 2)),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ── Area safety card ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GestureDetector(
                    onTap: () => context.push('/map'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Moderate Risk Area', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('3 incidents nearby · last 30d', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                                ),
                                child: Text('42', style: GoogleFonts.orbitron(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: 0.42,
                              backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                              Text('Safety: 42 / 100', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                              Text('100', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Test Fake Call ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GestureDetector(
                    onTap: () => context.push('/fake-call/incoming', extra: 'Police Control Room'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.call_outlined, color: Colors.blueAccent, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fake Call Deterrent', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Simulate incoming call to deter attackers', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.38)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Route Safety Check ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const RouteSafetySheet(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.safe.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.safe.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.route, color: AppColors.safe, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Route Safety Check', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Scan your route for risk zones before walking', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.38)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── System Diagnostics ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GestureDetector(
                    onTap: () => context.push('/diagnostics'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.safe.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.safe.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_user, color: AppColors.safe, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('System Diagnostics', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Verify all protection systems are armed', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.38)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Quick actions ─────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: QuickActionsBar(),
                ),

                const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Nav ────────────────────────────────────────
                Divider(color: AppColors.textSecondary.withValues(alpha: 0.1), height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(icon: Icons.home_rounded, label: 'Home', isActive: true, onTap: () {}),
                      _NavItem(icon: Icons.map_rounded, label: 'Map', onTap: () => context.push('/map')),
                      _NavItem(icon: Icons.groups_rounded, label: 'Community', onTap: () => context.push('/community')),
                      _NavItem(icon: Icons.folder_copy_rounded, label: 'Evidence', onTap: () => context.push('/evidence')),
                      _NavItem(icon: Icons.settings_rounded, label: 'Settings', onTap: () => context.push('/settings')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : AppColors.textSecondary, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isActive ? AppColors.primary : AppColors.textSecondary, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(height: 2),
          if (isActive) Container(width: 20, height: 2, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StatusIndicator({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.safe : AppColors.textSecondary,
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: AppColors.safe.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 2)] : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: isActive ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}
