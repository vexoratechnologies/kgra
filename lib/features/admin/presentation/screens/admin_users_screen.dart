import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_pdf_viewer_screen.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../../../../core/utils/file_picker_helper.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/state_committee/presentation/providers/state_committee_provider.dart';
import '../../../../features/state_committee/data/models/committee_member_model.dart';
import '../../../../features/meeting_minutes/presentation/providers/meeting_minutes_provider.dart';
import '../../../../features/meeting_minutes/data/models/meeting_minutes_model.dart';
import '../../../../features/government_orders/presentation/providers/government_orders_provider.dart';
import '../../../../features/government_orders/data/models/government_order_model.dart';
import '../../../../features/forms_circulars/presentation/providers/forms_circulars_provider.dart';
import '../../../../features/forms_circulars/data/models/form_circular_model.dart';
import '../../../../features/zonal/presentation/providers/zonal_provider.dart';
import '../../../../features/zonal/data/models/zonal_member_model.dart';
import '../../../../features/updates/presentation/providers/updates_provider.dart';
import '../../../../features/updates/data/models/update_model.dart';
import '../../../../features/live_sessions/presentation/providers/live_sessions_provider.dart';
import '../../../../features/live_sessions/data/models/live_session_model.dart';
import '../../../../features/gallery/presentation/providers/gallery_provider.dart';
import '../../../../features/gallery/data/models/gallery_image_model.dart';
import '../../../../features/videos/presentation/providers/video_provider.dart';
import '../../../../features/videos/data/models/video_model.dart';
import '../../../../features/events/presentation/providers/event_provider.dart';
import '../../../../features/events/data/models/event_model.dart';
import '../providers/admin_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';


