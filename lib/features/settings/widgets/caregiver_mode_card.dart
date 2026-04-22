import 'package:flutter/material.dart';
import 'package:kawach/core/theme/app_colors.dart';

/// Caregiver mode settings widget.
/// Parents can add a child phone number via this settings card.
/// When the child triggers SOS, the notify-guardians edge function
/// receives role=caregiver and alerts this number.
class CaregiverModeCard extends StatefulWidget {
  const CaregiverModeCard({super.key});

  @override
  State<CaregiverModeCard> createState() => _CaregiverModeCardState();
}

class _CaregiverModeCardState extends State<CaregiverModeCard> {
  bool _enabled = false;
  final _childPhoneController = TextEditingController();
  bool _linked = false;

  @override
  void dispose() {
    _childPhoneController.dispose();
    super.dispose();
  }

  Future<void> _linkChild() async {
    final phone = _childPhoneController.text.trim();
    if (phone.isEmpty) return;

    // to-do: call Supabase edge function to send OTP invite to child
    // The child accepts and their account is linked to this guardian.
    setState(() => _linked = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite sent to $phone'),
          backgroundColor: AppColors.safe,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Caregiver Mode', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Link a child account to receive\ntheir SOS alerts.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              Switch(
                value: _enabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _enabled = val),
              ),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _childPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Child phone number (+91...)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.child_care, color: AppColors.primary),
                suffixIcon: _linked
                    ? const Icon(Icons.check_circle, color: AppColors.safe)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _linkChild,
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Send Invite Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
