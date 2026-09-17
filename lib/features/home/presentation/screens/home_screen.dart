import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/app_pdf_viewer_screen.dart';
import '../../../ads/presentation/widgets/ad_carousel_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../events/data/models/event_model.dart';
import '../../../updates/presentation/providers/updates_provider.dart';
import '../../../updates/data/models/update_model.dart';
import '../../../government_orders/presentation/providers/government_orders_provider.dart';
import '../../../government_orders/data/models/government_order_model.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../meeting_minutes/presentation/providers/meeting_minutes_provider.dart';
import '../../../meeting_minutes/data/models/meeting_minutes_model.dart';
import '../../../live_sessions/presentation/providers/live_sessions_provider.dart';
import '../../../live_sessions/data/models/live_session_model.dart';

// Color Palette Constants
const Color kBgColor = Color(0xFFF8F9FC);
const Color kPrimaryColor = Color(0xFF8B1E2D);
const Color kSecondaryColor = Color(0xFFC0392B);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kWarningColor = Color(0xFFF39C12);
const Color kPurpleColor = Color(0xFF7C4DFF);
const Color kBlueColor = Color(0xFF3B82F6);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kDividerColor = Color(0xFFECECEC);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EventProvider>().fetchEvents();
      context.read<LiveSessionProvider>().fetchLiveSessions();
      context.read<UpdatesProvider>().fetchUpdates();
      context.read<GovernmentOrdersProvider>().fetchAllOrders();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning 👋';
    } else if (hour < 17) {
      return 'Good Afternoon 👋';
    } else {
      return 'Good Evening 👋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final userName = currentUser?.name ?? 'Vanessa';
    final membershipId = currentUser?.membershipId ?? 'KGRA-2026-MEMBER';

    // Grid action items mapping
    final allGridItems = [
      _GridItem(
        title: 'State Committee Members',
        icon: LucideIcons.users,
        iconColor: kBlueColor,
        bgColor: kBlueColor.withOpacity(0.08),
        onTap: () => context.push(AppRoutes.stateCommittee),
      ),
      _GridItem(
        title: 'Executive Committee Members',
        icon: LucideIcons.award,
        iconColor: const Color(0xFFE11D48),
        bgColor: const Color(0xFFE11D48).withOpacity(0.08),
        onTap: () => context.push(AppRoutes.executiveCommittee),
      ),
      _GridItem(
        title: 'Zonal Committee Members',
        icon: LucideIcons.map,
        iconColor: kPurpleColor,
        bgColor: kPurpleColor.withOpacity(0.08),
        onTap: () => context.push(AppRoutes.zonalCommittee),
      ),
      _GridItem(
        title: 'Meeting Minutes',
        icon: LucideIcons.fileText,
        iconColor: kPrimaryColor,
        bgColor: kPrimaryColor.withOpacity(0.08),
        onTap: () => context.push(AppRoutes.meetingMinutes),
      ),
      _GridItem(
        title: 'Gallery',
        icon: LucideIcons.image,
        iconColor: kSecondaryColor,
        bgColor: kSecondaryColor.withOpacity(0.08),
        onTap: () => context.push(AppRoutes.gallery),
      ),
      _GridItem(
        title: 'Forms',
        icon: LucideIcons.fileSpreadsheet,
        iconColor: const Color(0xFF0D9488),
        bgColor: const Color(0xFF0D9488).withOpacity(0.08),
        onTap: () => context.push(AppRoutes.formsCirculars),
      ),

      _GridItem(
        title: 'Membership',
        icon: LucideIcons.userPlus,
        iconColor: kSuccessColor,
        bgColor: kSuccessColor.withOpacity(0.08),
        isComingSoon: true,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Membership Registration...')),
          );
        },
      ),
      _GridItem(
        title: 'Beneficiary Scheme',
        icon: LucideIcons.heartHandshake,
        iconColor: const Color(0xFFEC4899),
        bgColor: const Color(0xFFEC4899).withOpacity(0.08),
        isComingSoon: true,
        onTap: () => context.push(AppRoutes.beneficiary),
      ),

      _GridItem(
        title: 'Live Session',
        icon: LucideIcons.video,
        iconColor: kSecondaryColor,
        bgColor: kSecondaryColor.withOpacity(0.08),
        onTap: () => context.push(AppRoutes.liveSessions),
      ),
      _GridItem(
        title: 'Educational Video',
        icon: LucideIcons.playCircle,
        iconColor: const Color(0xFF0891B2),
        bgColor: const Color(0xFF0891B2).withOpacity(0.08),
        onTap: () => context.push(AppRoutes.videos),
      ),
    ];

    // Filter items based on search query
    final filteredGridItems = allGridItems.where((item) {
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Compact Header (110px)
            SliverToBoxAdapter(
              child: Container(
                height: 110,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // Profile Image (56x56)
                    _buildProfileImage(context, authProvider),
                    const SizedBox(width: 16),
                    // Greeting text and Membership ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getGreeting(),
                            style: GoogleFonts.inter(
                              color: kTextSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hello, $userName',
                            style: GoogleFonts.inter(
                              color: kTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ID: $membershipId',
                              style: GoogleFonts.inter(
                                color: kPrimaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification Button (Rounded Square 48x48)
                    _buildNotificationButton(context),
                  ],
                ),
              ),
            ),

            // 2. Banner Slider (AdCarouselWidget Redesigned)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: const AdCarouselWidget(),
              ),
            ),

            // Spacing 24px
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // // 3. Search Bar
            // SliverPadding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
            //   sliver: SliverToBoxAdapter(
            //     child: Row(
            //       children: [
            //         Expanded(
            //           child: Container(
            //             height: 56,
            //             decoration: BoxDecoration(
            //               color: kCardColor,
            //               borderRadius: BorderRadius.circular(16),
            //               boxShadow: [
            //                 BoxShadow(
            //                   color: Colors.black.withOpacity(0.08),
            //                   blurRadius: 20,
            //                   offset: const Offset(0, 6),
            //                 ),
            //               ],
            //             ),
            //             child: TextField(
            //               controller: _searchController,
            //               onChanged: (val) {
            //                 setState(() {
            //                   _searchQuery = val;
            //                 });
            //               },
            //               decoration: InputDecoration(
            //                 hintText: 'Search anything...',
            //                 hintStyle: GoogleFonts.inter(
            //                   color: kTextSecondary,
            //                   fontSize: 15,
            //                 ),
            //                 prefixIcon: const Icon(
            //                   LucideIcons.search,
            //                   color: kTextSecondary,
            //                   size: 20,
            //                 ),
            //                 border: InputBorder.none,
            //                 contentPadding: const EdgeInsets.symmetric(vertical: 18),
            //               ),
            //             ),
            //           ),
            //         ),
            //         const SizedBox(width: 12),
            //         PressScaleWidget(
            //           onTap: () {
            //             ScaffoldMessenger.of(context).showSnackBar(
            //               const SnackBar(content: Text('Filter options coming soon...')),
            //             );
            //           },
            //           child: Container(
            //             width: 56,
            //             height: 56,
            //             decoration: BoxDecoration(
            //               color: kCardColor,
            //               borderRadius: BorderRadius.circular(16),
            //               boxShadow: [
            //                 BoxShadow(
            //                   color: Colors.black.withOpacity(0.08),
            //                   blurRadius: 20,
            //                   offset: const Offset(0, 6),
            //                 ),
            //               ],
            //             ),
            //             child: const Icon(
            //               LucideIcons.sliders,
            //               color: kPrimaryColor,
            //               size: 20,
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            // Spacing 24px
            // const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 4. Quick Actions
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.inter(
                            color: kTextPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // GestureDetector(
                        //   onTap: () {
                        //     setState(() {
                        //       _searchController.clear();
                        //       _searchQuery = '';
                        //     });
                        //   },
                        //   child: Text(
                        //     'View All',
                        //     style: GoogleFonts.inter(
                        //       color: kPrimaryColor,
                        //       fontSize: 13,
                        //       fontWeight: FontWeight.w600,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    filteredGridItems.isEmpty
                        ? Container(
                            height: 100,
                            alignment: Alignment.center,
                            child: Text(
                              'No actions found',
                              style: GoogleFonts.inter(color: kTextSecondary),
                            ),
                          )
                        : GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.82,
                            children: filteredGridItems.map((item) {
                              return _buildActionCard(context, item);
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),

            // Spacing 24px
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 5. Upcoming Meetings & Live Sessions Section
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final eventProvider = context.watch<EventProvider>();
                  final liveProvider = context.watch<LiveSessionProvider>();

                  final events = eventProvider.eventsList;
                  final liveSessions = liveProvider.sessionsList;

                  final now = DateTime.now();
                  final todayStr = DateFormat('yyyy-MM-dd').format(now);

                  final upcomingEvents = events.where((e) => e.date.compareTo(todayStr) >= 0).toList();
                  upcomingEvents.sort((a, b) => a.date.compareTo(b.date));

                  final upcomingLive = liveSessions.where((s) => s.date.isEmpty || s.date.compareTo(todayStr) >= 0).toList();

                  if (upcomingEvents.isEmpty && upcomingLive.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Meetings & Live Sessions',
                          style: GoogleFonts.inter(
                            color: kTextPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...upcomingEvents.map((e) => _buildUpcomingEventCard(context, e)),
                        ...upcomingLive.map((s) => _buildUpcomingLiveSessionCard(context, s)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 6. Latest Updates Section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Latest Updates',
                          style: GoogleFonts.inter(
                            color: kTextPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.updates),
                          child: Text(
                            'View All',
                            style: GoogleFonts.inter(
                              color: kPrimaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLatestUpdatesList(context),
                  ],
                ),
              ),
            ),

            // Spacing 24px
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 7. Recent Documents Section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Documents',
                          style: GoogleFonts.inter(
                            color: kTextPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.governmentOrders),
                          child: Text(
                            'View All',
                            style: GoogleFonts.inter(
                              color: kPrimaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentDocumentsSlider(context),
                  ],
                ),
              ),
            ),

            // Bottom space so we don't overlap with floating WhatsApp button & Navigation
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // Widget Builders
  // ----------------------------------------------------

  Widget _buildProfileImage(BuildContext context, AuthProvider authProvider) {
    final profileImageId = authProvider.currentUser?.profileImageId;
    
    Widget imageWidget;
    if (profileImageId != null && profileImageId.startsWith('http')) {
      imageWidget = Image.network(
        profileImageId,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatarChild(),
      );
    } else {
      final base64Image = authProvider.currentUserPhotoBase64;
      if (base64Image != null && base64Image.isNotEmpty) {
        try {
          final decodedBytes = base64Decode(base64Image);
          imageWidget = Image.memory(
            decodedBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatarChild(),
          );
        } catch (_) {
          imageWidget = _buildDefaultAvatarChild();
        }
      } else {
        imageWidget = _buildDefaultAvatarChild();
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: kPrimaryColor.withOpacity(0.15),
          width: 2.0,
        ),
      ),
      child: ClipOval(child: imageWidget),
    );
  }

  Widget _buildDefaultAvatarChild() {
    return Container(
      color: kPrimaryColor.withOpacity(0.08),
      child: const Center(
        child: Icon(
          Icons.person,
          color: kPrimaryColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notificationCount = notificationProvider.totalCount;

    return PressScaleWidget(
      onTap: () => context.push(AppRoutes.notification),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(
              LucideIcons.bell,
              color: kTextPrimary,
              size: 22,
            ),
            if (notificationCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, _GridItem item) {
    return PressScaleWidget(
      onTap: item.isComingSoon
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title} is coming soon!'),
                  backgroundColor: kPrimaryColor,
                ),
              );
            }
          : item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kTextPrimary,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (item.isComingSoon)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: kWarningColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventCard(BuildContext context, EventModel event) {
    final dateTime = DateTime.tryParse(event.date);
    final monthStr = dateTime != null ? DateFormat('MMM').format(dateTime).toUpperCase() : 'EVENT';
    final dayStr = dateTime != null ? DateFormat('d').format(dateTime) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date Card (64x74)
            Container(
              width: 64,
              height: 74,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimaryColor.withValues(alpha: 0.12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthStr,
                    style: GoogleFonts.inter(
                      color: kPrimaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayStr,
                    style: GoogleFonts.inter(
                      color: kPrimaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.inter(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: kTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        event.time,
                        style: GoogleFonts.inter(
                          color: kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined, size: 13, color: kTextSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          style: GoogleFonts.inter(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Overlapping Person Badges + +12 others (Exact representation from Image 2)
                  Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 22,
                        child: Stack(
                          children: List.generate(3, (idx) {
                            return Positioned(
                              left: idx * 14.0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFE9ED),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 13,
                                    color: Color(0xFF8B1E2D),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+12 others',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // NO Join button for events per user directive!
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingLiveSessionCard(BuildContext context, LiveSessionModel session) {
    final dateTime = DateTime.tryParse(session.date);
    final monthStr = dateTime != null ? DateFormat('MMM').format(dateTime).toUpperCase() : 'LIVE';
    final dayStr = dateTime != null ? DateFormat('d').format(dateTime) : 'NOW';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Live Session Date Badge
            Container(
              width: 64,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthStr,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayStr,
                    style: GoogleFonts.inter(
                      color: Colors.red.shade800,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    session.title,
                    style: GoogleFonts.inter(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.description.isNotEmpty ? session.description : 'Interactive Live Session',
                    style: GoogleFonts.inter(
                      color: kTextSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Join Button for Live Sessions
            PressScaleWidget(
              onTap: () async {
                final uri = Uri.parse(session.url.trim());
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open link: ${session.url}')),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Join',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestUpdatesList(BuildContext context) {
    final updatesProvider = context.watch<UpdatesProvider>();
    final updatesList = updatesProvider.updatesList;

    if (updatesProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    final displayUpdates = updatesList.isNotEmpty
        ? updatesList.take(3).toList()
        : [
            const _MockUpdate(
              title: 'Govt. Order Revision Approved',
              subtitle: 'Revised allowances and salary revision directives inside.',
              time: '2 hours ago',
              isNew: true,
            ),
            const _MockUpdate(
              title: 'KGRA Zonal Meeting Schedule',
              subtitle: 'All members requested to join scheduled zonal meeting.',
              time: '1 day ago',
              isNew: false,
            ),
          ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayUpdates.length,
      itemBuilder: (context, index) {
        final item = displayUpdates[index];
        final String title = item is _MockUpdate ? item.title : (item as UpdateModel).title;
        final String subtitle = item is _MockUpdate ? item.subtitle : (item as UpdateModel).content;
        final String dateStr = item is _MockUpdate ? item.time : (item as UpdateModel).date;
        final bool showNewBadge = item is _MockUpdate ? item.isNew : index == 0;

        return PressScaleWidget(
          onTap: () => context.push(AppRoutes.updates),
          child: Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Left Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.megaphone,
                      color: kSecondaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  color: kTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showNewBadge) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kSecondaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'NEW',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: kTextSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentDocumentsSlider(BuildContext context) {
    final docsProvider = context.watch<GovernmentOrdersProvider>();
    final minutesProvider = context.watch<MeetingMinutesProvider>();

    final docsList = docsProvider.orders;
    final minutesList = minutesProvider.minutesList;

    if (docsProvider.isLoading || minutesProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    // Combine both lists and sort them by createdAt desc
    final List<dynamic> combinedDocs = [];
    combinedDocs.addAll(docsList);
    combinedDocs.addAll(minutesList.where((m) => m.status == 'approved'));

    // Sort by createdAt descending
    combinedDocs.sort((a, b) {
      final aCreated = a is GovernmentOrderModel ? a.createdAt : (a as MeetingMinutesModel).createdAt;
      final bCreated = b is GovernmentOrderModel ? b.createdAt : (b as MeetingMinutesModel).createdAt;
      return bCreated.compareTo(aCreated);
    });

    final displayDocs = combinedDocs.isNotEmpty
        ? combinedDocs
        : [
            const _MockDoc(
              id: 'mock_doc_1',
              title: 'Order revision no. 43',
              size: '1.4 MB',
              pdfUrl: 'mock_pdf_1',
            ),
            const _MockDoc(
              id: 'mock_doc_2',
              title: 'Zonal circular update',
              size: '0.8 MB',
              pdfUrl: 'mock_pdf_2',
            ),
            const _MockDoc(
              id: 'mock_doc_3',
              title: 'Headquarters circular',
              size: '2.1 MB',
              pdfUrl: 'mock_pdf_3',
            ),
          ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: displayDocs.length,
        itemBuilder: (context, index) {
          final doc = displayDocs[index];
          final String title;
          final String size;
          final String pdfUrl;
          final String docId;
          final String folderName;

          if (doc is _MockDoc) {
            title = doc.title;
            size = doc.size;
            pdfUrl = doc.pdfUrl;
            docId = doc.id;
            folderName = 'government_orders';
          } else if (doc is GovernmentOrderModel) {
            title = doc.title;
            size = '1.2 MB';
            pdfUrl = doc.pdfUrl;
            docId = doc.id;
            folderName = 'government_orders';
          } else { // MeetingMinutesModel
            final m = doc as MeetingMinutesModel;
            title = m.title;
            size = '1.2 MB';
            pdfUrl = m.pdfUrl;
            docId = m.id;
            folderName = 'meeting_minutes';
          }

          return PressScaleWidget(
            onTap: () {
              if (pdfUrl.startsWith('http')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppPdfViewerScreen(
                      pdfUrl: pdfUrl,
                      title: title,
                      folderName: folderName,
                      docId: docId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Viewing PDF: $title'),
                    backgroundColor: kPrimaryColor,
                  ),
                );
              }
            },
            child: Container(
              width: 180,
              height: 90,
              margin: const EdgeInsets.only(right: 14, bottom: 8),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // PDF Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.fileText,
                        color: kPrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: kTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            size,
                            style: GoogleFonts.inter(
                              color: kTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Download icon
                    Icon(
                      LucideIcons.arrowDownCircle,
                      color: kPrimaryColor.withOpacity(0.6),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// Custom Helper Widgets & Classes
// ----------------------------------------------------

class PressScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const PressScaleWidget({super.key, required this.child, required this.onTap});

  @override
  State<PressScaleWidget> createState() => _PressScaleWidgetState();
}

class _PressScaleWidgetState extends State<PressScaleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class _GridItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isComingSoon;

  const _GridItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
    this.isComingSoon = false,
  });
}

class _MockUpdate {
  final String title;
  final String subtitle;
  final String time;
  final bool isNew;

  const _MockUpdate({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isNew,
  });
}

class _MockDoc {
  final String id;
  final String title;
  final String size;
  final String pdfUrl;

  const _MockDoc({
    required this.id,
    required this.title,
    required this.size,
    required this.pdfUrl,
  });
}
