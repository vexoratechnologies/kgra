import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/authentication_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/storage_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/state_committee/data/repositories/state_committee_repository.dart';
import 'features/state_committee/presentation/providers/state_committee_provider.dart';
import 'features/meeting_minutes/data/repositories/meeting_minutes_repository.dart';
import 'features/meeting_minutes/presentation/providers/meeting_minutes_provider.dart';
import 'features/government_orders/data/repositories/government_order_repository.dart';
import 'features/government_orders/presentation/providers/government_orders_provider.dart';
import 'features/forms_circulars/data/repositories/form_circular_repository.dart';
import 'features/forms_circulars/presentation/providers/forms_circulars_provider.dart';
import 'features/zonal/data/repositories/zonal_repository.dart';
import 'features/zonal/presentation/providers/zonal_provider.dart';
import 'features/updates/data/repositories/updates_repository.dart';
import 'features/updates/presentation/providers/updates_provider.dart';
import 'features/notification/data/repositories/notification_repository.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/live_sessions/data/repositories/live_sessions_repository.dart';
import 'features/live_sessions/presentation/providers/live_sessions_provider.dart';
import 'features/gallery/data/repositories/gallery_repository.dart';
import 'features/gallery/presentation/providers/gallery_provider.dart';
import 'features/videos/data/repositories/video_repository.dart';
import 'features/videos/presentation/providers/video_provider.dart';
import 'features/ads/data/repositories/ad_repository.dart';
import 'features/ads/presentation/providers/ad_provider.dart';
import 'features/events/data/repositories/event_repository.dart';
import 'features/events/presentation/providers/event_provider.dart';

/// Global service locator instance.
final GetIt locator = GetIt.instance;

/// Setup dependency injection for the entire application.
/// 
/// Registers services, repositories, and providers required for startup.
Future<void> initInjection() async {
  // Pre-initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);

  // Services
  locator.registerLazySingleton<FirestoreService>(
    () => FirestoreService(),
  );
  locator.registerLazySingleton<AuthenticationService>(
    () => AuthenticationService(),
  );
  locator.registerLazySingleton<StorageService>(
    () => StorageService(),
  );

  // Repositories
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      authService: locator<AuthenticationService>(),
      firestoreService: locator<FirestoreService>(),
      prefs: locator<SharedPreferences>(),
    ),
  );
  locator.registerLazySingleton<AdminRepository>(
    () => AdminRepository(
      firestoreService: locator<FirestoreService>(),
    ),
  );
  locator.registerLazySingleton<StateCommitteeRepository>(
    () => StateCommitteeRepository(
      firestoreService: locator<FirestoreService>(),
    ),
  );
  locator.registerLazySingleton<MeetingMinutesRepository>(
    () => MeetingMinutesRepository(
      firestoreService: locator<FirestoreService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<GovernmentOrderRepository>(
    () => GovernmentOrderRepository(
      firestoreService: locator<FirestoreService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<FormCircularRepository>(
    () => FormCircularRepository(
      firestoreService: locator<FirestoreService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<ZonalRepository>(
    () => ZonalRepository(
      firestoreService: locator<FirestoreService>(),
    ),
  );
  locator.registerLazySingleton<UpdatesRepository>(
    () => UpdatesRepository(
      firestoreService: locator<FirestoreService>(),
    ),
  );
  locator.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(
      firestoreService: locator<FirestoreService>(),
    ),
  );
  locator.registerLazySingleton<LiveSessionRepository>(
    () => LiveSessionRepository(
      firestoreService: locator<FirestoreService>(),
    ),
  );
  locator.registerLazySingleton<GalleryRepository>(
    () => GalleryRepository(
      firestoreService: locator<FirestoreService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<VideoRepository>(
    () => VideoRepository(
      firestoreService: locator<FirestoreService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<EventRepository>(
    () => EventRepository(
      firestoreService: locator<FirestoreService>(),
    ),
  );
  locator.registerLazySingleton<AdRepository>(
    () => AdRepository(
      firestoreService: locator<FirestoreService>(),
      storageService: locator<StorageService>(),
    ),
  );

  // Providers (ChangeNotifiers must be factory or singleton, provider wraps creation)
  locator.registerFactory<AuthProvider>(
    () => AuthProvider(authRepository: locator<AuthRepository>()),
  );
  locator.registerFactory<AdminProvider>(
    () => AdminProvider(
      adminRepository: locator<AdminRepository>(),
      prefs: locator<SharedPreferences>(),
    ),
  );
  locator.registerFactory<StateCommitteeProvider>(
    () => StateCommitteeProvider(repository: locator<StateCommitteeRepository>()),
  );
  locator.registerFactory<MeetingMinutesProvider>(
    () => MeetingMinutesProvider(repository: locator<MeetingMinutesRepository>()),
  );
  locator.registerFactory<GovernmentOrdersProvider>(
    () => GovernmentOrdersProvider(repository: locator<GovernmentOrderRepository>()),
  );
  locator.registerFactory<FormsCircularsProvider>(
    () => FormsCircularsProvider(repository: locator<FormCircularRepository>()),
  );
  locator.registerFactory<ZonalProvider>(
    () => ZonalProvider(repository: locator<ZonalRepository>()),
  );
  locator.registerFactory<UpdatesProvider>(
    () => UpdatesProvider(repository: locator<UpdatesRepository>()),
  );
  locator.registerFactory<NotificationProvider>(
    () => NotificationProvider(
      repository: locator<NotificationRepository>(),
      prefs: locator<SharedPreferences>(),
    ),
  );
  locator.registerFactory<LiveSessionProvider>(
    () => LiveSessionProvider(repository: locator<LiveSessionRepository>()),
  );
  locator.registerFactory<GalleryProvider>(
    () => GalleryProvider(repository: locator<GalleryRepository>()),
  );
  locator.registerFactory<VideoProvider>(
    () => VideoProvider(repository: locator<VideoRepository>()),
  );
  locator.registerFactory<AdProvider>(
    () => AdProvider(repository: locator<AdRepository>()),
  );
  locator.registerFactory<EventProvider>(
    () => EventProvider(repository: locator<EventRepository>()),
  );
}
