import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
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
    final currentAdmin = adminProvider.currentAdmin;

    if (currentAdmin != null && currentAdmin.role == 'super_admin') {
      context.go(AppRoutes.superAdminDashboard);
    } else {
      context.go(AppRoutes.superAdminLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0004), // Dark deep crimson/gold premium theme
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E0004), Color(0xFF3F0008)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.security_outlined,
                    size: 44,
                    color: Color(0xFFFFD700), // Gold
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'KGRA SUPER ADMIN',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFFFFD700), // Gold
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
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white10,
                  color: Color(0xFFFFD700),
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
