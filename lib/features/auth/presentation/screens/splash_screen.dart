import 'dart:math' show pi, sin, cos;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';

/// UserSplashScreen loads the app state, checks auth session, and redirects.
/// It features a custom premium animation system with wavy graphics and loading indicators.
class UserSplashScreen extends StatefulWidget {
  const UserSplashScreen({super.key});

  @override
  State<UserSplashScreen> createState() => _UserSplashScreenState();
}

class _UserSplashScreenState extends State<UserSplashScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _dotsController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Animation Controllers
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Trigger app state checking and routing
    _initApp();
  }

  @override
  void dispose() {
    _waveController.dispose();
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
          // Background Graphic Canvas (Parallax Waves, Circle and Grid)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundWavesPainter(waveValue: _waveController.value),
                );
              },
            ),
          ),
          
          // Central Column Branding & Loading
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  
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
                        'assets/icon/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Safe fallback to kgra.jpeg if app_icon is missing or building locally
                          return Image.asset(
                            'assets/icon/kgra.jpeg',
                            fit: BoxFit.cover,
                          );
                        },
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
                  
                  const Spacer(flex: 2),
                  
                  // Loading Indicator: Short Accent Line
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF731C29),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pagination Dots Cycling Animation
                  AnimatedBuilder(
                    animation: _dotsController,
                    builder: (context, child) {
                      final int activeIndex = (_dotsController.value * 4).floor() % 4;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final bool isActive = index == activeIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            width: isActive ? 9.0 : 6.0,
                            height: isActive ? 9.0 : 6.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? const Color(0xFF731C29)
                                  : const Color(0xFFD29FA3).withOpacity(0.4),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Loading Text (Pulsing)
                  FadeTransition(
                    opacity: _pulseAnimation,
                    child: Text(
                      'LOADING...',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF731C29),
                        letterSpacing: 3.5,
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Background Painter to render the fluid wave graphics and dotted elements
class BackgroundWavesPainter extends CustomPainter {
  final double waveValue;

  BackgroundWavesPainter({required this.waveValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dotted Grid Pattern (Upper-Left background layer)
    final dotPaint = Paint()
      ..color = const Color(0xFFD29FA3).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j < 7; j++) {
        canvas.drawCircle(
          Offset(30.0 + i * 16.0, 70.0 + j * 16.0),
          1.5,
          dotPaint,
        );
      }
    }

    // 2. Faint Circle Outline (Upper-Right background layer)
    final circlePaint = Paint()
      ..color = const Color(0xFFD29FA3).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      size.width * 0.18,
      circlePaint,
    );

    // Compute dynamic parallax shifts using sine and cosine functions
    final double waveShiftX1 = sin(waveValue * 2 * pi) * 8.0;
    final double waveShiftY1 = cos(waveValue * 2 * pi) * 6.0;
    final double waveShiftX2 = cos(waveValue * 2 * pi) * 10.0;
    final double waveShiftY2 = sin(waveValue * 2 * pi) * 5.0;

    // 3. Top-Left Waves (Dusty Rose Layer - Behind)
    final topRosePath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.72 + waveShiftX1, 0)
      ..cubicTo(
        size.width * 0.55 + waveShiftX2,
        size.height * 0.16 + waveShiftY1,
        size.width * 0.20 + waveShiftX1,
        size.height * 0.22 + waveShiftY2,
        0,
        size.height * 0.26 + waveShiftY1,
      )
      ..close();
    
    canvas.drawPath(
      topRosePath,
      Paint()..color = const Color(0xFFD29FA3).withOpacity(0.75),
    );

    // 4. Top-Left Waves (Deep Maroon Layer - Front)
    final topMaroonPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.58 + waveShiftX2, 0)
      ..cubicTo(
        size.width * 0.42 + waveShiftX1,
        size.height * 0.12 + waveShiftY2,
        size.width * 0.15 + waveShiftX2,
        size.height * 0.18 + waveShiftY1,
        0,
        size.height * 0.20 + waveShiftY2,
      )
      ..close();

    canvas.drawPath(
      topMaroonPath,
      Paint()..color = const Color(0xFF731C29),
    );

    // 5. Bottom-Right Waves (Dusty Rose Layer - Behind)
    final bottomRosePath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.22 - waveShiftX1, size.height)
      ..cubicTo(
        size.width * 0.38 - waveShiftX2,
        size.height * 0.82 - waveShiftY1,
        size.width * 0.78 - waveShiftX1,
        size.height * 0.76 - waveShiftY2,
        size.width,
        size.height * 0.62 - waveShiftY1,
      )
      ..close();

    canvas.drawPath(
      bottomRosePath,
      Paint()..color = const Color(0xFFD29FA3).withOpacity(0.75),
    );

    // 6. Bottom-Right Waves (Deep Maroon Layer - Front)
    final bottomMaroonPath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.38 - waveShiftX2, size.height)
      ..cubicTo(
        size.width * 0.52 - waveShiftX1,
        size.height * 0.88 - waveShiftY2,
        size.width * 0.82 - waveShiftX2,
        size.height * 0.80 - waveShiftY1,
        size.width,
        size.height * 0.70 - waveShiftY2,
      )
      ..close();

    canvas.drawPath(
      bottomMaroonPath,
      Paint()..color = const Color(0xFF731C29),
    );
  }

  @override
  bool shouldRepaint(covariant BackgroundWavesPainter oldDelegate) {
    return oldDelegate.waveValue != waveValue;
  }
}
