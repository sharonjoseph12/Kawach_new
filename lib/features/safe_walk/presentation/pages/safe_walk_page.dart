import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/safe_walk/pin_service.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_event.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:vibration/vibration.dart';

class SafeWalkPage extends StatefulWidget {
  const SafeWalkPage({super.key});

  @override
  State<SafeWalkPage> createState() => _SafeWalkPageState();
}

class _SafeWalkPageState extends State<SafeWalkPage> {
  static const int _pinLength = 4;

  final PinService _pinService = getIt<PinService>();

  bool _isActive = false;
  bool _hasPin = false;
  bool _isSettingPin = false;
  String _newPinInput = '';

  int _totalSeconds = 15 * 60;
  int _remainingSeconds = 15 * 60;
  Timer? _timer;

  // Periodic check-in
  int _checkinIntervalMinutes = 5;
  Timer? _checkinTimer;
  int _checkinCountdownSeconds = 0;
  bool _awaitingCheckin = false;
  final _notifications = FlutterLocalNotificationsPlugin();

  String _enteredPin = '';
  bool _isPinError = false;

  @override
  void initState() {
    super.initState();
    _checkPinExists();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        // User tapped notification — treat as check-in confirmed
        if (mounted) _confirmCheckin();
      },
    );
  }

  Future<void> _checkPinExists() async {
    final hasPin = await _pinService.hasPin();
    setState(() => _hasPin = hasPin);
  }

  void _startTimer() {
    setState(() {
      _isActive = true;
      _remainingSeconds = _totalSeconds;
      _enteredPin = '';
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds == 30) {
            Vibration.vibrate(pattern: [0, 500, 200, 500]);
          }
        } else {
          _triggerDeadManSOS();
        }
      });
    });

    // Start periodic check-in
    _scheduleNextCheckin();
  }

  void _scheduleNextCheckin() {
    _checkinTimer?.cancel();
    _checkinTimer = Timer(Duration(minutes: _checkinIntervalMinutes), _triggerCheckin);
  }

  Future<void> _triggerCheckin() async {
    if (!mounted || !_isActive) return;
    setState(() {
      _awaitingCheckin = true;
      _checkinCountdownSeconds = 60;
    });
    Vibration.vibrate(pattern: [0, 300, 100, 300]);
    await _notifications.show(
      42,
      '⚠️ Are you safe?',
      'Tap to confirm within 60 seconds — or SOS will trigger.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kawach_checkin', 'Check-in Alerts',
          channelDescription: 'Safe Walk periodic check-in',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
        ),
        iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
      ),
    );
    // 60-second response window
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_awaitingCheckin) { t.cancel(); return; }
      setState(() => _checkinCountdownSeconds--);
      if (_checkinCountdownSeconds <= 0) {
        t.cancel();
        _triggerDeadManSOS();
      }
    });
  }

  void _confirmCheckin() {
    if (!_awaitingCheckin) return;
    _notifications.cancel(42);
    setState(() { _awaitingCheckin = false; _checkinCountdownSeconds = 0; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Check-in confirmed. Stay safe.'),
      backgroundColor: AppColors.safe,
      duration: Duration(seconds: 2),
    ));
    _scheduleNextCheckin();
  }

  void _triggerDeadManSOS() {
    _timer?.cancel();
    context.read<SosBloc>().add(const SosTriggerPressed('dead_mans_switch'));
    context.go('/sos_active');
  }

  void _handlePinDigit(String digit, {bool isSetting = false}) {
    if (isSetting) {
      if (_newPinInput.length < _pinLength) {
        setState(() => _newPinInput += digit);
        if (_newPinInput.length == _pinLength) {
          _saveNewPin();
        }
      }
      return;
    }

    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin += digit;
        _isPinError = false;
      });

      if (_enteredPin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  Future<void> _verifyPin() async {
    final correct = await _pinService.verifyPin(_enteredPin);
    final isDuress = await _pinService.verifyDuressPin(_enteredPin);

    if (correct) {
      _cancelSafeWalk();
    } else if (isDuress) {
      // Secretly trigger SOS, but pretend to cancel the UI
      if (!mounted) return;
      context.read<SosBloc>().add(const SosTriggerPressed('coercion_duress_pin'));
      _cancelSafeWalk(isDuress: true);
    } else {
      setState(() {
        _isPinError = true;
      });
      Vibration.vibrate();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _enteredPin = '');
      });
    }
  }

  Future<void> _saveNewPin() async {
    final reverse = _newPinInput.split('').reversed.join('');
    // If palindrome prevent duress from being identical
    final duressPin = (reverse == _newPinInput) 
        ? _newPinInput.split('').map((e) => ((int.parse(e) + 1) % 10).toString()).join('') 
        : reverse;

    await _pinService.savePin(_newPinInput, duressPin);
    setState(() {
      _hasPin = true;
      _isSettingPin = false;
      _newPinInput = '';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PIN saved! Your DURESS PIN is $duressPin. Use $duressPin to fake-cancel and silently alert police.'),
          backgroundColor: AppColors.safe,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  void _cancelSafeWalk({bool isDuress = false}) {
    _timer?.cancel();
    _checkinTimer?.cancel();
    _notifications.cancel(42);
    setState(() {
      _isActive = false;
      _enteredPin = '';
      _awaitingCheckin = false;
    });

    if (!isDuress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safe Walk ended. You are safe.'),
          backgroundColor: AppColors.safe,
        ),
      );
    } else {
      // Under duress, silently exit entirely to home screen without obvious green messages
      if (mounted) context.go('/');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkinTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    int m = _remainingSeconds ~/ 60;
    int s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safe Walk', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (_hasPin)
            IconButton(
              icon: const Icon(Icons.lock_reset, color: AppColors.textSecondary),
              onPressed: () => setState(() {
                _isSettingPin = true;
                _newPinInput = '';
              }),
              tooltip: 'Change PIN',
            ),
        ],
      ),
      body: SafeArea(
        child: _isSettingPin
            ? _buildPinSetup()
            : !_hasPin
                ? _buildNoPinState()
                : _isActive
                    ? _buildActiveState()
                    : _buildSetupState(),
      ),
    );
  }

  Widget _buildNoPinState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 72, color: AppColors.warning),
          const SizedBox(height: 24),
          const Text(
            'Set a secure PIN first',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your PIN is stored with military-grade encryption. You\'ll use it to cancel Safe Walk before SOS triggers.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => setState(() { _isSettingPin = true; _newPinInput = ''; }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Set PIN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSetup() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Choose a 4-digit PIN', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('This will be encrypted on your device.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (index) {
              final isFilled = index < _newPinInput.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: isFilled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3), width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          _buildNumpad(isSetting: true),
        ],
      ),
    );
  }

  Widget _buildSetupState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.shield_moon, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Keep your phone in your pocket. If you don\'t cancel the timer with your PIN before it hits zero, an SOS is automatically triggered.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // ── Check-in interval control (only in setup state)
          if (!_isActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Text('Check-in every:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _checkinIntervalMinutes.toDouble(),
                      min: 2, max: 15, divisions: 13,
                      activeColor: AppColors.secondary,
                      label: '$_checkinIntervalMinutes min',
                      onChanged: (v) => setState(() => _checkinIntervalMinutes = v.round()),
                    ),
                  ),
                  Text('${_checkinIntervalMinutes}m', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Text('Duration: ${_totalSeconds ~/ 60} minutes', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          Slider(
            value: (_totalSeconds ~/ 60).toDouble(),
            min: 5, max: 60, divisions: 11,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _totalSeconds = val.toInt() * 60),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _startTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Start Safe Walk', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveState() {
    final isCritical = _remainingSeconds <= 30;
    final color = isCritical ? Colors.red : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Check-in pending banner
          if (_awaitingCheckin)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(
                    '⚠️ ARE YOU SAFE? Confirm in ${_checkinCountdownSeconds}s',
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _confirmCheckin,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.safe),
                    child: const Text('✅  I AM SAFE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          const Text('Time Remaining', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
          const SizedBox(height: 8),
          Text(_formattedTime, style: TextStyle(color: color, fontSize: 72, fontWeight: FontWeight.bold)),
          if (isCritical)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('ENTER PIN TO CANCEL SOS!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (index) {
              final isFilled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? (_isPinError ? Colors.red : AppColors.primary) : Colors.transparent,
                  border: Border.all(color: _isPinError ? Colors.red : (isFilled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3)), width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          Expanded(child: _buildNumpad()),
        ],
      ),
    );
  }

  Widget _buildNumpad({bool isSetting = false}) {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      children: [
        for (int i = 1; i <= 9; i++) _buildNumBtn(i.toString(), isSetting: isSetting),
        const SizedBox(),
        _buildNumBtn('0', isSetting: isSetting),
        IconButton(
          icon: const Icon(Icons.backspace, color: AppColors.textSecondary),
          onPressed: () {
            setState(() {
              if (isSetting) {
                if (_newPinInput.isNotEmpty) _newPinInput = _newPinInput.substring(0, _newPinInput.length - 1);
              } else {
                if (_enteredPin.isNotEmpty) { _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1); _isPinError = false; }
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildNumBtn(String digit, {bool isSetting = false}) {
    return InkWell(
      onTap: () => _handlePinDigit(digit, isSetting: isSetting),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.05)),
        alignment: Alignment.center,
        child: Text(digit, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24)),
      ),
    );
  }
}
