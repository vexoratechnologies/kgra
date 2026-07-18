import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/state_committee/presentation/providers/state_committee_provider.dart';
import 'features/meeting_minutes/presentation/providers/meeting_minutes_provider.dart';
import 'features/government_orders/presentation/providers/government_orders_provider.dart';
import 'features/forms_circulars/presentation/providers/forms_circulars_provider.dart';
import 'features/zonal/presentation/providers/zonal_provider.dart';
import 'features/updates/presentation/providers/updates_provider.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/live_sessions/presentation/providers/live_sessions_provider.dart';
import 'features/gallery/presentation/providers/gallery_provider.dart';
import 'features/videos/presentation/providers/video_provider.dart';
import 'features/ads/presentation/providers/ad_provider.dart';
import 'features/events/presentation/providers/event_provider.dart';
import 'injection.dart';

/// The root App widget of the My KGRA Mobile Application.
/// 
/// Wraps MaterialApp in MultiProvider to inject design system and core providers.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => locator<AuthProvider>(),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => locator<AdminProvider>(),
        ),
        ChangeNotifierProvider<StateCommitteeProvider>(
          create: (_) => locator<StateCommitteeProvider>(),
        ),
        ChangeNotifierProvider<MeetingMinutesProvider>(
          create: (_) => locator<MeetingMinutesProvider>(),
        ),
        ChangeNotifierProvider<GovernmentOrdersProvider>(
          create: (_) => locator<GovernmentOrdersProvider>(),
        ),
        ChangeNotifierProvider<FormsCircularsProvider>(
          create: (_) => locator<FormsCircularsProvider>(),
        ),
        ChangeNotifierProvider<ZonalProvider>(
          create: (_) => locator<ZonalProvider>(),
        ),
        ChangeNotifierProvider<UpdatesProvider>(
          create: (_) => locator<UpdatesProvider>(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => locator<NotificationProvider>(),
        ),
        ChangeNotifierProvider<LiveSessionProvider>(
          create: (_) => locator<LiveSessionProvider>(),
        ),
        ChangeNotifierProvider<GalleryProvider>(
          create: (_) => locator<GalleryProvider>(),
        ),
        ChangeNotifierProvider<VideoProvider>(
          create: (_) => locator<VideoProvider>(),
        ),
        ChangeNotifierProvider<AdProvider>(
          create: (_) => locator<AdProvider>(),
        ),
        ChangeNotifierProvider<EventProvider>(
          create: (_) => locator<EventProvider>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'My KGRA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
