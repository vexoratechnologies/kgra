import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../providers/auth_provider.dart';

/// PendingApprovalScreen is shown when a user registers but is not yet approved.
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  Future<void> _handleCheckStatus(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkApprovalStatus();
    
    if (authProvider.isAuthenticated && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account approved! Logging in...'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(AppRoutes.home);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account registration is still pending approval.'),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                // Glassmorphic status container
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: AppRadius.borderXl,
                    border: Border.all(
                      color: AppColors.brandSecondary.withValues(alpha: 0.1),
                      width: 1,
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
                      // Pending Icon with pulse aura effect
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.pending_actions_outlined,
                            size: 40,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      Text(
                        'Approval Pending',
                        style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      Text(
                        'Your registration request has been successfully submitted to the administrator.\n\nTo ensure professional integrity, administrative approval is required before you can access the My KGRA member portal.',
                        style: AppTextStyle.bodyMd(color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Check Status button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading 
                              ? null 
                              : () => _handleCheckStatus(context),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Check Approval Status'),
                        ),
                      ),
                      
                      // Show mock simulator button if Firebase is not initialized
                      if (Firebase.apps.isEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brandPrimary,
                              side: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
                            ),
                            onPressed: authProvider.isLoading
                                ? null
                                : () async {
                                    await authProvider.simulateMockApproval();
                                    if (authProvider.isAuthenticated && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Simulated approval successful!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      context.go(AppRoutes.home);
                                    }
                                  },
                            child: const Text('Simulate Admin Approval (Mock Mode)'),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Sign out / Go back
                      TextButton(
                        onPressed: () async {
                          await authProvider.signOut();
                          if (context.mounted) {
                            context.go(AppRoutes.login);
                          }
                        },
                        child: Text(
                          'Back to Login',
                          style: AppTextStyle.labelMd(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.bold,
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
  ),
);
  }
}
