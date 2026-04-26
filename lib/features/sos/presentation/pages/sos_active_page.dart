import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_event.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_state.dart';
import 'package:kawach/features/siren/siren_service.dart';
import 'package:kawach/features/safe_walk/pin_service.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:url_launcher/url_launcher.dart';

class SosActivePage extends StatefulWidget {
  const SosActivePage({super.key});

  @override
  State<SosActivePage> createState() => _SosActivePageState();
}

class _SosActivePageState extends State<SosActivePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;
  late Timer _elapsedTimer;
  int _secondsElapsed = 0;
  bool _isStealthMode = false;
  int _stealthTaps = 0;
  double _previousBrightness = 0.5;
  bool _hasAutoCalled = false;

  void _handleAutoCall(SosActive state) async {
    if (_hasAutoCalled) return;
    _hasAutoCalled = true;

    debugPrint('KAWACH TACTICAL: SOS Active confirmed. Initializing emergency communication...');
    
    // 2-second tactical pause for the user to see the UI before dialer popup
    await Future.delayed(const Duration(milliseconds: 2000));
    
    final cleanNumber = (state.primaryGuardianPhone ?? '100').replaceAll(RegExp(r'[^0-9+]'), '');
    debugPrint('KAWACH TACTICAL: Target emergency number -> $cleanNumber');
    
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      // Force external application mode to guarantee dialer popup
      debugPrint('KAWACH TACTICAL: Launching Dialer (External)...');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('KAWACH TACTICAL: Emergency call trigger failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });

    // Keep screen on during SOS
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // AUTO-CALL TRIGGER: Ensure call starts even if page was pushed after state became active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<SosBloc>().state;
      if (state is SosActive) {
        _handleAutoCall(state);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _elapsedTimer.cancel();
    getIt<SirenService>().stopSiren();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _enableStealthMode() async {
    try {
      _previousBrightness = await ScreenBrightness().application;
      await ScreenBrightness().setApplicationScreenBrightness(0.0);
    } catch (_) {}
    setState(() {
      _isStealthMode = true;
      _stealthTaps = 0;
    });
  }

  Future<void> _disableStealthMode() async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(_previousBrightness);
    } catch (_) {}
    setState(() {
      _isStealthMode = false;
    });
  }

  Future<void> _restoreBrightness() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (_) {}
  }

  String _formatElapsed() {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _triggerTypeLabel(String type) {
    switch (type) {
      case 'manual': return 'Manual Button Press';
      case 'hardware_volume_button': return 'Volume Button (Pocket SOS)';
      case 'smartwatch_media': return 'Smartwatch Trigger';
      case 'hard_fall': return 'Fall Detection';
      case 'route_deviance': return 'Route Deviation Detected';
      case 'ai_behavioral': return 'AI Guardian Alert';
      case 'dead_battery': return 'Critical Battery Alert';
      case 'wake_word': return 'Voice Activation';
      case 'physical_hardware': return 'Physical Trigger';
      case 'coercion_duress_pin': return 'Duress Alert';
      default: return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _triggerTypeIcon(String type) {
    switch (type) {
      case 'manual': return Icons.touch_app;
      case 'hardware_volume_button': return Icons.volume_down;
      case 'smartwatch_media': return Icons.watch;
      case 'hard_fall': return Icons.trending_down;
      case 'route_deviance': return Icons.wrong_location;
      case 'ai_behavioral': return Icons.psychology;
      case 'dead_battery': return Icons.battery_alert;
      case 'wake_word': return Icons.mic;
      case 'physical_hardware': return Icons.phonelink_ring;
      case 'coercion_duress_pin': return Icons.warning_amber;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SosBloc, SosState>(
      listener: (context, state) {
        if (state is SosResolved) {
          if (mounted) context.go('/');
        }
        if (state is SosActive) {
          // Trigger auto-call to primary guardian or police if available
          _handleAutoCall(state);
        }
      },
      builder: (context, state) {
        if (state is! SosActive && state is! SosCancelling) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.danger)),
          );
        }

        final alert = state is SosActive ? state.alert : null;
        final lat = state is SosActive ? state.currentLat : null;
        final lng = state is SosActive ? state.currentLng : null;
        final evidenceCount = state is SosActive ? state.evidenceCount : 0;
        final sosId = alert?.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Background Animations (Rings/Pulse)
              Positioned.fill(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _ringAnimation,
                    builder: (_, __) => Container(
                      width: 250 + (_ringAnimation.value * 200),
                      height: 250 + (_ringAnimation.value * 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: (1 - _ringAnimation.value) * 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.danger.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),

              // Main Feed (Clean Scroll)
              Column(
                children: [
                  Expanded(
                    child: SafeArea(
                      bottom: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          children: [
                            // Timer badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.5), width: 1),
                              ),
                              child: Text(
                                'SOS ACTIVE • ${_formatElapsed()}',
                                style: GoogleFonts.orbitron(
                                  fontSize: 10,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'HELP IS ON THE WAY',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.orbitron(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Protector Badge
                            if (state is SosActive && state.primaryGuardianPhone != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shield, color: Colors.blue, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('PROTECTOR ASSIGNED', 
                                            style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                          const Text('Guardian Alpha', 
                                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _handleAutoCall(state),
                                      icon: const Icon(Icons.call, color: Colors.blue, size: 20),
                                    ),
                                  ],
                                ),
                              ),

                            // Tactical Stats
                            _InfoTile(
                              icon: Icons.my_location,
                              label: 'LIVE LOCATION',
                              value: lat != null ? '${lat.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}' : 'Locating...',
                              iconColor: AppColors.danger,
                            ),
                            const SizedBox(height: 12),
                            if (alert?.triggerType != null)
                              _InfoTile(
                                icon: _triggerTypeIcon(alert!.triggerType!),
                                label: 'TRIGGER METHOD',
                                value: _triggerTypeLabel(alert.triggerType!),
                                iconColor: AppColors.warning,
                              ),
                            const SizedBox(height: 12),
                            _InfoTile(
                              icon: Icons.security,
                              label: 'EVIDENCE SECURED',
                              value: evidenceCount > 0 ? '$evidenceCount files locked' : 'Capturing...',
                              iconColor: AppColors.safe,
                            ),
                            const SizedBox(height: 12),
                            if (alert != null)
                              _InfoTile(
                                icon: Icons.battery_charging_full,
                                label: 'BATTERY',
                                value: '${alert.batteryPct}%',
                                iconColor: (alert.batteryPct ?? 100) < 20 ? AppColors.danger : AppColors.warning,
                              ),
                            const SizedBox(height: 24),
                            // Police & Guardians status
                            _LivePoliceStatus(sosId: sosId),
                            const SizedBox(height: 12),
                            _QuickCallPoliceButton(sosId: sosId),
                            const SizedBox(height: 16),
                            Text(
                              'GUARDIANS NOTIFIED',
                              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            _LiveGuardiansGrid(sosId: sosId),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Deep Stealth Mask
              if (_isStealthMode)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      _stealthTaps++;
                      if (_stealthTaps >= 3) _disableStealthMode();
                    },
                    child: Container(color: Colors.black),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1), width: 1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final siren = getIt<SirenService>();
                          setState(() {
                            if (siren.isActive) {
                              siren.stopSiren();
                            } else {
                              siren.startSiren();
                            }
                          });
                        },
                        icon: Icon(getIt<SirenService>().isActive ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 18),
                        label: Text(getIt<SirenService>().isActive ? 'STOP ALARM' : 'SOUND ALARM', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getIt<SirenService>().isActive ? AppColors.surface : Colors.redAccent,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _enableStealthMode,
                        icon: const Icon(Icons.dark_mode, color: Colors.white, size: 16),
                        label: const Text('STEALTH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E1E),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CancelSOSButton(
                  isCancelling: state is SosCancelling,
                  onCancel: () async {
                    final result = await _showPinDialog(context);
                    if (result == 'cancel' && context.mounted) {
                      if (await Vibration.hasVibrator()) {
                        Vibration.vibrate(duration: 200);
                      }
                      if (!context.mounted) return;
                      context.read<SosBloc>().add(const SosCancelPressed('user_confirmed_safe'));
                    } else if (result == 'duress' && context.mounted) {
                      context.read<SosBloc>().add(const SosTriggerPressed('coercion_duress_pin'));
                      context.go('/');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showPinDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        bool error = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Emergency PIN', style: TextStyle(color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter 4-digit PIN to cancel.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  style: const TextStyle(color: AppColors.textPrimary, letterSpacing: 10, fontSize: 24),
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: error ? 'Incorrect PIN' : null,
                  ),
                  onChanged: (v) async {
                    if (v.length == 4) {
                      final svc = getIt<PinService>();
                      if (await svc.verifyPin(v)) {
                        if (ctx.mounted) Navigator.pop(ctx, 'cancel');
                      } else if (await svc.verifyDuressPin(v)) {
                        if (ctx.mounted) Navigator.pop(ctx, 'duress');
                      } else {
                        setState(() => error = true);
                      }
                    } else {
                      if (error) setState(() => error = false);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Stay Active', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardianBadge extends StatelessWidget {
  final String name;
  final String? phone;
  final bool notified;
  const _GuardianBadge({required this.name, this.phone, required this.notified});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notified
                    ? AppColors.safe.withValues(alpha: 0.15)
                    : AppColors.card,
                border: Border.all(
                  color: notified ? AppColors.safe : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                notified ? Icons.check : Icons.hourglass_empty,
                color: notified ? AppColors.safe : AppColors.textSecondary,
                size: 24,
              ),
            ),
            if (phone != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.call, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name.split(' ').first,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _LiveGuardiansGrid extends StatefulWidget {
  final String? sosId;
  const _LiveGuardiansGrid({this.sosId});

  @override
  State<_LiveGuardiansGrid> createState() => _LiveGuardiansGridState();
}

class _LiveGuardiansGridState extends State<_LiveGuardiansGrid> {
  List<Map<String, dynamic>> _guardians = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchAndSubscribe();
  }

  Future<void> _fetchAndSubscribe() async {
    if (widget.sosId == null) return;
    final client = Supabase.instance.client;

    try {
      final data = await client.from('sos_guardians')
          .select('guardians(contact_name, contact_phone), notified_at')
          .eq('sos_id', widget.sosId as Object);
      
      if (mounted) setState(() => _guardians = List.from(data));

      _channel = client.channel('public:sos_guardians:sos_id=eq.${widget.sosId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sos_guardians',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'sos_id', value: widget.sosId),
          callback: (payload) => _fetchAndSubscribe(),
        )
        .subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_guardians.isEmpty) {
      return const Center(child: Text('Notifying...', style: TextStyle(color: AppColors.textSecondary)));
    }
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 24,
      children: _guardians.map((g) {
        final gData = g['guardians'];
        final name = gData != null && gData is Map ? gData['contact_name'] : 'Guardian';
        final phone = gData != null && gData is Map ? gData['contact_phone'] : null;
        final notified = g['notified_at'] != null;
        return _GuardianBadge(name: name, phone: phone, notified: notified);
      }).toList(),
    );
  }
}

class _CancelSOSButton extends StatefulWidget {
  final VoidCallback onCancel;
  final bool isCancelling;
  const _CancelSOSButton(
      {required this.onCancel, required this.isCancelling});

  @override
  State<_CancelSOSButton> createState() => _CancelSOSButtonState();
}

class _CancelSOSButtonState extends State<_CancelSOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCancel();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCancelling) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.warning),
        ),
      );
    }
    return GestureDetector(
      onLongPressStart: (_) => _ctrl.forward(),
      onLongPressEnd: (_) => _ctrl.reset(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2), width: 1),
            color: AppColors.surface,
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: _ctrl.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.safe.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'HOLD 3s — I AM SAFE',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePoliceStatus extends StatefulWidget {
  final String? sosId;
  const _LivePoliceStatus({this.sosId});

  @override
  State<_LivePoliceStatus> createState() => _LivePoliceStatusState();
}

class _LivePoliceStatusState extends State<_LivePoliceStatus> {
  Map<String, dynamic>? _response;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.sosId == null) return;
    final client = Supabase.instance.client;
    try {
      final res = await client.from('police_responses')
          .select('status, police_stations(name, contact_number)')
          .eq('sos_id', widget.sosId as Object)
          .maybeSingle();
      if (mounted) setState(() => _response = res);
      
      // Realtime listener
      client.channel('public:police_responses:sos_id=eq.${widget.sosId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'police_responses',
          callback: (p) => _fetch(),
        ).subscribe();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_response == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger)),
            const SizedBox(width: 12),
            Text('ROUTING TO NEAREST STATION...', style: GoogleFonts.orbitron(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final station = _response!['police_stations'];
    final name = station != null && station is Map ? station['name'] : 'Police';
    final status = _response!['status'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_police, color: AppColors.danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(), style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(status == 'pending' ? 'ALERT RECEIVED' : status.toUpperCase(), 
                  style: TextStyle(color: status == 'resolved' ? AppColors.safe : AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (status == 'pending')
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger)),
        ],
      ),
    );
  }
}

class _QuickCallPoliceButton extends StatefulWidget {
  final String? sosId;
  const _QuickCallPoliceButton({this.sosId});

  @override
  State<_QuickCallPoliceButton> createState() => _QuickCallPoliceButtonState();
}

class _QuickCallPoliceButtonState extends State<_QuickCallPoliceButton> {
  String? _phone;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.sosId == null) return;
    try {
      final res = await Supabase.instance.client
          .from('police_responses')
          .select('police_stations(contact_number)')
          .eq('sos_id', widget.sosId as Object)
          .maybeSingle();
      
      if (res != null && res['police_stations'] != null) {
        setState(() => _phone = res['police_stations']['contact_number']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final number = _phone ?? '100';
        final uri = Uri.parse('tel:$number');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      icon: const Icon(Icons.call, color: Colors.white, size: 20),
      label: Text(
        'CALL NEAREST POLICE STATION',
        style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}

