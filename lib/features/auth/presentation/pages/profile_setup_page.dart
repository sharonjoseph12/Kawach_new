import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/auth/data/profile_repository.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _repo = ProfileRepository();
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _repo.fetchProfile();
    if (mounted) {
      _nameCtrl.text = profile?['full_name'] as String? ?? '';
      setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.upsertProfile(fullName: _nameCtrl.text.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_setup_done', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile saved!'),
          backgroundColor: AppColors.safe,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Profile', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loaded
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 96, height: 96,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _nameCtrl.text.trim().isNotEmpty
                                ? Text(
                                    _nameCtrl.text.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                  )
                                : const Icon(Icons.person, color: Colors.white, size: 52),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('DISPLAY NAME', style: TextStyle(color: AppColors.primary, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your name appears on the home screen and in emergency alerts sent to your guardians.',
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12, height: 1.5),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
