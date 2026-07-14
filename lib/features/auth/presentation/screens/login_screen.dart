import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../providers/auth_provider.dart';

/// LoginScreen implements mockup 1 (Member Login page).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    String phone = _phoneController.text.trim();
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('91') && phone.length > 10) {
      phone = phone.substring(2);
    }
    phone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhoneNumber = '+91$phone';
    
    final authProvider = context.read<AuthProvider>();
    authProvider.clearStates();
    
    // Check if the user is registered first
    final exists = await authProvider.checkUserExists(fullPhoneNumber);
    
    if (authProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (!exists && mounted) {
      authProvider.setVerificationPhone(fullPhoneNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number not registered. Please create an account.'),
          backgroundColor: AppColors.error,
        ),
      );
      context.go(AppRoutes.register);
      return;
    }
    
    // Registered! Proceed to send OTP
    final success = await authProvider.sendOtp(fullPhoneNumber);
    
    if (success && mounted) {
      context.go(AppRoutes.otp);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Authentication failed.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.brandBackground,
          // Subtle background decoration representing medical imaging/radiographic lines
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&q=80&w=1000'
            ),
            opacity: 0.03, // translucent background watermark
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                  
                  // Watermark / Brand Logo at top
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
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
                          Icons.healing_outlined, // caduceus mockup icon
                          size: 40,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // App Title
                  Text(
                    'My KGRA',
                    style: AppTextStyle.headlineLgMobile(color: AppColors.brandSecondary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kerala Government Radiographers\' Association',
                    style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Glassmorphic Card Container
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member Login',
                          style: AppTextStyle.titleLg(color: AppColors.brandPrimary).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Sign in to access your dashboard',
                          style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Input Label
                        Text(
                          'Mobile Number',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Custom Input Field with Country Code
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Very light gray container
                            borderRadius: AppRadius.borderLg,
                          ),
                          child: Row(
                            children: [
                              // Country code prefix dropdown
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                child: Row(
                                  children: [
                                    const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '+91',
                                      style: AppTextStyle.bodyMd(color: AppColors.onSurface).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Vertical divider
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.grey.shade300,
                              ),
                              // Real text input
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter 10 digit number',
                                    fillColor: Colors.transparent,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Phone number required';
                                    }
                                    if (value.trim().length != 10 || 
                                        !RegExp(r'^\d+$').hasMatch(value.trim())) {
                                      return 'Enter valid 10-digit number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleSendOtp,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send OTP'),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // OR Separator
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: Text(
                                'OR',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Create Account option
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'New to My KGRA?',
                                style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              GestureDetector(
                                onTap: () {
                                  authProvider.clearStates();
                                  context.go(AppRoutes.register);
                                },
                                child: Text(
                                  'Create Account',
                                  style: AppTextStyle.titleLg(color: AppColors.brandPrimary).copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Footer Approval Notice
                  Text(
                    'Admin approval is required for all new registrations to maintain professional standards.',
                    style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
}
