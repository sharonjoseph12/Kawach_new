import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/services/camouflage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _audioDetection = true;
  bool _behavioralAnomaly = true;
  bool _meshRelay = true;
  bool _camouflageMode = false;
  bool _signingOut = false;
  String _phone = '';
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    String versionText = '1.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      versionText = '${info.version} (${info.buildNumber})';
    } catch (_) {}

    setState(() {
      _audioDetection = prefs.getBool('audio_detection') ?? true;
      _behavioralAnomaly = prefs.getBool('behavioral_anomaly') ?? true;
      _meshRelay = prefs.getBool('mesh_relay') ?? true;
      _camouflageMode = prefs.getBool('camouflage_mode') ?? false;
      _phone = user?.phone ?? user?.email ?? 'Not signed in';
      _appVersion = versionText;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_detection', _audioDetection);
    await prefs.setBool('behavioral_anomaly', _behavioralAnomaly);
    await prefs.setBool('mesh_relay', _meshRelay);
    await prefs.setBool('camouflage_mode', _camouflageMode);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will need to verify your phone number again.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _signingOut = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_setup_done');
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/phone');
  }

  void _changePIN() => context.push('/safe-walk');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 4),

          // ── Account card ─────────────────────────────────────────────
          _buildSection('ACCOUNT', [
            _ProfileCard(phone: _phone),
            const SizedBox(height: 12),
            _TileButton(
              icon: Icons.lock_outline,
              title: 'Change PIN',
              subtitle: 'Update your Safe Walk security PIN',
              iconColor: AppColors.primary,
              onTap: _changePIN,
            ),
            _TileButton(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your name shown on home screen',
              iconColor: AppColors.primary,
              onTap: () => context.push('/profile'),
            ),
            _TileButton(
              icon: Icons.person_outline,
              title: 'Guardians',
              subtitle: 'Manage your emergency contacts',
              iconColor: AppColors.secondary,
              onTap: () => context.push('/guardians'),
            ),
            _TileButton(
              icon: Icons.history,
              title: 'SOS History',
              subtitle: 'View all past emergency events',
              iconColor: AppColors.danger,
              onTap: () => context.push('/sos-history'),
            ),
          ]),

          // ── AI & Monitoring ───────────────────────────────────────────
          _buildSection('AI & MONITORING', [
            _SwitchTile(
              icon: Icons.mic,
              title: 'Audio Threat Detection',
              subtitle: 'Detect screams and glass breaking',
              iconColor: AppColors.secondary,
              value: _audioDetection,
              onChanged: (v) { setState(() => _audioDetection = v); _save(); },
            ),
            _SwitchTile(
              icon: Icons.psychology_outlined,
              title: 'Behavioral Anomaly',
              subtitle: 'Detect unusual movement patterns',
              iconColor: AppColors.warning,
              value: _behavioralAnomaly,
              onChanged: (v) { setState(() => _behavioralAnomaly = v); _save(); },
            ),
          ]),

          // ── Mesh Network ──────────────────────────────────────────────
          _buildSection('MESH NETWORK', [
            _SwitchTile(
              icon: Icons.device_hub,
              title: 'Mesh Relay',
              subtitle: 'Help others by relaying SOS signals offline',
              iconColor: AppColors.meshActive,
              value: _meshRelay,
              onChanged: (v) { setState(() => _meshRelay = v); _save(); },
            ),
          ]),

          // ── App ───────────────────────────────────────────────────────
          _buildSection('APP', [
            _SwitchTile(
              icon: Icons.calculate_outlined,
              title: 'App Disguise (Calculator)',
              subtitle: 'Hides Kawach icon and poses as Calculator',
              iconColor: const Color(0xFF7C4DFF),
              value: _camouflageMode,
              onChanged: (v) async {
                setState(() => _camouflageMode = v);
                await _save();
                if (v) {
                  await CamouflageService.enableCamouflage();
                } else {
                  await CamouflageService.disableCamouflage();
                }
              },
            ),
            _TileButton(
              icon: Icons.monitor_heart_outlined,
              title: 'System Diagnostics',
              subtitle: 'Check sensors, permissions & connectivity',
              iconColor: AppColors.safe,
              onTap: () => context.push('/diagnostics'),
            ),
            _TileButton(
              icon: Icons.info_outline,
              title: 'About Kawach',
              subtitle: 'Version $_appVersion • Made with ❤️ for safety',
              iconColor: AppColors.textSecondary,
              onTap: () {},
            ),
          ]),

          // ── Danger zone ───────────────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.15)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: AppColors.danger, size: 20),
              ),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              subtitle: Text(_phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              trailing: _signingOut
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.danger, strokeWidth: 2))
                  : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: _signingOut ? null : _signOut,
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title, style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            )),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String phone;
  const _ProfileCard({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 28)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Account', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _TileButton({required this.icon, required this.title, required this.subtitle, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.icon, required this.title, required this.subtitle, required this.iconColor, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary),
    );
  }
}
