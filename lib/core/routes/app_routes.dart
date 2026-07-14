import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/admin_splash_screen.dart';
import '../../features/auth/presentation/screens/super_admin_splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/home/presentation/screens/main_navigation_wrapper.dart';
import '../../features/state_committee/presentation/screens/state_committee_screen.dart';
import '../../features/meeting_minutes/presentation/screens/meeting_minutes_screen.dart';
import '../../features/government_orders/presentation/screens/government_orders_screen.dart';
import '../../features/forms_circulars/presentation/screens/forms_circulars_screen.dart';
import '../../features/updates/presentation/screens/updates_screen.dart';
import '../../features/notification/presentation/screens/notifications_screen.dart';
import '../../features/live_sessions/presentation/screens/live_sessions_screen.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/videos/presentation/screens/videos_catalog_screen.dart';
import '../../features/videos/presentation/screens/video_player_screen.dart';
import '../../features/videos/data/models/video_model.dart';
import '../../features/zonal/presentation/screens/zonal_committee_screen.dart';
import '../../features/auth/presentation/screens/admin_login_screen.dart';
import '../../features/admin/presentation/screens/super_admin_dashboard.dart';

/// AppRoutes defines all navigation routes and transition effects for the application.
/// 
/// It encapsulates centralized routing configuration to prevent scattered routes.
class AppRoutes {
  AppRoutes._();

  // Route paths
  static const String splash = '/';
  static const String adminSplash = '/admin';
  static const String superAdminSplash = '/superadmin';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String register = '/register';
  static const String pending = '/pending';
  static const String adminUsers = '/admin-users';
  static const String adminLogin = '/admin/login';
  static const String superAdminDashboard = '/admin/super-dashboard';
  
  static const String home = '/home';
  static const String profile = '/profile';
  static const String videos = '/videos';
  static const String videoDetails = '/video-details';
  static const String notification = '/notification';
  static const String liveSessions = '/live-sessions';
  static const String settings = '/settings';
  static const String payment = '/payment';
  static const String beneficiary = '/beneficiary';
  static const String stateCommittee = '/state-committee';
  static const String zonalCommittee = '/zonal-committee';
  static const String meetingMinutes = '/meeting-minutes';
  static const String governmentOrders = '/government-orders';
  static const String formsCirculars = '/forms-circulars';
  static const String updates = '/updates';
  static const String gallery = '/gallery';
  
  // Custom route that is useful for demonstrating the UI/Theme system
  static const String themeDemo = '/theme-demo';

