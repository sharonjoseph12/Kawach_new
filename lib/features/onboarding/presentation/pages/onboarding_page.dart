import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/safe_walk/pin_service.dart';
import 'package:kawach/app/di/injection.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  final PinService _pinService = getIt<PinService>();
  int _currentPage = 0;
  String _pinInput = '';
  bool _permissionsGranted = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.locationAlways,
      Permission.microphone,
      Permission.camera,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.ignoreBatteryOptimizations,
      Permission.notification,
    ].request();
    setState(() => _permissionsGranted = true);
  }

  Future<void> _completeOnboarding() async {
    if (_pinInput.length == 4) {
      final reverse = _pinInput.split('').reversed.join('');
      final duressPin = (reverse == _pinInput) 
          ? _pinInput.split('').map((e) => ((int.parse(e) + 1) % 10).toString()).join('') 
          : reverse;
      await _pinService.savePin(_pinInput, duressPin);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/');
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildPermissionsPage(),
                  _buildGuardianPage(),
                  _buildPinPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _currentPage == 3 ? 'Get Protected' : 'Continue',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 120, height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              ),
              child: Icon(Icons.shield, color: Colors.white, size: 64),
            ),
          ),
          SizedBox(height: 32),
          Text('Welcome to KAWACH', style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 16),
          Text(
            'Your AI-powered personal safety companion. In 3 steps, you\'ll have real-time SOS, guardian alerts, and covert protection set up.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    final perms = [
      ('Always-on Location', Icons.location_on, 'Track you during emergencies'),
      ('Microphone', Icons.mic, 'Silent audio evidence capture'),
      ('Camera', Icons.camera_alt, 'Front-camera burst during SOS'),
      ('Bluetooth', Icons.bluetooth, 'Offline BLE mesh network'),
      ('Battery Unrestricted', Icons.battery_full, 'Keep protection running 24/7'),
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enable Protections', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Kawach needs these to protect you in every scenario.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ...perms.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              Icon(p.$2, color: AppColors.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$1, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text(p.$3, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              )),
            ]),
          )),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _requestPermissions,
            icon: Icon(_permissionsGranted ? Icons.check_circle : Icons.lock_open, color: _permissionsGranted ? AppColors.safe : AppColors.primary),
            label: Text(_permissionsGranted ? 'Permissions Granted' : 'Grant All Permissions', style: TextStyle(color: _permissionsGranted ? AppColors.safe : AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _permissionsGranted ? AppColors.safe : AppColors.primary),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_3, size: 80, color: AppColors.secondary),
          const SizedBox(height: 24),
          const Text('Add Your Guardians', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text(
            'Guardians receive instant alerts with your live location when SOS is triggered. They can also share a live tracking link.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => context.push('/guardians'),
            icon: const Icon(Icons.person_add, color: AppColors.primary),
            label: const Text('Add Guardians Now', style: TextStyle(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _nextPage,
            child: const Text('Skip for now', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPinPage() {
    const pinLength = 4;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text('Set Your Safe Walk PIN', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('This PIN cancels your Safe Walk timer. It\'s stored with encryption only on your device.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pinLength, (i) {
              final filled = i < _pinInput.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: filled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3), width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1.6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (int i = 1; i <= 9; i++) _numBtn(i.toString()),
              const SizedBox(),
              _numBtn('0'),
              IconButton(
                icon: const Icon(Icons.backspace, color: AppColors.textSecondary),
                onPressed: () { if (_pinInput.isNotEmpty) setState(() => _pinInput = _pinInput.substring(0, _pinInput.length - 1)); },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numBtn(String d) => InkWell(
    onTap: () { if (_pinInput.length < 4) setState(() => _pinInput += d); },
    borderRadius: BorderRadius.circular(40),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.05)),
      child: Text(d, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24)),
    ),
  );
}
