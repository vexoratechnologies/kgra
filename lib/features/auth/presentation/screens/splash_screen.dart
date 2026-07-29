import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';

/// UserSplashScreen loads the app state, checks auth session, and redirects.
/// It features a background image and a centered logo branding block with bottom loading animation.
class UserSplashScreen extends StatefulWidget {
  const UserSplashScreen({super.key});

  @override
  State<UserSplashScreen> createState() => _UserSplashScreenState();
}

class _UserSplashScreenState extends State<UserSplashScreen> with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controllers
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Trigger app state checking and routing
    _initApp();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    final startTime = DateTime.now();

    // Start session checking and state restoration in parallel
    final adminProvider = context.read<AdminProvider>();
    final checkAdminFuture = adminProvider.checkAdminSession();
    
    final authProvider = context.read<AuthProvider>();
    final checkAuthFuture = authProvider.checkAuthStatus();

    await Future.wait([checkAdminFuture, checkAuthFuture]);

    // Ensure splash screen brand exposure of at least 2500ms
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 2500) - elapsed;
    // final remaining = const Duration(milliseconds: 200500) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;
    
    // Check if an admin/super-admin session exists first
    final currentAdmin = adminProvider.currentAdmin;
    if (currentAdmin != null) {
      if (currentAdmin.role == 'super_admin') {
        context.go(AppRoutes.superAdminDashboard);
        return;
      } else if (currentAdmin.role == 'zonal_admin') {
        context.go(AppRoutes.adminUsers);
        return;
      }
    }
    
    // Navigation routing logic based on session data
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
      backgroundColor: const Color(0xFFFDFBF8),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/icon/splash.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          
          // Central Logo Branding (Exactly in the center of the page)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Brand Logo Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF731C29).withOpacity(0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFD29FA3).withOpacity(0.4),
                      width: 2.0,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/kgra.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title: MY KGRA
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                    children: const [
                      TextSpan(
                        text: 'MY ',
                        style: TextStyle(color: Color(0xFF3D3D3D)),
                      ),
                      TextSpan(
                        text: 'KGRA',
                        style: TextStyle(color: Color(0xFF731C29)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Motto
                Text(
                  'UNITY • LEARNING • SERVICE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF731C29),
                    letterSpacing: 4.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Bottom Loading indicators (positioned relative to bottom)
          Positioned(
            bottom: 240,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Three-Dot Pulsing Loading Indicator (Middle dot is larger)
                AnimatedBuilder(
                  animation: _dotsController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final double delay = index * 0.25;
                        final double angle = (_dotsController.value * 2 * math.pi) - delay;
                        
                        final double scale = 1.0 + 0.3 * math.sin(angle);
                        final double opacity = 0.5 + 0.5 * math.sin(angle);
                        final double baseSize = index == 1 ? 16.0 : 8.0;

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6.0),
                            width: baseSize,
                            height: baseSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF731C29).withOpacity(opacity.clamp(0.0, 1.0)),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Loading Text (Pulsing)
                // FadeTransition(
                //   opacity: _pulseAnimation,
                //   child: Text(
                //     'LOADING...',
                //     style: GoogleFonts.inter(
                //       fontSize: 10,
                //       fontWeight: FontWeight.w700,
                //       color: const Color(0xFF731C29),
                //       letterSpacing: 3.5,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