/// AdminUsersScreen lists pending registration requests and supports approved/rejected tabs.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeTab = 'Dashboard';
  String? _expandedUserUid;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Mock Settings States
  bool _autoApprove = false;
  String _clearanceLevel = 'General';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final adminProvider = context.read<AdminProvider>();
      if (adminProvider.currentAdmin == null) {
        await adminProvider.checkAdminSession();
      }
      final currentAdmin = adminProvider.currentAdmin;
      if (!mounted) return;
      if (currentAdmin == null || (currentAdmin.role != 'zonal_admin' && currentAdmin.role != 'super_admin')) {
        adminProvider.logoutAdmin();
        context.go(AppRoutes.adminLogin);
      } else {
        _refreshAllData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshAllData() {
    final provider = context.read<AdminProvider>();
    provider.fetchPendingUsers();
    provider.fetchApprovedUsers();
    provider.fetchRejectedUsers();

    // Fetch new modules
    context.read<StateCommitteeProvider>().fetchMembers();
    context.read<MeetingMinutesProvider>().fetchAllMinutes();
    context.read<GovernmentOrdersProvider>().fetchAllOrders();
    context.read<FormsCircularsProvider>().fetchAllForms();
    context.read<ZonalProvider>().fetchMembers();
    provider.fetchZones();
    provider.fetchDesignations();
    context.read<UpdatesProvider>().fetchUpdates();
    context.read<LiveSessionProvider>().fetchLiveSessions();
    context.read<GalleryProvider>().fetchImages();
    context.read<VideoProvider>().fetchVideos();
    context.read<EventProvider>().fetchEvents();
  }

  void _onTabChanged(String label) {
    if (label == 'Dashboard') {
      _refreshAllData();
    } else if (label == 'Pending Approvals') {
      context.read<AdminProvider>().fetchPendingUsers();
    } else if (label == 'Approved Members') {
      context.read<AdminProvider>().fetchApprovedUsers();
    } else if (label == 'Rejected Requests') {
      context.read<AdminProvider>().fetchRejectedUsers();
    } else if (label == 'Zonal Committee' || label == 'Executive Committee') {
      context.read<ZonalProvider>().fetchMembers();
    } else if (label == 'Meeting Minutes') {
      context.read<MeetingMinutesProvider>().fetchAllMinutes();
    } else if (label == 'Govt Orders') {
      context.read<GovernmentOrdersProvider>().fetchAllOrders();
    } else if (label == 'Forms & Circulars') {
      context.read<FormsCircularsProvider>().fetchAllForms();
    } else if (label == 'Updates') {
      context.read<UpdatesProvider>().fetchUpdates();
    } else if (label == 'Gallery') {
      context.read<GalleryProvider>().fetchImages();
    } else if (label == 'Videos') {
      context.read<VideoProvider>().fetchVideos();
    } else if (label == 'Events') {
      context.read<EventProvider>().fetchEvents();
    }
  }

  void _toggleExpand(UserModel user, AdminProvider provider) {
    setState(() {
      if (_expandedUserUid == user.uid) {
        _expandedUserUid = null;
      } else {
        _expandedUserUid = user.uid;
        if (user.profileImageId != null) {
          provider.fetchUserImage(user.profileImageId!, user.uid);
        }
      }
    });
  }

  Future<void> _handleApprove(BuildContext context, String uid, AdminProvider provider) async {
    final success = await provider.approveUser(uid);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User approved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context, String uid, AdminProvider provider) async {
    final success = await provider.rejectUser(uid);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User registration request rejected.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _searchQuery.toLowerCase();
    return users.where((u) {
      return u.name.toLowerCase().contains(query) ||
             u.phoneNumber.toLowerCase().contains(query) ||
             (u.designation?.toLowerCase().contains(query) ?? false) ||
             (u.institution?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 850;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? _buildSidebar(context, isMobile: true) : null,
      appBar: !isDesktop
          ? CompactAppBar(
              title: _activeTab,
              subtitle: 'Manage members & approvals',
              rightIcon: Icons.refresh,
              onRightTap: _refreshAllData,
              onBackTap: () {
                if (_scaffoldKey.currentState != null) {
                  _scaffoldKey.currentState!.openDrawer();
                }
              },
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDesktop ? AppColors.surfaceContainerLow : AppColors.brandBackground,
        child: SafeArea(
          child: Row(
            children: [
              if (isDesktop) _buildSidebar(context, isMobile: false),
              Expanded(
                child: isDesktop
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(context),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(24), // rounded-3xl
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _buildMainContent(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildMainContent(context),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: isDesktop ? BorderRadius.circular(20) : null,
        boxShadow: isDesktop ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
        border: isDesktop ? null : Border(
          bottom: BorderSide(
            color: AppColors.brandSecondary.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _activeTab,
            style: AppTextStyle.headlineLg(color: AppColors.brandSecondary).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
                  foregroundColor: AppColors.brandPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                ),
                onPressed: _refreshAllData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Data'),
              ),
              const SizedBox(width: AppSpacing.lg),
              const VerticalDivider(width: 1, indent: 8, endIndent: 8),
              const SizedBox(width: AppSpacing.lg),
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandPrimary,
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Admin Portal',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isMobile}) {
    final adminProvider = context.watch<AdminProvider>();
    final pendingCount = adminProvider.pendingUsers.length;

    final sidebarContent = Container(
      width: isMobile ? 260 : 220, // Slimmer profile
      height: double.infinity,
      decoration: BoxDecoration(
        color: isMobile ? Colors.white : AppColors.surfaceContainerLow, // Soft background
        border: Border(
          right: BorderSide(
            color: AppColors.brandSecondary.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo Section (Top-aligned)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.brandSecondary.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.borderMd,
                    child: Image.asset(
                      'assets/icon/kgra.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My KGRA',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.brandSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                ),
                _buildSidebarItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Pending Approvals',
                  badgeCount: pendingCount > 0 ? pendingCount : null,
                ),
                _buildSidebarItem(
                  icon: Icons.check_circle_outline,
                  label: 'Approved Members',
                  badgeCount: adminProvider.approvedUsers.isNotEmpty ? adminProvider.approvedUsers.length : null,
                ),
                _buildSidebarItem(
                  icon: Icons.cancel_outlined,
                  label: 'Rejected Requests',
                  badgeCount: adminProvider.rejectedUsers.isNotEmpty ? adminProvider.rejectedUsers.length : null,
                ),
                _buildSidebarItem(
                  icon: Icons.group_outlined,
                  label: 'Committee Members',
                ),
                _buildSidebarItem(
                  icon: Icons.stars_outlined,
                  label: 'Executive Committee',
                ),
                _buildSidebarItem(
                  icon: Icons.groups_outlined,
                  label: 'Zonal Committee',
                ),
                _buildSidebarItem(
                  icon: Icons.description_outlined,
                  label: 'Meeting Minutes',
                ),
                _buildSidebarItem(
                  icon: Icons.gavel_outlined,
                  label: 'Government Orders',
                ),
                _buildSidebarItem(
                  icon: Icons.folder_zip_outlined,
                  label: 'Forms & Circulars',
                ),
                _buildSidebarItem(
                  icon: Icons.campaign_outlined,
                  label: 'Updates',
                ),
                _buildSidebarItem(
                  icon: Icons.live_tv_outlined,
                  label: 'Live Sessions',
                ),
                _buildSidebarItem(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                ),
                _buildSidebarItem(
                  icon: Icons.video_library_outlined,
                  label: 'Educational Videos',
                ),
                _buildSidebarItem(
                  icon: Icons.event_outlined,
                  label: 'Upcoming Events',
                ),
                _buildSidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                ),
              ],
            ),
          ),

          // Footer Back Button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                side: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.15)),
                foregroundColor: AppColors.brandSecondary,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
              onPressed: () {
                if (isMobile) Navigator.pop(context);
                context.read<AdminProvider>().logoutAdmin();
                context.go(AppRoutes.adminLogin);
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Login'),
            ),
          ),
        ],
      ),
    );

    return isMobile ? Drawer(child: sidebarContent) : sidebarContent;
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = _activeTab == label;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () {
              setState(() {
                _activeTab = label;
                _expandedUserUid = null;
                _searchQuery = '';
                _searchController.clear();
              });
              _onTabChanged(label);
              if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                _scaffoldKey.currentState?.closeDrawer();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              // Generous vertical padding: py-4 (14px-16px vertical padding)
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandPrimary.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? const Color(0xFF8B1E2D) : const Color(0xFF64748B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF8B1E2D) : const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (badgeCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: label == 'Pending Approvals' ? AppColors.error : AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            left: -8, // Center-align pill relative to the left margin
            top: 10,
            bottom: 16,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E2D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    switch (_activeTab) {
      case 'Dashboard':
        return _buildDashboardView(context);
      case 'Pending Approvals':
        return _buildListView(context, 'pending');
      case 'Approved Members':
        return _buildListView(context, 'approved');
      case 'Rejected Requests':
        return _buildListView(context, 'rejected');
      case 'Committee Members':
      case 'State Committee':
        return _buildCommitteeMembersView(context);
      case 'Executive Committee':
        return _buildExecutiveCommitteeView(context);
      case 'Zonal Committee':
        return _buildZonalCommitteeView(context);
      case 'Meeting Minutes':
        return _buildMeetingMinutesView(context);
      case 'Government Orders':
        return _buildGovernmentOrdersView(context);
      case 'Forms & Circulars':
        return _buildFormsCircularsView(context);
      case 'Updates':
        return _buildUpdatesView(context);
      case 'Live Sessions':
        return _buildLiveSessionsView(context);
      case 'Gallery':
        return _buildGalleryView(context);
      case 'Educational Videos':
        return _buildEducationalVideosView(context);
      case 'Upcoming Events':
        return _buildUpcomingEventsView(context);
      case 'Settings':
        return _buildSettingsView(context);
      default:
        return _buildDashboardView(context);
    }
  }

  Widget _buildDashboardView(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final pendingNum = adminProvider.pendingUsers.length;
    final approvedNum = adminProvider.approvedUsers.length;
    final rejectedNum = adminProvider.rejectedUsers.length;
    final totalNum = pendingNum + approvedNum + rejectedNum;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Cards
              Text(
                'Welcome, ',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Overview of registrations, approved members, and general association management systems.',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (adminProvider.error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Database Sync Issue: ${adminProvider.error!}',
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.error),
                        onPressed: _refreshAllData,
                        tooltip: 'Retry Sync',
                      ),
                    ],
                  ),
                ),
              ],

              // Summary Stat Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - (AppSpacing.lg * 3)) / 4;
                  final count = constraints.maxWidth < 600 ? 2 : 4;

                  return Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      _buildStatCard(
                        title: 'Total Requests',
                        value: totalNum.toString(),
                        icon: Icons.assessment_outlined,
                        color: AppColors.brandSecondary,
                        width: count == 2 ? (constraints.maxWidth - AppSpacing.lg) / 2 : cardWidth,
                      ),
                      _buildStatCard(
                        title: 'Pending Approvals',
                        value: pendingNum.toString(),
                        icon: Icons.pending_actions_outlined,
                        color: AppColors.error,
                        width: count == 2 ? (constraints.maxWidth - AppSpacing.lg) / 2 : cardWidth,
                        onTap: () {
                          setState(() {
                            _activeTab = 'Pending Approvals';
                          });
                        },
                      ),
                      _buildStatCard(
                        title: 'Approved Members',
                        value: approvedNum.toString(),
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        width: count == 2 ? (constraints.maxWidth - AppSpacing.lg) / 2 : cardWidth,
                        onTap: () {
                          setState(() {
                            _activeTab = 'Approved Members';
                          });
                        },
                      ),
                      _buildStatCard(
                        title: 'Rejected Requests',
                        value: rejectedNum.toString(),
                        icon: Icons.cancel_outlined,
                        color: Colors.grey,
                        width: count == 2 ? (constraints.maxWidth - AppSpacing.lg) / 2 : cardWidth,
                        onTap: () {
                          setState(() {
                            _activeTab = 'Rejected Requests';
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Recent Activities Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Registrations',
                          style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        adminProvider.pendingUsers.isEmpty
                            ? _buildCardWrapper(
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  alignment: Alignment.center,
                                  child: const Text('No pending registration requests to show.'),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: adminProvider.pendingUsers.length > 3 ? 3 : adminProvider.pendingUsers.length,
                                itemBuilder: (context, index) {
                                  final user = adminProvider.pendingUsers[index];
                                  return _buildDashboardListTile(user);
                                },
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Controls',
                          style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildCardWrapper(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                _buildQuickActionButton(
                                  label: 'Review Pending Requests',
                                  icon: Icons.people_alt_outlined,
                                  color: AppColors.brandPrimary,
                                  onPressed: () => setState(() => _activeTab = 'Pending Approvals'),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _buildQuickActionButton(
                                  label: 'Manage Web Settings',
                                  icon: Icons.settings_outlined,
                                  color: AppColors.brandSecondary,
                                  onPressed: () => setState(() => _activeTab = 'Settings'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
    VoidCallback? onTap,
  }) {
    final cardContent = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyle.headlineLg(color: AppColors.brandSecondary).copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return _buildCardWrapper(
      width: width,
      child: onTap != null
          ? InkWell(
              borderRadius: AppRadius.borderLg,
              onTap: onTap,
              child: cardContent,
            )
          : cardContent,
    );
  }

  Widget _buildDashboardListTile(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.brandSecondary.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.06),
                child: const Icon(Icons.person, color: AppColors.brandPrimary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.brandSecondary),
                  ),
                  Text(
                    user.designation ?? 'Designation Unspecified',
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildListView(BuildContext context, String status) {
    final adminProvider = context.watch<AdminProvider>();
    List<UserModel> usersList;

    if (status == 'pending') {
      usersList = adminProvider.pendingUsers;
    } else if (status == 'approved') {
      usersList = adminProvider.approvedUsers;
    } else {
      usersList = adminProvider.rejectedUsers;
    }

    final filteredUsers = _filterUsers(usersList);

    return Column(
      children: [
        // Search Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.brandSecondary.withValues(alpha: 0.04),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, designation, or institution...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.brandSecondary.withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMd,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandSecondary.withValues(alpha: 0.03),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: adminProvider.selectedZoneFilter,
                        icon: const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.brandPrimary),
                        style: const TextStyle(
                          color: AppColors.brandSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            adminProvider.setSelectedZoneFilter(val);
                          }
                        },
                        items: [
                          'All Zones',
                          ...adminProvider.zones,
                        ].map((zone) {
                          return DropdownMenuItem<String>(
                            value: zone,
                            child: Text(zone == 'All Zones' ? 'All Zones' : 'Zone: $zone'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // List Body
        Expanded(
          child: adminProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.brandPrimary),
                )
              : adminProvider.error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Error Loading List',
                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              adminProvider.error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _refreshAllData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandSecondary.withValues(alpha: 0.04),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  status == 'approved'
                                      ? Icons.check_circle_outline
                                      : status == 'rejected'
                                          ? Icons.cancel_outlined
                                          : Icons.people_alt_outlined,
                                  size: 64,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                _searchQuery.isNotEmpty ? 'No Results Found' : 'No Accounts Found',
                                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching records match the search query.'
                                : 'No records exist in the system for this tab.',
                            style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final isExpanded = _expandedUserUid == user.uid;
                            final base64Image = adminProvider.userImages[user.uid];
                            final isImgLoading = adminProvider.isImageLoading(user.uid);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: AppRadius.borderLg,
                                border: Border.all(
                                  color: isExpanded
                                      ? AppColors.brandPrimary.withValues(alpha: 0.3)
                                      : AppColors.brandSecondary.withValues(alpha: 0.06),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brandSecondary.withValues(alpha: 0.03),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () => _toggleExpand(user, adminProvider),
                                borderRadius: AppRadius.borderLg,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.06),
                                            child: const Icon(Icons.person, color: AppColors.brandPrimary, size: 22),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.name,
                                                  style: AppTextStyle.bodyLg(color: AppColors.brandSecondary).copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  user.phoneNumber,
                                                  style: AppTextStyle.labelSm(color: AppColors.onSurfaceVariant),
                                                ),
                                              ],
                                            ),
                                          ),
                                          _buildBadge(status),
                                          const SizedBox(width: AppSpacing.sm),
                                          Icon(
                                            isExpanded ? Icons.expand_less : Icons.expand_more,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _InfoTile(
                                              icon: Icons.badge_outlined,
                                              label: 'Designation',
                                              value: user.designation ?? 'Not Provided',
                                            ),
                                          ),
                                          Expanded(
                                            child: _InfoTile(
                                              icon: Icons.business_outlined,
                                              label: 'Institution',
                                              value: user.institution ?? 'Not Provided',
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isExpanded) ...[
                                        const Divider(height: AppSpacing.md),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _InfoTile(
                                                icon: Icons.map_outlined,
                                                label: 'Zone',
                                                value: user.zone ?? 'Not Provided',
                                              ),
                                            ),
                                            Expanded(
                                              child: _InfoTile(
                                                icon: Icons.cake_outlined,
                                                label: 'Date of Birth',
                                                value: user.dateOfBirth ?? 'Not Provided',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _InfoTile(
                                                icon: Icons.event_outlined,
                                                label: 'Date of Join',
                                                value: user.dateOfJoin ?? 'Not Provided',
                                              ),
                                            ),
                                            Expanded(
                                              child: _InfoTile(
                                                icon: Icons.card_membership_outlined,
                                                label: 'Membership ID',
                                                value: user.membershipId ?? 'Not Provided',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _InfoTile(
                                                icon: Icons.work_off_outlined,
                                                label: 'Date of Retirement',
                                                value: user.dateOfRetirement ?? 'Not Provided',
                                              ),
                                            ),
                                            const Expanded(child: SizedBox()),
                                          ],
                                        ),
                                        if (user.reviewedByName != null || user.reviewedById != null || user.reviewedAt != null) ...[
                                          const SizedBox(height: AppSpacing.md),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoTile(
                                                  icon: Icons.verified_user_outlined,
                                                  label: user.status == 'approved'
                                                      ? 'Approved By'
                                                      : (user.status == 'rejected' ? 'Rejected By' : 'Reviewed By'),
                                                  value: '${user.reviewedByName ?? "Admin"}${user.reviewedById != null ? " (ID: ${user.reviewedById})" : ""}',
                                                ),
                                              ),
                                              Expanded(
                                                child: _InfoTile(
                                                  icon: Icons.access_time_outlined,
                                                  label: 'Reviewed At',
                                                  value: user.reviewedAt ?? 'Not Provided',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const Divider(height: AppSpacing.xl),
                                        Center(
                                          child: Column(
                                            children: [
                                              const Text(
                                                'Submitted Profile Photo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.onSurfaceVariant,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: AppSpacing.md),
                                              Container(
                                                width: 140,
                                                height: 140,
                                                decoration: BoxDecoration(
                                                  color: AppColors.brandSecondary.withValues(alpha: 0.04),
                                                  borderRadius: AppRadius.borderLg,
                                                  border: Border.all(
                                                    color: AppColors.brandSecondary.withValues(alpha: 0.1),
                                                  ),
                                                ),
                                                child: isImgLoading
                                                    ? const Center(
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : (user.profileImageId != null && user.profileImageId!.startsWith('http'))
                                                        ? ClipRRect(
                                                            borderRadius: AppRadius.borderLg,
                                                            child: Image.network(
                                                              user.profileImageId!,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) => const Center(
                                                                child: Icon(Icons.broken_image, size: 32),
                                                              ),
                                                            ),
                                                          )
                                                        : base64Image != null
                                                            ? ClipRRect(
                                                                borderRadius: AppRadius.borderLg,
                                                                child: Image.memory(
                                                                  base64Decode(base64Image),
                                                                  fit: BoxFit.cover,
                                                                ),
                                                              )
                                                            : const Center(
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(
                                                                  Icons.no_photography_outlined,
                                                                  color: AppColors.onSurfaceVariant,
                                                                  size: 32,
                                                                ),
                                                                SizedBox(height: AppSpacing.xs),
                                                                Text(
                                                                  'No Photo Uploaded',
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    color: AppColors.onSurfaceVariant,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (status == 'pending') ...[
                                          const SizedBox(height: AppSpacing.xl),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.error,
                                                    side: const BorderSide(color: AppColors.error),
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                  onPressed: () => _handleReject(context, user.uid, adminProvider),
                                                  icon: const Icon(Icons.close, size: 18),
                                                  label: const Text('Reject'),
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.md),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                  onPressed: () => _handleApprove(context, user.uid, adminProvider),
                                                  icon: const Icon(Icons.check, size: 18),
                                                  label: const Text('Approve'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBadge(String status) {
    Color color;
    String text;

    if (status == 'approved') {
      color = Colors.green;
      text = 'Approved';
    } else if (status == 'rejected') {
      color = AppColors.error;
      text = 'Rejected';
    } else {
      color = Colors.orange;
      text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portal Configuration',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Configure administration policies, validation rules, and offline systems.',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xl),

              _buildCardWrapper(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text(
                          'Auto-Approve Registrations',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandSecondary),
                        ),
                        subtitle: const Text('Bypasses human verification (Not Recommended for Production)'),
                        value: _autoApprove,
                        activeColor: AppColors.brandPrimary,
                        onChanged: (val) => setState(() => _autoApprove = val),
                      ),
                      const Divider(height: 32),
                      ListTile(
                        title: const Text(
                          'Security Clearance Level',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandSecondary),
                        ),
                        subtitle: const Text('Minimum clearance level to modify user verification statuses'),
                        trailing: DropdownButton<String>(
                          value: _clearanceLevel,
                          underline: const SizedBox(),
                          items: <String>['General', 'Supervisor', 'State Committee', 'Superadmin']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _clearanceLevel = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, {required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              onConfirm();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Committee Members Administration
  // ==========================================

  Widget _buildCommitteeMembersView(BuildContext context) {
    final provider = context.watch<StateCommitteeProvider>();
    final members = provider.members;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members Management',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showCommitteeMemberDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Member'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : members.isEmpty
                      ? const Center(child: Text('No committee members found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final m = members[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.06),
                                        backgroundImage: m.photoBase64 != null
                                            ? MemoryImage(base64Decode(m.photoBase64!))
                                            : null,
                                        child: m.photoBase64 == null
                                            ? const Icon(Icons.person, color: AppColors.brandPrimary, size: 28)
                                            : null,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.name,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              m.designation,
                                              style: const TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(m.phoneNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                const SizedBox(width: AppSpacing.md),
                                                const Icon(Icons.email, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(m.email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showCommitteeMemberDialog(context, member: m),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Member',
                                          content: 'Are you sure you want to delete ${m.name}?',
                                          onConfirm: () => provider.deleteMember(m.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showCommitteeMemberDialog(BuildContext context, {CommitteeMemberModel? member}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final phoneCtrl = TextEditingController(text: member?.phoneNumber ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    String? photoBase64 = member?.photoBase64;
    final designations = context.read<AdminProvider>().designations;
    String? selectedDesignation = member?.designation;
    if (selectedDesignation == null && designations.isNotEmpty) {
      selectedDesignation = designations.first;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(member == null ? 'Add Committee Member' : 'Update Committee Member'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 300, maxHeight: 300);
                          if (img != null) {
                            final bytes = await img.readAsBytes();
                            setDialogState(() {
                              photoBase64 = base64Encode(bytes);
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64!)) : null,
                          child: photoBase64 == null
                              ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedDesignation,
                        decoration: const InputDecoration(labelText: 'Designation *'),
                        items: designations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) => setDialogState(() => selectedDesignation = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone Number *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newMember = CommitteeMemberModel(
                        id: member?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        designation: selectedDesignation ?? '',
                        phoneNumber: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        photoBase64: photoBase64,
                        createdAt: member?.createdAt ?? DateTime.now().toIso8601String(),
                      );
                      bool success;
                      if (member == null) {
                        success = await context.read<StateCommitteeProvider>().addMember(newMember);
                        if (success && dialogCtx.mounted) {
                          await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                            title: 'New State Committee Member',
                            body: '${newMember.name} has been added to the State Committee.',
                            routingPath: AppRoutes.stateCommittee,
                          );
                        }
                      } else {
                        success = await context.read<StateCommitteeProvider>().updateMember(newMember);
                      }
                      if (success && dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // Meeting Minutes Administration
  // ==========================================

  Widget _buildMeetingMinutesView(BuildContext context) {
    final provider = context.watch<MeetingMinutesProvider>();
    final minutes = provider.minutesList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meeting Minutes',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showMeetingMinutesDialog(context),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload PDF'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : minutes.isEmpty
                      ? const Center(child: Text('No meeting minutes uploaded.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: minutes.length,
                          itemBuilder: (context, index) {
                            final m = minutes[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: AppRadius.borderMd,
                                        ),
                                        child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.title,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                             Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Date: ${m.date} | File: ${m.pdfName}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    m.section == 'zonal' && m.zone.isNotEmpty
                                                        ? 'ZONAL (${m.zone.toUpperCase()})'
                                                        : m.section.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.brandPrimary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: m.status == 'approved'
                                                        ? Colors.green.withValues(alpha: 0.1)
                                                        : m.status == 'rejected'
                                                            ? AppColors.error.withValues(alpha: 0.1)
                                                            : Colors.orange.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    m.status.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: m.status == 'approved'
                                                          ? Colors.green
                                                          : m.status == 'rejected'
                                                              ? AppColors.error
                                                              : Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Colors.green),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AppPdfViewerScreen(
                                                title: m.title,
                                                pdfUrl: m.pdfUrl,
                                                folderName: 'meeting_minutes',
                                                docId: m.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showMeetingMinutesDialog(context, minutes: m),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Minutes',
                                          content: 'Are you sure you want to delete ${m.title}?',
                                          onConfirm: () => provider.deleteMinutes(m),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showMeetingMinutesDialog(BuildContext context, {MeetingMinutesModel? minutes}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: minutes?.title ?? '');
    final dateCtrl = TextEditingController(text: minutes?.date ?? '');
    String pdfName = minutes?.pdfName ?? '';
    Uint8List? pdfBytes;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isSaving = false;
        String selectedSection = minutes?.section ?? 'all';
        String selectedZone = minutes?.zone ?? '';
        final zonesList = context.read<AdminProvider>().zones;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(minutes == null ? 'Upload Meeting Minutes' : 'Update Meeting Minutes'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: const InputDecoration(labelText: 'Section *'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'state', child: Text('State')),
                        DropdownMenuItem(value: 'executive', child: Text('Executive')),
                        DropdownMenuItem(value: 'zonal', child: Text('Zonal')),
                      ],
                      onChanged: isSaving ? null : (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedSection = val;
                          });
                        }
                      },
                    ),
                    if (selectedSection == 'zonal') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedZone.isNotEmpty && zonesList.contains(selectedZone)
                            ? selectedZone
                            : (zonesList.isNotEmpty ? zonesList.first : null),
                        decoration: const InputDecoration(labelText: 'Select Zone *'),
                        items: zonesList.isEmpty
                            ? []
                            : zonesList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                        validator: (v) => selectedSection == 'zonal' && (v == null || v.isEmpty) ? 'Required' : null,
                        onChanged: isSaving ? null : (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedZone = val;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Meeting Date *', suffixIcon: Icon(Icons.calendar_today)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving ? null : () async {
                              final pickedFile = await pickPdfFile();
                              if (pickedFile != null) {
                                setDialogState(() {
                                  pdfBytes = pickedFile.bytes;
                                  pdfName = pickedFile.name;
                                });
                              }
                            },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Pick PDF *'),
                          ),
                        ),
                      ],
                    ),
                    if (pdfName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Selected: $pdfName', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      if (minutes == null && pdfBytes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a PDF file.')),
                        );
                        return;
                      }
                      
                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        final newMinutes = MeetingMinutesModel(
                          id: minutes?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text.trim(),
                          date: dateCtrl.text.trim(),
                          pdfName: pdfName,
                          pdfUrl: minutes?.pdfUrl ?? '',
                          status: minutes?.status ?? 'pending',
                          createdAt: minutes?.createdAt ?? DateTime.now().toIso8601String(),
                          section: selectedSection,
                          zone: selectedSection == 'zonal'
                              ? (selectedZone.isNotEmpty && zonesList.contains(selectedZone)
                                  ? selectedZone
                                  : (zonesList.isNotEmpty ? zonesList.first : ''))
                              : '',
                        );
                        bool success;
                        if (minutes == null) {
                          success = await context.read<MeetingMinutesProvider>().addMinutes(newMinutes, pdfBytes!);
                        } else {
                          success = await context.read<MeetingMinutesProvider>().updateMinutes(newMinutes, pdfBytes);
                        }
                        if (success && dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving: $e')),
                          );
                        }
                      } finally {
                        if (dialogCtx.mounted) {
                          setDialogState(() {
                            isSaving = false;
                          });
                        }
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // Government Orders Administration
  // ==========================================

  Widget _buildGovernmentOrdersView(BuildContext context) {
    final provider = context.watch<GovernmentOrdersProvider>();
    final orders = provider.orders;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Government Orders (GO)',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showGovernmentOrderDialog(context),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Add GO pdf'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : orders.isEmpty
                      ? const Center(child: Text('No government orders found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final o = orders[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: AppRadius.borderMd,
                                        ),
                                        child: const Icon(Icons.gavel, color: Colors.orange, size: 24),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              o.title,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Order No: ${o.orderNumber} | Date: ${o.date}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    o.section == 'zonal' && o.zone.isNotEmpty
                                                        ? 'ZONAL (${o.zone.toUpperCase()})'
                                                        : o.section.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.brandPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Colors.green),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AppPdfViewerScreen(
                                                title: o.title,
                                                pdfUrl: o.pdfUrl,
                                                folderName: 'government_orders',
                                                docId: o.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showGovernmentOrderDialog(context, order: o),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Order',
                                          content: 'Are you sure you want to delete ${o.title}?',
                                          onConfirm: () => provider.deleteOrder(o),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showGovernmentOrderDialog(BuildContext context, {GovernmentOrderModel? order}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: order?.title ?? '');
    final numCtrl = TextEditingController(text: order?.orderNumber ?? '');
    final dateCtrl = TextEditingController(text: order?.date ?? '');
    String pdfName = order?.pdfName ?? '';
    Uint8List? pdfBytes;
    bool isSaving = false;
    String selectedSection = order?.section ?? 'all';
    String selectedZone = order?.zone ?? '';
    final zonesList = context.read<AdminProvider>().zones;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(order == null ? 'Add Government Order' : 'Update Government Order'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: const InputDecoration(labelText: 'Section *'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'state', child: Text('State')),
                        DropdownMenuItem(value: 'executive', child: Text('Executive')),
                        DropdownMenuItem(value: 'zonal', child: Text('Zonal')),
                      ],
                      onChanged: isSaving ? null : (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedSection = val;
                          });
                        }
                      },
                    ),
                    if (selectedSection == 'zonal') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedZone.isNotEmpty && zonesList.contains(selectedZone)
                            ? selectedZone
                            : (zonesList.isNotEmpty ? zonesList.first : null),
                        decoration: const InputDecoration(labelText: 'Select Zone *'),
                        items: zonesList.isEmpty
                            ? []
                            : zonesList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                        validator: (v) => selectedSection == 'zonal' && (v == null || v.isEmpty) ? 'Required' : null,
                        onChanged: isSaving ? null : (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedZone = val;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: numCtrl,
                      decoration: const InputDecoration(labelText: 'Order Number *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Order Date *', suffixIcon: Icon(Icons.calendar_today)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onTap: isSaving ? null : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving ? null : () async {
                              final pickedFile = await pickPdfFile();
                              if (pickedFile != null) {
                                setDialogState(() {
                                  pdfBytes = pickedFile.bytes;
                                  pdfName = pickedFile.name;
                                });
                              }
                            },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Pick PDF *'),
                          ),
                        ),
                      ],
                    ),
                    if (pdfName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Selected: $pdfName', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      if (order == null && pdfBytes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a PDF file.')),
                        );
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        final newOrder = GovernmentOrderModel(
                          id: order?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text.trim(),
                          orderNumber: numCtrl.text.trim(),
                          date: dateCtrl.text.trim(),
                          pdfName: pdfName,
                          pdfUrl: order?.pdfUrl ?? '',
                          createdAt: order?.createdAt ?? DateTime.now().toIso8601String(),
                          section: selectedSection,
                          zone: selectedSection == 'zonal'
                              ? (selectedZone.isNotEmpty && zonesList.contains(selectedZone)
                                  ? selectedZone
                                  : (zonesList.isNotEmpty ? zonesList.first : ''))
                              : '',
                        );
                        bool success;
                        if (order == null) {
                          success = await context.read<GovernmentOrdersProvider>().addOrder(newOrder, pdfBytes!);
                          if (success && dialogCtx.mounted) {
                            await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                              title: 'New Government Order',
                              body: newOrder.title,
                              routingPath: AppRoutes.governmentOrders,
                            );
                          }
                        } else {
                          success = await context.read<GovernmentOrdersProvider>().updateOrder(newOrder, pdfBytes);
                        }
                        if (success && dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving: $e')),
                          );
                        }
                      } finally {
                        if (dialogCtx.mounted) {
                          setDialogState(() {
                            isSaving = false;
                          });
                        }
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // Forms & Circulars Administration
  // ==========================================

  Widget _buildFormsCircularsView(BuildContext context) {
    final provider = context.watch<FormsCircularsProvider>();
    final forms = provider.forms;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Forms & Circulars',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showFormCircularDialog(context),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Add Form pdf'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : forms.isEmpty
                      ? const Center(child: Text('No forms or circulars found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: forms.length,
                          itemBuilder: (context, index) {
                            final f = forms[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: AppRadius.borderMd,
                                        ),
                                        child: const Icon(Icons.file_copy, color: Colors.blue, size: 24),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f.title,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Circular No: ${f.circularNumber ?? "N/A"} | Date: ${f.date}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Colors.green),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AppPdfViewerScreen(
                                                title: f.title,
                                                pdfUrl: f.pdfUrl,
                                                folderName: 'forms_circulars',
                                                docId: f.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showFormCircularDialog(context, formCircular: f),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Form',
                                          content: 'Are you sure you want to delete ${f.title}?',
                                          onConfirm: () => provider.deleteForm(f),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showFormCircularDialog(BuildContext context, {FormCircularModel? formCircular}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: formCircular?.title ?? '');
    final numCtrl = TextEditingController(text: formCircular?.circularNumber ?? '');
    final dateCtrl = TextEditingController(text: formCircular?.date ?? '');
    final urlCtrl = TextEditingController(text: formCircular?.externalUrl ?? '');
    String pdfName = formCircular?.pdfName ?? '';
    Uint8List? pdfBytes;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(formCircular == null ? 'Add Form/Circular' : 'Update Form/Circular'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: numCtrl,
                      decoration: const InputDecoration(labelText: 'Circular Number (Optional)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: urlCtrl,
                      decoration: const InputDecoration(labelText: 'External URL (Optional)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Publish Date *', suffixIcon: Icon(Icons.calendar_today)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving ? null : () async {
                              final pickedFile = await pickPdfFile();
                              if (pickedFile != null) {
                                setDialogState(() {
                                  pdfBytes = pickedFile.bytes;
                                  pdfName = pickedFile.name;
                                });
                              }
                            },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Pick PDF *'),
                          ),
                        ),
                      ],
                    ),
                    if (pdfName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Selected: $pdfName', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      if (formCircular == null && pdfBytes == null && urlCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a PDF file or enter an external URL.')),
                        );
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        final newForm = FormCircularModel(
                          id: formCircular?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text.trim(),
                          circularNumber: numCtrl.text.trim().isEmpty ? null : numCtrl.text.trim(),
                          date: dateCtrl.text.trim(),
                          pdfName: pdfName,
                          pdfUrl: formCircular?.pdfUrl ?? '',
                          externalUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                          createdAt: formCircular?.createdAt ?? DateTime.now().toIso8601String(),
                        );
                        bool success;
                        if (formCircular == null) {
                          success = await context.read<FormsCircularsProvider>().addForm(newForm, pdfBytes);
                          if (success && dialogCtx.mounted) {
                            await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                              title: 'New Form or Circular',
                              body: newForm.title,
                              routingPath: AppRoutes.formsCirculars,
                            );
                          }
                        } else {
                          success = await context.read<FormsCircularsProvider>().updateForm(newForm, pdfBytes);
                        }
                        if (success && dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving: $e')),
                          );
                        }
                      } finally {
                        if (dialogCtx.mounted) {
                          setDialogState(() {
                            isSaving = false;
                          });
                        }
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCardWrapper({required Widget child, double? width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: AppColors.brandSecondary.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandSecondary.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildExecutiveCommitteeView(BuildContext context) {
    final provider = context.watch<ZonalProvider>();
    final members = provider.members.where((m) => m.zone.toLowerCase().contains('executive')).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Executive Committee Management',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showZonalMemberDialog(context, defaultZone: 'Executive Committee'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Executive Member'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : members.isEmpty
                      ? const Center(child: Text('No executive committee members found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final m = members[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.06),
                                        backgroundImage: m.photoBase64 != null
                                            ? MemoryImage(base64Decode(m.photoBase64!))
                                            : null,
                                        child: m.photoBase64 == null
                                            ? const Icon(Icons.person, color: AppColors.brandPrimary, size: 28)
                                            : null,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.name,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${m.designation} | Executive Committee',
                                              style: const TextStyle(
                                                color: AppColors.brandPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(m.phoneNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                const SizedBox(width: AppSpacing.md),
                                                const Icon(Icons.email, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(m.email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showZonalMemberDialog(context, member: m, defaultZone: 'Executive Committee'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Member',
                                          content: 'Are you sure you want to delete ${m.name}?',
                                          onConfirm: () => provider.deleteMember(m.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildZonalCommitteeView(BuildContext context) {
    final provider = context.watch<ZonalProvider>();
    final members = provider.members.where((m) => !m.zone.toLowerCase().contains('executive')).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Zonal Committee Management',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showZonalMemberDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Zonal Member'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : members.isEmpty
                      ? const Center(child: Text('No zonal committee members found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final m = members[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.06),
                                        backgroundImage: m.photoBase64 != null
                                            ? MemoryImage(base64Decode(m.photoBase64!))
                                            : null,
                                        child: m.photoBase64 == null
                                            ? const Icon(Icons.person, color: AppColors.brandPrimary, size: 28)
                                            : null,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.name,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${m.designation} | Zone: ${m.zone}',
                                              style: const TextStyle(
                                                color: AppColors.brandPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(m.phoneNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                const SizedBox(width: AppSpacing.md),
                                                const Icon(Icons.email, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(m.email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showZonalMemberDialog(context, member: m),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Member',
                                          content: 'Are you sure you want to delete ${m.name}?',
                                          onConfirm: () => provider.deleteMember(m.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showZonalMemberDialog(BuildContext context, {ZonalMemberModel? member, String? defaultZone}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final phoneCtrl = TextEditingController(text: member?.phoneNumber ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    final isExecutive = (member?.zone ?? defaultZone ?? '').toLowerCase().contains('executive') || defaultZone == 'Executive Committee';
    String? selectedZone = isExecutive ? 'Executive Committee' : (member?.zone ?? defaultZone);
    String? photoBase64 = member?.photoBase64;
    final designations = context.read<AdminProvider>().designations;
    String? selectedDesignation = member?.designation;
    if (selectedDesignation == null && designations.isNotEmpty) {
      selectedDesignation = designations.first;
    }

    final rawZones = context.read<AdminProvider>().zones;
    final availableZonalZones = rawZones.where((z) => !z.toLowerCase().contains('executive')).toList();
    if (!isExecutive && (selectedZone == null || selectedZone.toLowerCase().contains('executive')) && availableZonalZones.isNotEmpty) {
      selectedZone = availableZonalZones.first;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(member == null 
                  ? (isExecutive ? 'Add Executive Member' : 'Add Zonal Member') 
                  : (isExecutive ? 'Update Executive Member' : 'Update Zonal Member')),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 300, maxHeight: 300);
                          if (img != null) {
                            final bytes = await img.readAsBytes();
                            setDialogState(() {
                              photoBase64 = base64Encode(bytes);
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64!)) : null,
                          child: photoBase64 == null
                              ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedDesignation,
                        decoration: const InputDecoration(labelText: 'Designation *'),
                        items: designations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) => setDialogState(() => selectedDesignation = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      if (isExecutive) ...[
                        TextFormField(
                          initialValue: 'Executive Committee',
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Committee Section'),
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          value: selectedZone,
                          decoration: const InputDecoration(labelText: 'Zone *'),
                          items: availableZonalZones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                          onChanged: (val) => setDialogState(() => selectedZone = val),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone Number *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final finalZone = isExecutive ? 'Executive Committee' : selectedZone!;
                      final newMember = ZonalMemberModel(
                        id: member?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        designation: selectedDesignation ?? '',
                        phoneNumber: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        zone: finalZone,
                        photoBase64: photoBase64,
                        createdAt: member?.createdAt ?? DateTime.now().toIso8601String(),
                      );
                      bool success;
                      if (member == null) {
                        success = await context.read<ZonalProvider>().addMember(newMember);
                        if (success && dialogCtx.mounted) {
                          final isExec = newMember.zone.toLowerCase().contains('executive');
                          await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                            title: isExec ? 'New Executive Committee Member' : 'New Zonal Committee Member',
                            body: isExec 
                                ? '${newMember.name} has been added to the Executive Committee.' 
                                : '${newMember.name} has been added to the Zonal Committee of ${newMember.zone}.',
                            routingPath: isExec ? AppRoutes.executiveCommittee : AppRoutes.zonalCommittee,
                          );
                        }
                      } else {
                        success = await context.read<ZonalProvider>().updateMember(newMember);
                      }
                      if (success && dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUpdatesView(BuildContext context) {
    final provider = context.watch<UpdatesProvider>();
    final updates = provider.updatesList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Updates Management',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showUpdateDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Update'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : updates.isEmpty
                      ? const Center(child: Text('No updates posted.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: updates.length,
                          itemBuilder: (context, index) {
                            final u = updates[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandPrimary.withValues(alpha: 0.05),
                                          borderRadius: AppRadius.borderMd,
                                        ),
                                        child: const Icon(Icons.campaign, color: AppColors.brandPrimary, size: 24),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              u.title,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Date: ${u.date} | Content: ${u.content.length > 60 ? "${u.content.substring(0, 60)}..." : u.content}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showUpdateDialog(context, update: u),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Update',
                                          content: 'Are you sure you want to delete ${u.title}?',
                                          onConfirm: () => provider.deleteUpdate(u.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showUpdateDialog(BuildContext context, {UpdateModel? update}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: update?.title ?? '');
    final contentCtrl = TextEditingController(text: update?.content ?? '');
    final dateCtrl = TextEditingController(text: update?.date ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(update == null ? 'Post New Update' : 'Edit Update'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Date *', suffixIcon: Icon(Icons.calendar_today)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contentCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Content *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newUpdate = UpdateModel(
                        id: update?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                        date: dateCtrl.text.trim(),
                        createdAt: update?.createdAt ?? DateTime.now().toIso8601String(),
                      );
                      bool success;
                      if (update == null) {
                        success = await context.read<UpdatesProvider>().addUpdate(newUpdate);
                        if (success && dialogCtx.mounted) {
                          await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                            title: 'New Update Available',
                            body: newUpdate.title,
                            routingPath: AppRoutes.updates,
                          );
                        }
                      } else {
                        success = await context.read<UpdatesProvider>().updateUpdate(newUpdate);
                      }
                      if (success && dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLiveSessionsView(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();
    final sessions = provider.sessionsList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Sessions Management',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showLiveSessionDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Live Session'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : sessions.isEmpty
                      ? const Center(child: Text('No live sessions scheduled.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final s = sessions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: AppRadius.borderMd,
                                        ),
                                        child: const Icon(Icons.live_tv, color: Colors.red, size: 24),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.title,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Date: ${s.date} | Link: ${s.url}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showLiveSessionDialog(context, session: s),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Session',
                                          content: 'Are you sure you want to delete ${s.title}?',
                                          onConfirm: () => provider.deleteLiveSession(s.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showLiveSessionDialog(BuildContext context, {LiveSessionModel? session}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: session?.title ?? '');
    final descCtrl = TextEditingController(text: session?.description ?? '');
    final urlCtrl = TextEditingController(text: session?.url ?? '');
    final dateCtrl = TextEditingController(text: session?.date ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(session == null ? 'Schedule Live Session' : 'Edit Live Session'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Scheduled Date *', suffixIcon: Icon(Icons.calendar_today)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(labelText: 'Live Session URL *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description (Optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newSession = LiveSessionModel(
                        id: session?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        url: urlCtrl.text.trim(),
                        date: dateCtrl.text.trim(),
                        createdAt: session?.createdAt ?? DateTime.now().toIso8601String(),
                      );
                      bool success;
                      if (session == null) {
                        success = await context.read<LiveSessionProvider>().addLiveSession(newSession);
                        if (success && dialogCtx.mounted) {
                          await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                            title: 'Live Session Scheduled',
                            body: newSession.title,
                            routingPath: AppRoutes.liveSessions,
                          );
                        }
                      } else {
                        success = await context.read<LiveSessionProvider>().updateLiveSession(newSession);
                      }
                      if (success && dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGalleryView(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    final images = provider.imagesList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photo Gallery Management',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showGalleryDialog(context),
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Add Image'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : images.isEmpty
                      ? const Center(child: Text('No gallery images found.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final img = images[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppRadius.borderLg,
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadius.borderLg,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            img.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit, size: 12, color: Colors.blue),
                                                    onPressed: () => _showGalleryDialog(context, image: img),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete, size: 12, color: AppColors.error),
                                                    onPressed: () => _confirmDelete(
                                                      context,
                                                      title: 'Delete Photo',
                                                      content: 'Are you sure you want to delete this photo?',
                                                      onConfirm: () => provider.deleteImage(img),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      child: Text(
                                        img.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showGalleryDialog(BuildContext context, {GalleryImageModel? image}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: image?.title ?? '');
    Uint8List? imageBytes;
    String? originalFileName;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(image == null ? 'Upload Photo' : 'Update Photo'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: isSaving ? null : () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                            maxWidth: 1024,
                            maxHeight: 1024,
                          );
                          if (img != null) {
                            final bytes = await img.readAsBytes();
                            setDialogState(() {
                              imageBytes = bytes;
                              originalFileName = img.name;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          ),
                          child: imageBytes != null
                              ? ClipRRect(
                                  borderRadius: AppRadius.borderMd,
                                  child: Image.memory(imageBytes!, fit: BoxFit.cover),
                                )
                              : (image != null
                                  ? ClipRRect(
                                      borderRadius: AppRadius.borderMd,
                                      child: Image.network(
                                        image.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Select Image *', style: TextStyle(color: Colors.grey)),
                                      ],
                                    )),
                        ),
                      ),
                      if (originalFileName != null) ...[
                        const SizedBox(height: 8),
                        Text('Selected: $originalFileName', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Image Title *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            if (image == null && imageBytes == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select an image.')),
                              );
                              return;
                            }
                            setDialogState(() {
                              isSaving = true;
                            });
                            
                            final newImage = GalleryImageModel(
                              id: image?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              title: titleCtrl.text.trim(),
                              imageUrl: image?.imageUrl ?? '',
                              createdAt: image?.createdAt ?? DateTime.now().toIso8601String(),
                            );
                            
                            final galleryProvider = context.read<GalleryProvider>();
                            bool success;
                            if (image == null) {
                              success = await galleryProvider.addImage(newImage, imageBytes!);
                              if (success && dialogCtx.mounted) {
                                final notificationProvider = dialogCtx.read<NotificationProvider>();
                                await notificationProvider.sendSystemNotification(
                                  title: 'New Gallery Photo',
                                  body: newImage.title,
                                  routingPath: AppRoutes.gallery,
                                  // Removed unnecessary system notifications code here
                                );
                              }
                            } else {
                              success = await galleryProvider.updateImage(newImage, imageBytes);
                            }
                            
                            if (success && dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            } else {
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(content: Text(galleryProvider.error ?? 'Failed to save photo.')),
                                );
                              }
                              setDialogState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEducationalVideosView(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final videos = provider.videosList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Educational Videos Management',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showVideoDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Video'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : videos.isEmpty
                      ? const Center(child: Text('No educational videos scheduled.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            final v = videos[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: AppRadius.borderMd,
                                        ),
                                        child: v.thumbnailUrl.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: AppRadius.borderMd,
                                                child: Image.network(
                                                  v.thumbnailUrl,
                                                  width: 80,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Center(child: Icon(Icons.video_library, color: Colors.blue, size: 24)),
                                                ),
                                              )
                                            : const Center(child: Icon(Icons.video_library, color: Colors.blue, size: 24)),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              v.title,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    v.duration > 0
                                                        ? 'Duration: ${(v.duration ~/ 60)}m ${(v.duration % 60)}s | URL: ${v.videoUrl}'
                                                        : 'URL: ${v.videoUrl}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    v.section == 'zonal' && v.zone.isNotEmpty
                                                        ? 'ZONAL (${v.zone.toUpperCase()})'
                                                        : v.section.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.brandPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showVideoDialog(context, video: v),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Video',
                                          content: 'Are you sure you want to delete ${v.title}?',
                                          onConfirm: () => provider.deleteVideo(v.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showVideoDialog(BuildContext context, {VideoModel? video}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: video?.title ?? '');
    final descCtrl = TextEditingController(text: video?.description ?? '');

    Uint8List? videoBytes;
    String videoName = video?.videoUrl.isNotEmpty == true ? video!.videoUrl.split('/').last.split('?').first : '';

    Uint8List? thumbnailBytes;
    String thumbnailName = video?.thumbnailUrl.isNotEmpty == true ? video!.thumbnailUrl.split('/').last.split('?').first : '';

    bool isSaving = false;
    double videoProgress = 0.0;
    double thumbnailProgress = 0.0;
    String selectedSection = video?.section ?? 'all';
    String selectedZone = video?.zone ?? '';
    final zonesList = context.read<AdminProvider>().zones;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(video == null ? 'Upload Educational Video' : 'Edit Educational Video'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSection,
                        decoration: const InputDecoration(labelText: 'Section *'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'state', child: Text('State')),
                          DropdownMenuItem(value: 'executive', child: Text('Executive')),
                          DropdownMenuItem(value: 'zonal', child: Text('Zonal')),
                        ],
                        onChanged: isSaving ? null : (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedSection = val;
                            });
                          }
                        },
                      ),
                      if (selectedSection == 'zonal') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedZone.isNotEmpty && zonesList.contains(selectedZone)
                              ? selectedZone
                              : (zonesList.isNotEmpty ? zonesList.first : null),
                          decoration: const InputDecoration(labelText: 'Select Zone *'),
                          items: zonesList.isEmpty
                              ? []
                              : zonesList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                          validator: (v) => selectedSection == 'zonal' && (v == null || v.isEmpty) ? 'Required' : null,
                          onChanged: isSaving ? null : (val) {
                            if (val != null) {
                              setDialogState(() {
                                              selectedZone = val;
                              });
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Video Selector Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final pickedFile = await pickVideoFile();
                                      if (pickedFile != null) {
                                        setDialogState(() {
                                          videoBytes = pickedFile.bytes;
                                          videoName = pickedFile.name;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.video_call),
                              label: Text(videoBytes == null && video == null ? 'Pick Video *' : 'Change Video'),
                            ),
                          ),
                        ],
                      ),
                      if (videoName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Video: $videoName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Thumbnail Selector Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final pickedFile = await pickImageFile();
                                      if (pickedFile != null) {
                                        setDialogState(() {
                                          thumbnailBytes = pickedFile.bytes;
                                          thumbnailName = pickedFile.name;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.image),
                              label: Text(thumbnailBytes == null && (video == null || video.thumbnailUrl.isEmpty) ? 'Pick Thumbnail' : 'Change Thumbnail'),
                            ),
                          ),
                        ],
                      ),
                      if (thumbnailName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Thumbnail: $thumbnailName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description (Optional)'),
                      ),
                      if (isSaving) ...[
                        const SizedBox(height: 20),
                        if (videoBytes != null) ...[
                          Text('Uploading Video: ${(videoProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(value: videoProgress, color: AppColors.brandPrimary),
                          const SizedBox(height: 12),
                        ],
                        if (thumbnailBytes != null) ...[
                          Text('Uploading Thumbnail: ${(thumbnailProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(value: thumbnailProgress, color: Colors.amber),
                          const SizedBox(height: 12),
                        ],
                        const Center(child: Text('Saving Educational Video...', style: TextStyle(fontSize: 12))),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            if (video == null && videoBytes == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a video file.')),
                              );
                              return;
                            }
                            
                            setDialogState(() {
                              isSaving = true;
                              videoProgress = 0.0;
                              thumbnailProgress = 0.0;
                            });

                            try {
                              final newVideo = VideoModel(
                                id: video?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                videoUrl: video?.videoUrl ?? '',
                                thumbnailUrl: video?.thumbnailUrl ?? '',
                                duration: video?.duration ?? 0,
                                createdAt: video?.createdAt ?? DateTime.now().toIso8601String(),
                                section: selectedSection,
                                zone: selectedSection == 'zonal'
                                    ? (selectedZone.isNotEmpty && zonesList.contains(selectedZone)
                                        ? selectedZone
                                        : (zonesList.isNotEmpty ? zonesList.first : ''))
                                    : '',
                              );
                              
                              bool success;
                              if (video == null) {
                                success = await context.read<VideoProvider>().addVideo(
                                  newVideo,
                                  videoBytes,
                                  thumbnailBytes,
                                  onVideoProgress: (p) {
                                    setDialogState(() {
                                      videoProgress = p;
                                    });
                                  },
                                  onThumbnailProgress: (p) {
                                    setDialogState(() {
                                      thumbnailProgress = p;
                                    });
                                  },
                                );
                                if (success && dialogCtx.mounted) {
                                  await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                                    title: 'New Educational Video',
                                    body: newVideo.title,
                                    routingPath: AppRoutes.videos,
                                  );
                                }
                              } else {
                                success = await context.read<VideoProvider>().updateVideo(
                                  newVideo,
                                  videoBytes,
                                  thumbnailBytes,
                                  onVideoProgress: (p) {
                                    setDialogState(() {
                                      videoProgress = p;
                                    });
                                  },
                                  onThumbnailProgress: (p) {
                                    setDialogState(() {
                                      thumbnailProgress = p;
                                    });
                                  },
                                );
                              }
                              
                              if (success && dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                              } else if (dialogCtx.mounted) {
                                setDialogState(() {
                                  isSaving = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to save educational video.')),
                                );
                              }
                            } catch (e) {
                              if (dialogCtx.mounted) {
                                setDialogState(() {
                                  isSaving = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              }
                            }
                          }
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUpcomingEventsView(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final events = provider.eventsList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.04), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Events Management',
                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showEventDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Event'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                  : events.isEmpty
                      ? const Center(child: Text('No upcoming events scheduled.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final e = events[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildCardWrapper(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: AppRadius.borderMd,
                                        ),
                                        child: const Icon(Icons.event, color: Colors.amber, size: 24),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.title,
                                              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Date: ${e.date} | Time: ${e.time} | Location: ${e.location}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEventDialog(context, event: e),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          title: 'Delete Event',
                                          content: 'Are you sure you want to delete ${e.title}?',
                                          onConfirm: () => provider.deleteEvent(e.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _showEventDialog(BuildContext context, {EventModel? event}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: event?.title ?? '');
    final locCtrl = TextEditingController(text: event?.location ?? '');
    final dateCtrl = TextEditingController(text: event?.date ?? '');
    final timeCtrl = TextEditingController(text: event?.time ?? '10:30 AM');
    final linkCtrl = TextEditingController(text: event?.link ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(event == null ? 'Schedule Upcoming Event' : 'Edit Upcoming Event'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Event Title *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locCtrl,
                        decoration: const InputDecoration(labelText: 'Location *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Event Date *',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: event != null ? (DateTime.tryParse(event.date) ?? DateTime.now()) : DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: timeCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Event Time *',
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              timeCtrl.text = picked.format(context);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: linkCtrl,
                        decoration: const InputDecoration(labelText: 'Meeting URL / Link (Optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newEvent = EventModel(
                        id: event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text.trim(),
                        location: locCtrl.text.trim(),
                        date: dateCtrl.text.trim(),
                        createdAt: event?.createdAt ?? DateTime.now().toIso8601String(),
                        time: timeCtrl.text.trim(),
                        link: linkCtrl.text.trim(),
                      );
                      
                      bool success;
                      if (event == null) {
                        success = await context.read<EventProvider>().addEvent(newEvent);
                        if (success && dialogCtx.mounted) {
                          await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                            title: 'New Event Scheduled',
                            body: '${newEvent.title} on ${newEvent.date}',
                            routingPath: AppRoutes.notification,
                          );
                        }
                      } else {
                        success = await context.read<EventProvider>().updateEvent(newEvent);
                      }
                      
                      if (success && dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.brandPrimary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyle.bodyMd(color: AppColors.brandSecondary).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

