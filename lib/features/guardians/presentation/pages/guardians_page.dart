import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/guardians/data/guardian_repository.dart';

class GuardiansPage extends StatefulWidget {
  const GuardiansPage({super.key});

  @override
  State<GuardiansPage> createState() => _GuardiansPageState();
}

class _GuardiansPageState extends State<GuardiansPage> {
  final _repo = GuardianRepository();
  List<GuardianModel> _guardians = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await _repo.fetchGuardians();
      if (mounted) setState(() { _guardians = g; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addGuardian() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Guardian', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("They'll be notified instantly in an emergency.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            _Field(label: 'Full Name', controller: nameCtrl, icon: Icons.person_outline),
            const SizedBox(height: 14),
            _Field(label: 'Phone Number', controller: phoneCtrl, icon: Icons.phone_outlined, inputType: TextInputType.phone),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  await _repo.addGuardian(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim());
                  await _load();
                  if (mounted) {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Guardian added successfully."),
                      backgroundColor: AppColors.safe,
                    ));
                  }
                } catch (e) {
                  if (mounted) setState(() => _loading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to add: $e'),
                      backgroundColor: AppColors.danger,
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Guardian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGuardian(GuardianModel g) async {
    HapticFeedback.mediumImpact();
    setState(() => _guardians.remove(g));
    try {
      await _repo.deleteGuardian(g.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${g.contactName} removed'),
        action: SnackBarAction(label: 'Undo', onPressed: _load),
      ));
    } catch (_) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trusted Guardians', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _load)],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_sync, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Guardians are synced to the cloud. Swipe left to remove.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                )),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _guardians.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text('No guardians yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _guardians.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final g = _guardians[i];
                          return Dismissible(
                            key: Key(g.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: AppColors.danger),
                            ),
                            confirmDismiss: (_) async { await _deleteGuardian(g); return false; },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.08)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                    child: Text(
                                      g.contactName.isNotEmpty ? g.contactName[0] : '?',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(g.contactName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        Text(g.contactPhone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (g.verified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppColors.safe.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified, color: AppColors.safe, size: 14),
                                          SizedBox(width: 4),
                                          Text('Active', style: TextStyle(color: AppColors.safe, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Text('Pending', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: ElevatedButton.icon(
              onPressed: _addGuardian,
              icon: const Icon(Icons.person_add_outlined, color: Colors.white),
              label: const Text('Add Guardian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType inputType;
  const _Field({required this.label, required this.controller, required this.icon, this.inputType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}
