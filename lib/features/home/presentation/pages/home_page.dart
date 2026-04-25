import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:kawach/features/auth/data/profile_repository.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/core/services/safety_score_service.dart';
import 'package:kawach/core/services/demo_mode_service.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_event.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_state.dart';
import '../widgets/sos_button.dart';
import '../widgets/quick_actions_bar.dart';
import 'package:kawach/features/map/widgets/route_safety_sheet.dart';
import 'package:kawach/features/ai/audio/wake_word_service.dart';
import 'package:kawach/services/silent_sos/shake_detector.dart';
import 'package:kawach/services/silent_sos/gesture_sos_detector.dart';
import 'package:kawach/services/silent_sos/power_button_detector.dart';
import 'package:kawach/features/mesh/nearby_mesh_service.dart';
import 'package:kawach/app/di/injection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late WakeWordService _wakeWordService;
  late ShakeDetector _shakeDetector;
  late GestureSosDetector _gestureDetector;
  final _battery = Battery();
  int _batteryLevel = 100;
  String _userName = 'User';

  // Live safety score
  SafetyScore? _safetyScore;
  bool _scoreLoading = true;

  // Protection states
  bool _aiGuardianActive = false;
  bool _meshActive = false;
  bool _gpsActive = false;

  // Stats
  int _sosCount = 0;
  int _evidenceCount = 0;
  int _guardianCount = 0;

  @override
  void initState() {
    super.initState();
    _startWakeWordEngine();
    _startPhysicalTriggers();
    _loadUserData();
    _computeSafetyScore();
    _loadStats();
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

  Future<void> _loadStats() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final sos = await Supabase.instance.client.from('sos_alerts').select('id').eq('user_id', uid).count(CountOption.exact);
      final ev = await Supabase.instance.client.from('evidence_items').select('id').eq('user_id', uid).count(CountOption.exact);
      final gd = await Supabase.instance.client.from('guardians').select('id').eq('user_id', uid).count(CountOption.exact);
      if (mounted) {
        setState(() {
          _sosCount = sos.count;
          _evidenceCount = ev.count;
          _guardianCount = gd.count;
        });
      }
    } catch (_) {}
  }

  Future<void> _computeSafetyScore() async {
    try {
      final score = await getIt<SafetyScoreService>().computeScore();
      if (mounted) {
        setState(() {
          _safetyScore = score;
          _scoreLoading = false;
          // Derive protection states from score factors
          _gpsActive = score.factors.any((f) => f.label == 'GPS Active' && f.isPositive);
          // Check if mesh relay is running
          try {
            _meshActive = getIt.isRegistered<NearbyMeshService>();
          } catch (_) {}
        });
      }
    } catch (_) {
      if (mounted) setState(() => _scoreLoading = false);
    }
  }

  Future<void> _startWakeWordEngine() async {
    _wakeWordService = WakeWordService();
    final isAvailable = await _wakeWordService.initialize();
    if (mounted) setState(() => _aiGuardianActive = isAvailable);
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

  Color _riskColor() {
    if (_safetyScore == null) return AppColors.warning;
    switch (_safetyScore!.riskLevel) {
      case 'safe': return AppColors.safe;
      case 'moderate': return AppColors.warning;
      case 'high': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  String _riskLabel() {
    if (_safetyScore == null) return 'Analyzing...';
    switch (_safetyScore!.riskLevel) {
      case 'safe': return 'Safe Area';
      case 'moderate': return 'Moderate Risk';
      case 'high': return 'High Risk Area';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final demoMode = getIt<DemoModeService>().isActive;

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
            child: Stack(
              children: [
                Column(
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
                      _AnimatedRiskBadge(riskLevel: _safetyScore?.riskLevel ?? 'moderate'),
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
                        Row(
                          children: [
                            Text('ACTIVE PROTECTION', style: GoogleFonts.orbitron(fontSize: 10, letterSpacing: 1.5, color: AppColors.textSecondary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.safe.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.safe,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: AppColors.safe.withValues(alpha: 0.5), blurRadius: 4)],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('ALL SYSTEMS', style: GoogleFonts.orbitron(fontSize: 8, color: AppColors.safe, letterSpacing: 1)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _PulsingStatusIndicator(label: 'AI Guardian', isActive: _aiGuardianActive),
                            _PulsingStatusIndicator(label: 'Mesh Node', isActive: _meshActive),
                            _PulsingStatusIndicator(label: 'GPS Lock', isActive: _gpsActive),
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

                const SizedBox(height: 24),
                
                // ── Quick Stats ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatCounter(label: 'SOS Events', value: _sosCount),
                      Container(width: 1, height: 24, color: AppColors.textSecondary.withValues(alpha: 0.2)),
                      _StatCounter(label: 'Evidence', value: _evidenceCount),
                      Container(width: 1, height: 24, color: AppColors.textSecondary.withValues(alpha: 0.2)),
                      _StatCounter(label: 'Guardians', value: _guardianCount),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Live Area Safety Card ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GestureDetector(
                    onTap: () => context.push('/map'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _riskColor().withValues(alpha: 0.2), width: 1),
                      ),
                      child: _scoreLoading
                          ? _buildScoreLoading()
                          : _buildLiveScore(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Fake Call ────────────────────────────────────
                _FeatureCard(
                  icon: Icons.call_outlined,
                  iconColor: Colors.blueAccent,
                  title: 'Fake Call Deterrent',
                  subtitle: 'Simulate incoming call to deter attackers',
                  onTap: () => context.push('/fake-call/incoming', extra: 'Police Control Room'),
                ),

                const SizedBox(height: 12),

                // ── Guardian AI ────────────────────────────────────
                _FeatureCard(
                  icon: Icons.smart_toy_rounded,
                  iconColor: AppColors.primary,
                  title: 'Guardian AI',
                  subtitle: 'Chat with your 24/7 AI safety assistant',
                  onTap: () => context.push('/guardian-ai'),
                ),

                const SizedBox(height: 12),

                // ── Route Safety Check ────────────────────────────────────
                _FeatureCard(
                  icon: Icons.route,
                  iconColor: AppColors.safe,
                  title: 'Route Safety Check',
                  subtitle: 'Scan your route for risk zones before walking',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const RouteSafetySheet(),
                  ),
                ),

                const SizedBox(height: 12),

                // ── System Diagnostics ────────────────────────────────────
                _FeatureCard(
                  icon: Icons.verified_user,
                  iconColor: AppColors.safe,
                  title: 'System Diagnostics',
                  subtitle: 'Verify all protection systems are armed',
                  onTap: () => context.push('/diagnostics'),
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
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.08))),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, -2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
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
                ),
              ],
            ),

                // Demo mode badge
                if (demoMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('DEMO', style: GoogleFonts.orbitron(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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

  Widget _buildScoreLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.card,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLiveScore() {
    final score = _safetyScore!;
    final color = _riskColor();
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shield_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_riskLabel(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    '${score.factors.where((f) => !f.isPositive).length} risk factors detected',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text('${score.score}', style: GoogleFonts.orbitron(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score.score / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Show top 2 risk factors as chips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: score.factors.take(3).map((f) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (f.isPositive ? AppColors.safe : AppColors.warning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  f.isPositive ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  size: 12,
                  color: f.isPositive ? AppColors.safe : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(f.label, style: TextStyle(fontSize: 10, color: f.isPositive ? AppColors.safe : AppColors.warning, fontWeight: FontWeight.w600)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ─── Reusable Feature Card ─────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: iconColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.38)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing Status Indicator ──────────────────────────────────────
class _PulsingStatusIndicator extends StatefulWidget {
  final String label;
  final bool isActive;

  const _PulsingStatusIndicator({required this.label, required this.isActive});

  @override
  State<_PulsingStatusIndicator> createState() => _PulsingStatusIndicatorState();
}

class _PulsingStatusIndicatorState extends State<_PulsingStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (_, __) => Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: widget.isActive ? AppColors.safe : AppColors.textSecondary,
              shape: BoxShape.circle,
              boxShadow: widget.isActive
                  ? [BoxShadow(color: AppColors.safe.withValues(alpha: _glowAnimation.value), blurRadius: 8, spreadRadius: 2)]
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(widget.label, style: TextStyle(color: widget.isActive ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 11, fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

// ─── Animated Risk Badge ───────────────────────────────────────────
class _AnimatedRiskBadge extends StatelessWidget {
  final String riskLevel;

  const _AnimatedRiskBadge({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final color = riskLevel == 'safe' ? AppColors.safe
        : riskLevel == 'high' ? AppColors.danger
        : AppColors.warning;
    final label = riskLevel == 'safe' ? 'SAFE'
        : riskLevel == 'high' ? 'HIGH'
        : 'MOD';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.orbitron(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Nav Item ──────────────────────────────────────────────────────
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isActive ? AppColors.primary : AppColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isActive ? AppColors.primary : AppColors.textSecondary, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _StatCounter extends StatelessWidget {
  final String label;
  final int value;
  const _StatCounter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut,
          builder: (ctx, val, child) {
            return Text(
              val.toString(),
              style: GoogleFonts.orbitron(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1),
        ),
      ],
    );
  }
}
