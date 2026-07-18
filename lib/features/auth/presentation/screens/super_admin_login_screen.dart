import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../admin/presentation/providers/admin_provider.dart';

/// SuperAdminLoginScreen renders a premium, high-security login console for the Super Administrator.
class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.loginAdmin(
      username,
      password,
      allowedRole: 'super_admin',
    );

    if (success && mounted) {
      context.go(AppRoutes.superAdminDashboard);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.error ?? 'Super Admin Authentication failed.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    const goldColor = Color(0xFFFFD700);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E0004), Color(0xFF3F0008)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Custom AppBar leading for dark background
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: goldColor),
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Gold Shield Icon
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: goldColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: goldColor, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: goldColor.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.security_outlined,
                                  size: 40,
                                  color: goldColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          const Text(
                            'KGRA SUPER ADMIN',
                            style: TextStyle(
                              fontSize: 22,
                              color: goldColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Central Command & Control System',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // Glassmorphic Card Container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: AppRadius.borderXl,
                              border: Border.all(
                                color: goldColor.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Secure Console Sign In',
                                  style: TextStyle(
                                    color: goldColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                const Text(
                                  'Authentication required for root access',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Username Field
                                const Text(
                                  'Master Username',
                                  style: TextStyle(
                                    color: goldColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextFormField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.1),
                                    hintText: 'Enter username',
                                    hintStyle: const TextStyle(color: Colors.white30),
                                    prefixIcon: const Icon(Icons.person_outline, color: goldColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: const BorderSide(color: goldColor, width: 1.5),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: const BorderSide(color: AppColors.error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Username required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Password Field
                                const Text(
                                  'Console Password',
                                  style: TextStyle(
                                    color: goldColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.1),
                                    hintText: 'Enter password',
                                    hintStyle: const TextStyle(color: Colors.white30),
                                    prefixIcon: const Icon(Icons.lock_outline, color: goldColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: const BorderSide(color: goldColor, width: 1.5),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: const BorderSide(color: AppColors.error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Password required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xl),

                                // Action button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: goldColor,
                                      foregroundColor: const Color(0xFF1E0004),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.borderMd,
                                      ),
                                    ),
                                    onPressed: adminProvider.isLoading ? null : _handleLogin,
                                    child: adminProvider.isLoading
                                        ? const CircularProgressIndicator(color: Color(0xFF1E0004))
                                        : const Text(
                                            'Authorize Session',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
            ],
          ),
        ),
      ),
    );
  }
}
