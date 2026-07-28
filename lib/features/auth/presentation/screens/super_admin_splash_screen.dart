import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../admin/presentation/providers/admin_provider.dart';

class SuperAdminSplashScreen extends StatefulWidget {
  const SuperAdminSplashScreen({super.key});

  @override
  State<SuperAdminSplashScreen> createState() => _SuperAdminSplashScreenState();
}

class _SuperAdminSplashScreenState extends State<SuperAdminSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final adminProvider = context.read<AdminProvider>();
    await adminProvider.checkAdminSession();
    final currentAdmin = adminProvider.currentAdmin;

    if (currentAdmin != null) {
      if (currentAdmin.role == 'super_admin') {
        context.go(AppRoutes.superAdminDashboard);
      } else if (currentAdmin.role == 'zonal_admin') {
        context.go(AppRoutes.adminUsers);
      } else {
        context.go(AppRoutes.superAdminLogin);
      }
    } else {
      context.go(AppRoutes.superAdminLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.brandBackground,
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&q=80&w=1000'
            ),
            opacity: 0.03, // translucent background watermark
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandSecondary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/kgra.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'KGRA SUPER ADMIN',
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Central Command & Control System',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFE2E8F0),
                  color: AppColors.brandPrimary,
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
