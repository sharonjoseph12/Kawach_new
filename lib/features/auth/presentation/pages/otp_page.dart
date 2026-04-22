import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/core/utils/startup_utils.dart';
import 'package:kawach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawach/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawach/features/auth/presentation/bloc/auth_state.dart';

class OTPPage extends StatefulWidget {
  final String phone;
  const OTPPage({super.key, required this.phone});

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    _startResendTimer();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit — auto-submit
        _focusNodes[index].unfocus();
        _submit();
      }
    }
  }

  void _submit() {
    if (_otp.length != 6) return;
    HapticFeedback.lightImpact();
    context.read<AuthBloc>().add(AuthVerifyOTPPressed(widget.phone, _otp));
  }

  void _resend() {
    if (!_canResend) return;
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    context.read<AuthBloc>().add(AuthSendOTPPressed(widget.phone));
    _startResendTimer();
  }

  void _shakeAndClear() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Auto-create profile row for new users
          ensureProfileExists();
          if (mounted) context.go('/');
        } else if (state is AuthFailureState) {
          if (!mounted) return;
          _shakeAndClear();
          final msg = state.message.contains('expired')
              ? 'Code expired. Tap Resend to get a new one.'
              : 'Invalid code. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Text(
                  'Verify Phone',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter the 6-digit code sent to\n${widget.phone}',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 44),

                // OTP boxes row
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimation.value *
                            (_shakeController.status == AnimationStatus.forward
                                ? -1
                                : 1),
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 46,
                        height: 56,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (val) => _onDigitEntered(index, val),
                          onEditingComplete: () {},
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 32),

                // Resend row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resend,
                      child: Text(
                        _canResend ? 'Resend' : 'Resend in ${_resendSeconds}s',
                        style: GoogleFonts.poppins(
                          color: _canResend
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Verify button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Verify & Continue',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
