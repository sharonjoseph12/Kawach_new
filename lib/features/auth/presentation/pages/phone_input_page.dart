import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawach/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawach/features/auth/presentation/bloc/auth_state.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
        
    final state = context.read<AuthBloc>().state;
    if (state is AuthCodeSent) {
      _phoneController.text = state.phone.replaceAll('+91', '');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) return 'Enter your phone number';
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Must be exactly 10 digits';
    return null;
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    // Prepend +91 if not already present
    final raw = _phoneController.text.trim();
    final phone = raw.startsWith('+') ? raw : '+91$raw';
    context.read<AuthBloc>().add(AuthSendOTPPressed(phone));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthCodeSent) {
          if (mounted) context.push('/otp', extra: state.phone);
        } else if (state is AuthFailureState) {
          if (!mounted) return;
          // Only show errors when this page is the top route
          final currentRoute = GoRouterState.of(context).matchedLocation;
          if (currentRoute != '/phone') return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_friendlyError(state.message)),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 60, 28, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo / Shield icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.shield,
                            color: Colors.white, size: 36),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'Welcome to\nKAWACH',
                        style: GoogleFonts.orbitron(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Your AI-powered personal safety guardian.\nEnter your number to get started.',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Phone input with country code
                      Text(
                        'PHONE NUMBER',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            // Country code
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              decoration: BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        color: AppColors.textSecondary.withValues(alpha: 0.2), width: 1)),
                              ),
                              child: Row(
                                children: [
                                  const Text('🇮🇳',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+91',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Number field
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: GoogleFonts.poppins(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    letterSpacing: 2),
                                decoration: InputDecoration(
                                  hintText: '98765 43210',
                                  hintStyle: GoogleFonts.poppins(
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.5),
                                    letterSpacing: 2,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  fillColor: Colors.transparent,
                                  filled: true,
                                ),
                                validator: _validatePhone,
                                onFieldSubmitted: (_) => _submit(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Submit button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _submit(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.primary.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'Send Verification Code',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms & Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('rate') || raw.contains('429')) {
      return 'Too many attempts. Please wait a minute.';
    }
    if (raw.contains('phone_provider_disabled') || raw.contains('Unsupported phone provider')) {
      return 'Phone auth not configured. Contact support.';
    }
    if (raw.contains('invalid_phone') || raw.contains('Invalid phone number')) {
      return 'Invalid phone number. Check and try again.';
    }
    if (raw.contains('network') || raw.contains('socket')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Something went wrong. Please try again.';
  }
}