  /// Helper to create a page with a custom Fade + Slide transition.
  /// Matches standard duration (300ms) and curve (easeInOutCubic) from PROJECT_RULES.md.
  static CustomTransitionPage<T> fadeSlideTransitionPage<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Offset beginOffset = const Offset(1.0, 0.0), // Defaults to Right -> Left
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide animation from beginOffset (e.g. [1,0] is Right -> Left)
        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        );

        // Fade animation
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Global GoRouter instance configuration
  static final GoRouter router = GoRouter(
    initialLocation: superAdminSplash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const UserSplashScreen(),
      ),
      GoRoute(
        path: adminSplash,
        builder: (context, state) => const AdminSplashScreen(),
      ),
      GoRoute(
        path: superAdminSplash,
        builder: (context, state) => const SuperAdminSplashScreen(),
      ),
      GoRoute(
        path: login,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: otp,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const OtpScreen(),
        ),
      ),
      GoRoute(
        path: register,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: pending,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const PendingApprovalScreen(),
        ),
      ),
      GoRoute(
        path: adminUsers,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const AdminUsersScreen(),
        ),
      ),
      GoRoute(
        path: adminLogin,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const AdminLoginScreen(),
        ),
      ),
      GoRoute(
        path: superAdminDashboard,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const SuperAdminDashboard(),
        ),
      ),
      GoRoute(
        path: home,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const MainNavigationWrapper(),
        ),
      ),
      GoRoute(
        path: profile,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const _PlaceholderScreen(title: 'User Profile'),
        ),
      ),
      GoRoute(
        path: videos,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const VideosCatalogScreen(),
        ),
      ),
      GoRoute(
        path: videoDetails,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: VideoPlayerScreen(
            video: state.extra as VideoModel,
          ),
        ),
      ),
      GoRoute(
        path: notification,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: settings,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const _PlaceholderScreen(title: 'Settings'),
        ),
      ),
      GoRoute(
        path: payment,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const _PlaceholderScreen(title: 'Payments'),
        ),
      ),
      GoRoute(
        path: beneficiary,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const _PlaceholderScreen(title: 'Beneficiary Management'),
        ),
      ),
      GoRoute(
        path: stateCommittee,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const StateCommitteeScreen(),
        ),
      ),
      GoRoute(
        path: zonalCommittee,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const ZonalCommitteeScreen(),
        ),
      ),
      GoRoute(
        path: updates,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const UpdatesScreen(),
        ),
      ),
      GoRoute(
        path: liveSessions,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const LiveSessionsScreen(),
        ),
      ),
      GoRoute(
        path: gallery,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const GalleryScreen(),
        ),
      ),
      GoRoute(
        path: meetingMinutes,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const MeetingMinutesScreen(),
        ),
      ),
      GoRoute(
        path: governmentOrders,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const GovernmentOrdersScreen(),
        ),
      ),
      GoRoute(
        path: formsCirculars,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const FormsCircularsScreen(),
        ),
      ),
      GoRoute(
        path: themeDemo,
        pageBuilder: (context, state) => fadeSlideTransitionPage(
          context: context,
          state: state,
          child: const _ThemeDemoScreen(),
        ),
      ),
    ],
  );

  /// Helper static method for demo headers
  static TextStyle titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      color: const Color(0xFF0F4C81),
      fontWeight: FontWeight.bold,
    );
  }
}

/// Simple placeholder screen used during initialization.
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.themeDemo);
              },
              child: const Text('Go to Theme & Colors Demo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dedicated screen to showcase and test the Clinical Integrity design system elements.
class _ThemeDemoScreen extends StatefulWidget {
  const _ThemeDemoScreen();

  @override
  State<_ThemeDemoScreen> createState() => _ThemeDemoScreenState();
}

class _ThemeDemoScreenState extends State<_ThemeDemoScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Integrity Style Guide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.splash),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typographies
            Text('Typography System', style: AppRoutes.titleStyle(context)),
            const SizedBox(height: 16),
            Text('Display Large: Jakarta Sans 40px', style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text('Headline Large: Jakarta Sans 32px', style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('Headline Mobile: Jakarta Sans 28px', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Title Large: Jakarta Sans 22px', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Body Large: Hanken Grotesk 18px. Use this for main editorial descriptions.', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Body Medium: Hanken Grotesk 16px. Standard body and reading parameters.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Label Medium: Hanken Grotesk 14px', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text('Label Small: Hanken Grotesk 12px', style: theme.textTheme.labelMedium),
            
            const Divider(height: 48),
            
            // Buttons
            Text('Interactive Buttons', style: AppRoutes.titleStyle(context)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Primary Button (Filled)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Secondary Button (Outlined)'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Tertiary / Ghost Button'),
              ),
            ),
            
            const Divider(height: 48),

            // Inputs
            Text('Input Fields (MD3 Enclosed)', style: AppRoutes.titleStyle(context)),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Username or Register Number',
                hintText: 'Enter your credentials',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            
            const Divider(height: 48),

            // Glassmorphism & Shadow levels
            Text('Elevation & Depth (Glassmorphic)', style: AppRoutes.titleStyle(context)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // Gradient start/end from description
                gradient: const LinearGradient(
                  colors: [Color(0xFF0057B8), Color(0xFF4DA6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Container with Gradient',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  // Glassmorphic Card overlaid on top of gradient to showcase transparency
                  _GlassOverlayContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal helper widget to render card with white border and transparency
class _GlassOverlayContent extends StatelessWidget {
  const _GlassOverlayContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C81).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overlaid Glassmorphic Container',
            style: TextStyle(color: Color(0xFF191C22), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'This card uses 80% opacity white with light shadow and white border to create light refraction.',
            style: TextStyle(color: Color(0xFF424752), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
