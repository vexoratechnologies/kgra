import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/app_snack_bar.dart';
import '../providers/auth_provider.dart';

/// OtpScreen implements mockup 2 (Verify OTP page).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _totalTimerSeconds = 120;
  int _secondsRemaining = _totalTimerSeconds;
  Timer? _timer;
  
  // 6 digits controllers and focus nodes
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = _totalTimerSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  String _getFormattedTimer() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerify() async {
    // Combine all digits
    final otpCode = _controllers.map((c) => c.text.trim()).join();
    if (otpCode.length != 6) {
      AppSnackBar.showError(context, 'Please enter all 6 digits of the OTP.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(otpCode);

    if (success && mounted) {
      if (!authProvider.isRegistered) {
        // Redirect to Register screen
        context.go(AppRoutes.register);
      } else if (authProvider.isPendingApproval) {
        // Redirect to Pending screen
        context.go(AppRoutes.pending);
      } else {
        // Fully authenticated -> Go to Home
        context.go(AppRoutes.home);
      }
    } else if (mounted) {
      AppSnackBar.showError(context, authProvider.error ?? 'Verification failed.');
    }
  }

  void _handleResend() async {
    if (_secondsRemaining > 0) return;
    
    final authProvider = context.read<AuthProvider>();
    final phone = authProvider.verificationPhone;
    if (phone == null) return;
    
    final success = await authProvider.sendOtp(phone);
    if (success && mounted) {
      _startTimer();
      AppSnackBar.showSuccess(context, 'OTP sent again successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final rawPhone = authProvider.verificationPhone ?? '+91 XXXXX XXXXX';
    
    // Format phone display slightly nicer
    String formattedPhone = rawPhone;
    if (rawPhone.length == 13 && rawPhone.startsWith('+91')) {
      formattedPhone = '+91 ${rawPhone.substring(3, 8)} ${rawPhone.substring(8)}';
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.brandBackground,
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&q=80&w=1000'
            ),
            opacity: 0.03,
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                
                // Small Watermark Logo
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandSecondary.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.security_outlined,
                        size: 36,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: AppRadius.borderXl,
                    border: Border.all(
                      color: AppColors.brandSecondary.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandSecondary.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Verify OTP',
                        style: AppTextStyle.titleLg(color: AppColors.brandPrimary).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                          children: [
                            const TextSpan(text: 'Enter the 6-digit code sent to '),
                            TextSpan(
                              text: formattedPhone,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // 6 Boxes Code Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 44,
                            height: 48,
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              decoration: InputDecoration(
                                counterText: '',
                                fillColor: const Color(0xFFF1F5F9),
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.borderDefault,
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.borderDefault,
                                  borderSide: const BorderSide(
                                    color: AppColors.brandPrimary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  // Shift focus to next node
                                  if (index < 5) {
                                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                                  } else {
                                    FocusScope.of(context).unfocus();
                                  }
                                } else {
                                  // Shift focus to previous node
                                  if (index > 0) {
                                    FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                                  }
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Verify & Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _handleVerify,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Verify & Login'),
                                    SizedBox(width: AppSpacing.xs),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Countdown timer / Resend option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _secondsRemaining > 0
                                ? 'Didn\'t receive the code? Resend in '
                                : 'Didn\'t receive the code? ',
                            style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                          ),
                          _secondsRemaining > 0
                              ? Text(
                                  _getFormattedTimer(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandPrimary,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _handleResend,
                                  child: const Text(
                                    'Resend Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brandPrimary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      
                      // Change Mobile Number
                      GestureDetector(
                        onTap: () {
                          authProvider.clearStates();
                          context.go(AppRoutes.login);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 16, color: AppColors.brandPrimary),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Change Mobile Number',
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
