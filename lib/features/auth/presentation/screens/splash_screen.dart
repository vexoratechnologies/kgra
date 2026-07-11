import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../providers/auth_provider.dart';

/// UserSplashScreen loads the app state, checks auth session, and redirects.
class UserSplashScreen extends StatefulWidget {
  const UserSplashScreen({super.key});

  @override
  State<UserSplashScreen> createState() => _UserSplashScreenState();
}

class _UserSplashScreenState extends State<UserSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 1. Wait a moment for visual branding exposure
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    // 2. Check current authentication session in Firebase
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();
    
    if (!mounted) return;

    // 3. Navigation routing logic based on session data
    if (authProvider.isAuthenticated) {
      context.go(AppRoutes.home);
    } else if (authProvider.isPendingApproval) {
      context.go(AppRoutes.pending);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Caduceus medical-governmental logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandSecondary.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.healing_outlined,
                  size: 50,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'My KGRA',
              style: AppTextStyle.headlineLg(color: AppColors.brandSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kerala Government Radiographers\' Association',
              style: AppTextStyle.labelMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Soft progress bar indicator
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE2E8F0),
                color: AppColors.brandPrimary,
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
