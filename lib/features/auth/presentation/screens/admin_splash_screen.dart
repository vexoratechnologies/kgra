import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../admin/presentation/providers/admin_provider.dart';

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen> {
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
        context.go(AppRoutes.adminLogin);
      }
    } else {
      context.go(AppRoutes.adminLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2E30), // Sophisticated dark charcoal/gray
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
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
              'KGRA ZONAL ADMIN',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Zonal Admin Portal & Management System',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Colors.white,
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
