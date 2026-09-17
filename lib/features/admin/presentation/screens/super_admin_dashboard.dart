import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/file_picker_helper.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/app_pdf_viewer_screen.dart';

import '../../../ads/data/models/ad_model.dart';
import '../../../ads/presentation/providers/ad_provider.dart';
import '../../../auth/data/models/admin_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../forms_circulars/data/models/form_circular_model.dart';
import '../../../forms_circulars/presentation/providers/forms_circulars_provider.dart';
import '../../../gallery/data/models/gallery_image_model.dart';
import '../../../gallery/presentation/providers/gallery_provider.dart';
import '../../../government_orders/data/models/government_order_model.dart';
import '../../../government_orders/presentation/providers/government_orders_provider.dart';
import '../../../live_sessions/data/models/live_session_model.dart';
import '../../../live_sessions/presentation/providers/live_sessions_provider.dart';
import '../../../meeting_minutes/data/models/meeting_minutes_model.dart';
import '../../../meeting_minutes/presentation/providers/meeting_minutes_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../state_committee/data/models/committee_member_model.dart';
import '../../../state_committee/presentation/providers/state_committee_provider.dart';
import '../../../updates/data/models/update_model.dart';
import '../../../updates/presentation/providers/updates_provider.dart';
import '../../../videos/data/models/video_model.dart';
import '../../../videos/presentation/providers/video_provider.dart';
import '../../../zonal/data/models/zonal_member_model.dart';
import '../../../zonal/presentation/providers/zonal_provider.dart';
import '../providers/admin_provider.dart';

/// SuperAdminDashboard renders the full-suite super administrative operations panel,
/// giving Super Admin complete feature parity with Admin alongside master privileges.
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeTab = 'Dashboard';

  // Form keys
  final _adminFormKey = GlobalKey<FormState>();
  final _zoneFormKey = GlobalKey<FormState>();
  final _designationFormKey = GlobalKey<FormState>();

  // Text Controllers
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  String? _selectedAdminZone;
  final _zoneNameController = TextEditingController();
  final _designationNameController = TextEditingController();
  final _userSearchController = TextEditingController();
  final _committeeSearchController = TextEditingController();

  // Search & Filter States
  String _userSearchQuery = '';
  String _statusFilter = 'All Statuses';
  String _committeeZoneFilter = 'All';
  String _committeeSearchQuery = '';
  String? _expandedUserUid;

  // Mock Settings States
  String _clearanceLevel = 'Superadmin';

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
      if (currentAdmin == null || currentAdmin.role != 'super_admin') {
        context.go(AppRoutes.superAdminLogin);
      } else {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _zoneNameController.dispose();
    _designationNameController.dispose();
    _userSearchController.dispose();
    _committeeSearchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    final adminProv = context.read<AdminProvider>();
    adminProv.fetchAdmins();
    adminProv.fetchZones();
    adminProv.fetchDesignations();
    adminProv.fetchPendingUsers();
    adminProv.fetchApprovedUsers();
    adminProv.fetchRejectedUsers();

    // Module Providers
    context.read<StateCommitteeProvider>().fetchMembers();
    context.read<MeetingMinutesProvider>().fetchAllMinutes();
    context.read<GovernmentOrdersProvider>().fetchAllOrders();
    context.read<FormsCircularsProvider>().fetchAllForms();
    context.read<ZonalProvider>().fetchMembers();
    context.read<UpdatesProvider>().fetchUpdates();
    context.read<LiveSessionProvider>().fetchLiveSessions();
    context.read<GalleryProvider>().fetchImages();
    context.read<VideoProvider>().fetchVideos();
    context.read<EventProvider>().fetchEvents();
    context.read<AdProvider>().fetchAds(force: true);
  }

  void _onTabChanged(String label) {
    final adminProv = context.read<AdminProvider>();
    if (label == 'Dashboard') {
      _refreshData();
    } else if (label == 'All Members' || label == 'Pending Approvals') {
      adminProv.fetchPendingUsers();
      adminProv.fetchApprovedUsers();
      adminProv.fetchRejectedUsers();
    } else if (label == 'Approved Members') {
      adminProv.fetchApprovedUsers();
    } else if (label == 'Rejected Requests') {
      adminProv.fetchRejectedUsers();
    } else if (label == 'Zonal Admins') {
      adminProv.fetchAdmins();
    } else if (label == 'Zones') {
      adminProv.fetchZones();
    } else if (label == 'Designations') {
      adminProv.fetchDesignations();
    } else if (label == 'State Committee' || label == 'State Committee Members') {
      context.read<StateCommitteeProvider>().fetchMembers();
    } else if (label == 'Executive Committee' || label == 'Executive Committee Members' || label == 'Zonal Committee' || label == 'Zonal Committee Members') {
      context.read<ZonalProvider>().fetchMembers();
      adminProv.fetchZones();
      adminProv.fetchDesignations();
    } else if (label == 'Meeting Minutes' || label == 'Minutes Approvals') {
      context.read<MeetingMinutesProvider>().fetchAllMinutes();
    } else if (label == 'Government Orders') {
      context.read<GovernmentOrdersProvider>().fetchAllOrders();
    } else if (label == 'Forms & Circulars') {
      context.read<FormsCircularsProvider>().fetchAllForms();
    } else if (label == 'Updates') {
      context.read<UpdatesProvider>().fetchUpdates();
    } else if (label == 'Live Sessions') {
      context.read<LiveSessionProvider>().fetchLiveSessions();
    } else if (label == 'Gallery') {
      context.read<GalleryProvider>().fetchImages();
    } else if (label == 'Educational Videos') {
      context.read<VideoProvider>().fetchVideos();
    } else if (label == 'Upcoming Events') {
      context.read<EventProvider>().fetchEvents();
    } else if (label == 'Ads Carousel') {
      context.read<AdProvider>().fetchAds(force: true);
    }
  }

  // ==========================================
  // Zonal Admin Management Handlers
  // ==========================================

  Future<void> _handleAddAdmin() async {
    if (!_adminFormKey.currentState!.validate()) return;
    if (_selectedAdminZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a zone'), backgroundColor: AppColors.error),
      );
      return;
    }

    final newAdmin = AdminModel(
      username: _adminUsernameController.text.trim(),
      password: _adminPasswordController.text.trim(),
      role: 'zonal_admin',
      zone: _selectedAdminZone,
      createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    final success = await context.read<AdminProvider>().addAdmin(newAdmin);
    if (success && mounted) {
      _adminUsernameController.clear();
      _adminPasswordController.clear();
      setState(() => _selectedAdminZone = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zonal admin created successfully'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _handleAddZone() async {
    if (!_zoneFormKey.currentState!.validate()) return;

    final name = _zoneNameController.text.trim();
    final success = await context.read<AdminProvider>().addZone(name);
    if (success && mounted) {
      _zoneNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone added successfully'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _handleAddDesignation() async {
    if (!_designationFormKey.currentState!.validate()) return;

    final name = _designationNameController.text.trim();
    final success = await context.read<AdminProvider>().addDesignation(name);
    if (success && mounted) {
      _designationNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Designation added successfully'), backgroundColor: Colors.green),
      );
    }
  }

  // ==========================================
  // UI Builder
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    final currentAdmin = adminProvider.currentAdmin;
    if (currentAdmin == null || currentAdmin.role != 'super_admin') {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)));
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent(isMobile: true)),
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(_activeTab, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              backgroundColor: AppColors.surfaceContainerLowest,
              elevation: 1,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                ),
              ],
            ),
      backgroundColor: isDesktop ? AppColors.surfaceContainerLow : AppColors.brandBackground,
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) _buildSidebarContent(isMobile: false),
            Expanded(
              child: isDesktop
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildHeaderFrame(context),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: _buildTabContent(adminProvider),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: AppColors.surfaceContainerLowest,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: _buildTabContent(adminProvider),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderFrame(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Data'),
              ),
              const SizedBox(width: AppSpacing.lg),
              const VerticalDivider(width: 1, indent: 8, endIndent: 8),
              const SizedBox(width: AppSpacing.lg),
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandPrimary,
                child: Icon(Icons.security, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Super Admin',
                    style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Root Administrator',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent({required bool isMobile}) {
    final adminProv = context.watch<AdminProvider>();
    final minutesProv = context.watch<MeetingMinutesProvider>();
    final pendingUsers = adminProv.pendingUsers.length;
    final pendingMinutes = minutesProv.minutesList.where((m) => m.status == 'pending').length;

    return Container(
      width: isMobile ? 280 : 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isMobile ? Colors.white : AppColors.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: AppColors.brandSecondary.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo / Header
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPrimary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY KGRA',
                      style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      'Super Admin Portal',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _buildSidebarSectionHeader('CORE & MEMBERS'),
                _buildSidebarItem('Dashboard', Icons.dashboard_outlined),
                _buildSidebarItem('All Members', Icons.groups_outlined),
                _buildSidebarItem('Pending Approvals', Icons.hourglass_top_outlined, badgeCount: pendingUsers > 0 ? pendingUsers : null),
                _buildSidebarItem('Approved Members', Icons.verified_user_outlined),
                _buildSidebarItem('Rejected Requests', Icons.cancel_outlined),

                const SizedBox(height: 12),
                _buildSidebarSectionHeader('MASTER GOVERNANCE'),
                _buildSidebarItem('Zonal Admins', Icons.admin_panel_settings_outlined),
                _buildSidebarItem('Zones', Icons.map_outlined),
                _buildSidebarItem('Designations', Icons.badge_outlined),
                _buildSidebarItem('Ads Carousel', Icons.view_carousel_outlined),

                const SizedBox(height: 12),
                _buildSidebarSectionHeader('LEADERSHIP COMMITTEES'),
                _buildSidebarItem('State Committee Members', Icons.account_balance_outlined),
                _buildSidebarItem('Executive Committee Members', Icons.stars_outlined),
                _buildSidebarItem('Zonal Committee Members', Icons.group_work_outlined),

                const SizedBox(height: 12),
                _buildSidebarSectionHeader('MEDIA & DOCUMENTS'),
                _buildSidebarItem('Meeting Minutes', Icons.description_outlined),
                _buildSidebarItem('Minutes Approvals', Icons.approval_outlined, badgeCount: pendingMinutes > 0 ? pendingMinutes : null),
                _buildSidebarItem('Government Orders', Icons.gavel_outlined),
                _buildSidebarItem('Forms & Circulars', Icons.folder_zip_outlined),
                _buildSidebarItem('Updates', Icons.campaign_outlined),
                _buildSidebarItem('Live Sessions', Icons.live_tv_outlined),
                _buildSidebarItem('Gallery', Icons.photo_library_outlined),
                _buildSidebarItem('Educational Videos', Icons.video_library_outlined),
                _buildSidebarItem('Upcoming Events', Icons.event_outlined),

                const SizedBox(height: 12),
                _buildSidebarSectionHeader('SYSTEM'),
                _buildSidebarItem('Settings', Icons.settings_outlined),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Footer Back Button / Log Out
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
                context.read<AdminProvider>().logoutAdmin();
                context.go(AppRoutes.superAdminLogin);
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String label, IconData icon, {int? badgeCount}) {
    final isSelected = _activeTab == label;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: InkWell(
            onTap: () {
              setState(() {
                _activeTab = label;
                _expandedUserUid = null;
                _userSearchQuery = '';
                _userSearchController.clear();
              });
              _onTabChanged(label);
              if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                _scaffoldKey.currentState?.closeDrawer();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? const Color(0xFF8B1E2D) : const Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF8B1E2D) : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (badgeCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: label == 'Pending Approvals' || label == 'Minutes Approvals' ? AppColors.error : AppColors.brandPrimary,
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
            left: -8,
            top: 6,
            bottom: 10,
            child: Container(
              width: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E2D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // Main Content Tab Switcher
  // ==========================================

  Widget _buildTabContent(AdminProvider adminProvider) {
    switch (_activeTab) {
      case 'Dashboard':
        return _buildDashboardView(adminProvider);
      case 'All Members':
        return _buildSuperAdminUsersView(context, 'all', adminProvider);
      case 'Pending Approvals':
        return _buildSuperAdminUsersView(context, 'pending', adminProvider);
      case 'Approved Members':
        return _buildSuperAdminUsersView(context, 'approved', adminProvider);
      case 'Rejected Requests':
        return _buildSuperAdminUsersView(context, 'rejected', adminProvider);
      case 'Zonal Admins':
        return _buildZonalAdminsView(adminProvider);
      case 'Zones':
        return _buildZonesView(adminProvider);
      case 'Designations':
        return _buildDesignationsView(adminProvider);
      case 'State Committee':
      case 'State Committee Members':
        return _buildStateCommitteeView(context);
      case 'Executive Committee':
      case 'Executive Committee Members':
        return _buildExecutiveCommitteeView(context);
      case 'Zonal Committee':
      case 'Zonal Committee Members':
        return _buildZonalCommitteeView(context);
      case 'Meeting Minutes':
        return _buildMeetingMinutesView(context);
      case 'Minutes Approvals':
        return _buildMinutesApprovalsView();
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
      case 'Ads Carousel':
        return _buildAdsView(context);
      case 'Settings':
        return _buildSettingsView(context);
      default:
        return _buildDashboardView(adminProvider);
    }
  }

  // ==========================================
  // 1. Dashboard View (KPI Analytics)
  // ==========================================

  Widget _buildDashboardView(AdminProvider adminProvider) {
    final pendingNum = adminProvider.pendingUsers.length;
    final approvedNum = adminProvider.approvedUsers.length;
    final rejectedNum = adminProvider.rejectedUsers.length;
    final totalNum = pendingNum + approvedNum + rejectedNum;
    final zonalAdminsCount = adminProvider.admins.length;
    final zonesCount = adminProvider.zones.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Master Overview',
            style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Real-time statistics across all zones and administrative modules.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: AppSpacing.xl),

          // KPI Cards Grid
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _buildStatCard(
                title: 'Total Registrations',
                value: totalNum.toString(),
                icon: Icons.groups,
                color: AppColors.brandPrimary,
                subtitle: 'All time registrations',
              ),
              _buildStatCard(
                title: 'Pending Approvals',
                value: pendingNum.toString(),
                icon: Icons.hourglass_top,
                color: Colors.orange,
                subtitle: 'Action required',
              ),
              _buildStatCard(
                title: 'Approved Members',
                value: approvedNum.toString(),
                icon: Icons.verified,
                color: Colors.green,
                subtitle: 'Active verified members',
              ),
              _buildStatCard(
                title: 'Rejected Requests',
                value: rejectedNum.toString(),
                icon: Icons.cancel,
                color: AppColors.error,
                subtitle: 'Declined submissions',
              ),
              _buildStatCard(
                title: 'Zonal Admins',
                value: zonalAdminsCount.toString(),
                icon: Icons.admin_panel_settings,
                color: Colors.indigo,
                subtitle: 'Active zonal accounts',
              ),
              _buildStatCard(
                title: 'Configured Zones',
                value: zonesCount.toString(),
                icon: Icons.map,
                color: Colors.teal,
                subtitle: 'Territorial jurisdictions',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Quick Navigation Shortcuts
          Text(
            'Quick Actions',
            style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _buildQuickActionButton(
                label: 'Manage Zonal Admins',
                icon: Icons.person_add_alt_1,
                onTap: () => setState(() => _activeTab = 'Zonal Admins'),
              ),
              _buildQuickActionButton(
                label: 'Approve Pending Users',
                icon: Icons.how_to_reg,
                onTap: () => setState(() => _activeTab = 'Pending Approvals'),
              ),
              _buildQuickActionButton(
                label: 'Review Meeting Minutes',
                icon: Icons.approval,
                onTap: () => setState(() => _activeTab = 'Minutes Approvals'),
              ),
              _buildQuickActionButton(
                label: 'Publish Government Order',
                icon: Icons.upload_file,
                onTap: () => setState(() => _activeTab = 'Government Orders'),
              ),
              _buildQuickActionButton(
                label: 'Broadcast Update',
                icon: Icons.campaign,
                onTap: () => setState(() => _activeTab = 'Updates'),
              ),
              _buildQuickActionButton(
                label: 'Manage Ads Carousel',
                icon: Icons.view_carousel,
                onTap: () => setState(() => _activeTab = 'Ads Carousel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandSecondary,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandSecondary,
        elevation: 0,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.brandPrimary),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  // ==========================================
  // 2. Members Management (All / Pending / Approved / Rejected)
  // ==========================================

  Widget _buildSuperAdminUsersView(BuildContext context, String tabType, AdminProvider adminProvider) {
    List<UserModel> users;
    if (tabType == 'pending') {
      users = adminProvider.pendingUsers;
    } else if (tabType == 'approved') {
      users = adminProvider.approvedUsers;
    } else if (tabType == 'rejected') {
      users = adminProvider.rejectedUsers;
    } else {
      users = [
        ...adminProvider.pendingUsers,
        ...adminProvider.approvedUsers,
        ...adminProvider.rejectedUsers,
      ];
    }

    final filteredUsers = users.where((u) {
      final matchesQuery = _userSearchQuery.isEmpty ||
          u.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          u.phoneNumber.contains(_userSearchQuery) ||
          (u.membershipId != null && u.membershipId!.toLowerCase().contains(_userSearchQuery.toLowerCase())) ||
          (u.zone != null && u.zone!.toLowerCase().contains(_userSearchQuery.toLowerCase()));

      final matchesStatus = _statusFilter == 'All Statuses' || u.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Filter & Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userSearchController,
                  onChanged: (val) => setState(() => _userSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, membership ID, or zone...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: AppRadius.borderMd),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (tabType == 'all')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      style: const TextStyle(color: AppColors.brandSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      onChanged: (val) {
                        if (val != null) setState(() => _statusFilter = val);
                      },
                      items: const [
                        DropdownMenuItem(value: 'All Statuses', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // User List
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No members found matching the criteria.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isExpanded = _expandedUserUid == user.uid;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderLg,
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                                  child: Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusBadge(user.status),
                                  ],
                                ),
                                subtitle: Text(
                                  'Phone: ${user.phoneNumber} | Zone: ${user.zone ?? "N/A"} | Member ID: ${user.membershipId ?? "N/A"}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                      tooltip: 'Delete Member',
                                      onPressed: () => _handleDeleteUser(context, user.uid, adminProvider),
                                    ),
                                    IconButton(
                                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                      onPressed: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedUserUid = null;
                                          } else {
                                            _expandedUserUid = user.uid;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (isExpanded) ...[
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: AppSpacing.xl,
                                        runSpacing: AppSpacing.md,
                                        children: [
                                          _buildUserDetailTile(Icons.phone_outlined, 'Phone', user.phoneNumber),
                                          _buildUserDetailTile(Icons.badge_outlined, 'Designation', user.designation ?? 'N/A'),
                                          _buildUserDetailTile(Icons.business_outlined, 'Institution', user.institution ?? 'N/A'),
                                          _buildUserDetailTile(Icons.map_outlined, 'Zone', user.zone ?? 'N/A'),
                                          _buildUserDetailTile(Icons.card_membership_outlined, 'Membership ID', user.membershipId ?? 'N/A'),
                                          _buildUserDetailTile(Icons.cake_outlined, 'Date of Birth', AppDateFormatter.formatToDateMonthYear(user.dateOfBirth, fallback: 'N/A')),
                                          _buildUserDetailTile(Icons.event_outlined, 'Date of Join', AppDateFormatter.formatToDateMonthYear(user.dateOfJoin, fallback: 'N/A')),
                                          _buildUserDetailTile(Icons.work_off_outlined, 'Retirement Date', AppDateFormatter.formatToDateMonthYear(user.dateOfRetirement, fallback: 'N/A')),
                                          if (user.reviewedByName != null || user.reviewedAt != null)
                                            _buildUserDetailTile(Icons.verified_user_outlined, 'Reviewed By', '${user.reviewedByName ?? "Admin"} (${user.reviewedAt ?? ""})'),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // Actions
                                      Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (user.profileImageId != null && user.profileImageId!.isNotEmpty)
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.brandPrimary,
                                                side: const BorderSide(color: AppColors.brandPrimary),
                                              ),
                                              onPressed: () => _viewIdProofDialog(context, user, adminProvider),
                                              icon: const Icon(Icons.badge, size: 16),
                                              label: const Text('View Photo ID'),
                                            ),
                                          if (user.status == 'pending') ...[
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                              onPressed: () => _showRejectDialog(context, user.uid, adminProvider),
                                              icon: const Icon(Icons.close, size: 16),
                                              label: const Text('Reject'),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                final notifProvider = context.read<NotificationProvider>();
                                                final success = await adminProvider.approveUser(user.uid);
                                                if (success && context.mounted) {
                                                  await notifProvider.sendSystemNotification(
                                                    title: 'Registration Approved',
                                                    body: 'Your account registration has been approved.',
                                                    routingPath: AppRoutes.home,
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('User approved successfully'), backgroundColor: Colors.green),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.check, size: 16),
                                              label: const Text('Approve'),
                                            ),
                                          ],
                                          if (user.status == 'approved') ...[
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                                              onPressed: () => _showRejectDialog(context, user.uid, adminProvider),
                                              icon: const Icon(Icons.block, size: 16),
                                              label: const Text('Revoke / Reject'),
                                            ),
                                          ],
                                          if (user.status == 'rejected') ...[
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                final success = await adminProvider.approveUser(user.uid);
                                                if (success && context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('User approved successfully'), backgroundColor: Colors.green),
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.check, size: 16),
                                              label: const Text('Re-Approve'),
                                            ),
                                          ],
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                              side: const BorderSide(color: AppColors.error),
                                            ),
                                            onPressed: () => _handleDeleteUser(context, user.uid, adminProvider),
                                            icon: const Icon(Icons.delete_outline, size: 16),
                                            label: const Text('Delete Member'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    if (status == 'approved') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (status == 'rejected') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
      label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildUserDetailTile(IconData icon, String title, String value) {
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewIdProofDialog(BuildContext context, UserModel user, AdminProvider adminProvider) {
    if (user.profileImageId != null && !adminProvider.userImages.containsKey(user.uid)) {
      adminProvider.fetchUserImage(user.profileImageId!, user.uid);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final imgBase64 = adminProvider.userImages[user.uid];
        final isLoading = adminProvider.isImageLoading(user.uid);
        return AlertDialog(
          title: Text('${user.name} - Profile Photo'),
          content: isLoading
              ? const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                )
              : imgBase64 != null
                  ? Image.memory(base64Decode(imgBase64), fit: BoxFit.contain)
                  : const Text('No Photo document available.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _handleDeleteUser(BuildContext context, String uid, AdminProvider provider) {
    _confirmDelete(
      context,
      title: 'Delete Member',
      content: 'Are you sure you want to permanently delete this member registration? This action cannot be undone.',
      onConfirm: () async {
        final success = await provider.deleteUser(uid);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member deleted successfully.'),
              backgroundColor: Colors.black87,
            ),
          );
        }
      },
    );
  }

  void _showRejectDialog(BuildContext context, String uid, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Registration'),
        content: const Text('Are you sure you want to reject this member registration?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await provider.rejectUser(uid);
              if (success && dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registration rejected'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. Zonal Admins Management
  // ==========================================

  Widget _buildZonalAdminsView(AdminProvider adminProvider) {
    final admins = adminProvider.admins;
    final zones = adminProvider.zones;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zonal Administrators',
            style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Create and manage administrator accounts for specific zones.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: AppSpacing.xl),

          // Create Admin Form
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Form(
              key: _adminFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create New Zonal Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      SizedBox(
                        width: 250,
                        child: TextFormField(
                          controller: _adminUsernameController,
                          decoration: const InputDecoration(labelText: 'Username *', isDense: true),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: TextFormField(
                          controller: _adminPasswordController,
                          decoration: const InputDecoration(labelText: 'Password *', isDense: true),
                          obscureText: true,
                          validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: DropdownButtonFormField<String>(
                          value: _selectedAdminZone,
                          decoration: const InputDecoration(labelText: 'Assigned Zone *', isDense: true),
                          items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                          onChanged: (val) => setState(() => _selectedAdminZone = val),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onPressed: _handleAddAdmin,
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Add Admin'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // List Zonal Admins
          Text('Active Zonal Admins (${admins.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.md),

          admins.isEmpty
              ? const Text('No zonal admins configured yet.', style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final admin = admins[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.brandPrimary,
                          child: Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                        title: Text(admin.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Zone: ${admin.zone ?? "All"} | Role: ${admin.role}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _confirmDelete(
                            context,
                            title: 'Delete Admin',
                            content: 'Are you sure you want to delete zonal admin ${admin.username}?',
                            onConfirm: () => adminProvider.deleteAdmin(admin.username),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. Zones Management
  // ==========================================

  Widget _buildZonesView(AdminProvider adminProvider) {
    final zones = adminProvider.zones;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zones Master Registry', style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Define administrative geographic zones for user partitioning and zonal leadership.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: AppSpacing.xl),

          // Add Zone Form
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Form(
              key: _zoneFormKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _zoneNameController,
                      decoration: const InputDecoration(labelText: 'New Zone Name (e.g. Kozhikode, Trivandrum)', isDense: true),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onPressed: _handleAddZone,
                    icon: const Icon(Icons.add_location_alt, size: 18),
                    label: const Text('Add Zone'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Registered Zones (${zones.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.md),

          zones.isEmpty
              ? const Text('No zones configured.', style: TextStyle(color: Colors.grey))
              : Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: zones.map((z) {
                    return Chip(
                      label: Text(z, style: const TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.error),
                      onDeleted: () => _confirmDelete(
                        context,
                        title: 'Delete Zone',
                        content: 'Are you sure you want to remove zone $z?',
                        onConfirm: () => adminProvider.deleteZone(z),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. Designations Management
  // ==========================================

  Widget _buildDesignationsView(AdminProvider adminProvider) {
    final designations = adminProvider.designations;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Designations Master Registry', style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Configure official executive titles and designations for committee leaders and members.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: AppSpacing.xl),

          // Add Designation Form
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Form(
              key: _designationFormKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _designationNameController,
                      decoration: const InputDecoration(labelText: 'New Designation (e.g. President, General Secretary, Treasurer)', isDense: true),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onPressed: _handleAddDesignation,
                    icon: const Icon(Icons.badge, size: 18),
                    label: const Text('Add Designation'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Registered Designations (${designations.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.md),

          designations.isEmpty
              ? const Text('No designations configured.', style: TextStyle(color: Colors.grey))
              : Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: designations.map((d) {
                    return Chip(
                      label: Text(d, style: const TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.error),
                      onDeleted: () => _confirmDelete(
                        context,
                        title: 'Delete Designation',
                        content: 'Are you sure you want to remove designation $d?',
                        onConfirm: () => adminProvider.deleteDesignation(d),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. State Committee Management
  // ==========================================

  Widget _buildStateCommitteeView(BuildContext context) {
    final provider = context.watch<StateCommitteeProvider>();
    final members = provider.members;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('State Committee Members (${members.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showStateMemberDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Member'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : members.isEmpty
                  ? const Center(child: Text('No State Committee members found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final m = members[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                              backgroundImage: m.photoBase64 != null ? MemoryImage(base64Decode(m.photoBase64!)) : null,
                              child: m.photoBase64 == null ? const Icon(Icons.person, color: AppColors.brandPrimary) : null,
                            ),
                            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${m.designation} | Phone: ${m.phoneNumber} | Email: ${m.email}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showStateMemberDialog(context, member: m),
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
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showStateMemberDialog(BuildContext context, {CommitteeMemberModel? member}) {
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(member == null ? 'Add State Committee Member' : 'Update State Member'),
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
                        setDialogState(() => photoBase64 = base64Encode(bytes));
                      }
                    },
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64!)) : null,
                      child: photoBase64 == null ? const Icon(Icons.add_a_photo, size: 28, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
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
                    decoration: const InputDecoration(labelText: 'Email Address'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
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
                        body: '${newMember.name} joined the State Committee.',
                        routingPath: AppRoutes.stateCommittee,
                      );
                    }
                  } else {
                    success = await context.read<StateCommitteeProvider>().updateMember(newMember);
                  }
                  if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 7. Executive & Zonal Committee Management
  // ==========================================

  Widget _buildExecutiveCommitteeView(BuildContext context) {
    return _buildZonalOrExecutiveCommitteeView(context, isExecutive: true);
  }

  Widget _buildZonalCommitteeView(BuildContext context) {
    return _buildZonalOrExecutiveCommitteeView(context, isExecutive: false);
  }

  Widget _buildZonalOrExecutiveCommitteeView(BuildContext context, {required bool isExecutive}) {
    final zonalProv = context.watch<ZonalProvider>();
    final adminProv = context.watch<AdminProvider>();
    final allMembers = isExecutive
        ? zonalProv.members.where((m) => m.zone.toLowerCase().contains('executive')).toList()
        : zonalProv.members.where((m) => !m.zone.toLowerCase().contains('executive')).toList();
    final zones = adminProv.zones;

    final filtered = allMembers.where((m) {
      final matchesZone = _committeeZoneFilter == 'All' || m.zone == _committeeZoneFilter;
      final matchesQuery = _committeeSearchQuery.isEmpty ||
          m.name.toLowerCase().contains(_committeeSearchQuery.toLowerCase()) ||
          m.designation.toLowerCase().contains(_committeeSearchQuery.toLowerCase());
      return (isExecutive || matchesZone) && matchesQuery;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Text(
                '${isExecutive ? "Executive" : "Zonal"} Committee Members (${filtered.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (!isExecutive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _committeeZoneFilter,
                      style: const TextStyle(color: AppColors.brandSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      onChanged: (val) {
                        if (val != null) setState(() => _committeeZoneFilter = val);
                      },
                      items: ['All', ...zones].map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showZonalMemberDialog(context, isExecutive: isExecutive),
                icon: const Icon(Icons.add, size: 18),
                label: Text(isExecutive ? 'Add Executive Member' : 'Add Zonal Member'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No members found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final m = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                          backgroundImage: m.photoBase64 != null ? MemoryImage(base64Decode(m.photoBase64!)) : null,
                          child: m.photoBase64 == null ? const Icon(Icons.person, color: AppColors.brandPrimary) : null,
                        ),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${isExecutive ? "Executive Committee" : "Zone: ${m.zone}"} | Designation: ${m.designation} | Phone: ${m.phoneNumber}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showZonalMemberDialog(context, member: m, isExecutive: isExecutive),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _confirmDelete(
                                context,
                                title: 'Delete Member',
                                content: 'Are you sure you want to delete ${m.name}?',
                                onConfirm: () => zonalProv.deleteMember(m.id),
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

  void _showZonalMemberDialog(BuildContext context, {ZonalMemberModel? member, required bool isExecutive}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final phoneCtrl = TextEditingController(text: member?.phoneNumber ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    String? photoBase64 = member?.photoBase64;
    final zones = context.read<AdminProvider>().zones;
    final designations = context.read<AdminProvider>().designations;

    String? selectedZone = member?.zone;
    if (selectedZone == null && zones.isNotEmpty) selectedZone = zones.first;

    String? selectedDesignation = member?.designation;
    if (selectedDesignation == null && designations.isNotEmpty) selectedDesignation = designations.first;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(member == null ? (isExecutive ? 'Add Executive Member' : 'Add Zonal Member') : (isExecutive ? 'Update Executive Member' : 'Update Zonal Member')),
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
                        setDialogState(() => photoBase64 = base64Encode(bytes));
                      }
                    },
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64!)) : null,
                      child: photoBase64 == null ? const Icon(Icons.add_a_photo, size: 28, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  if (!isExecutive) ...[
                    DropdownButtonFormField<String>(
                      value: selectedZone != null && zones.any((z) => z.toLowerCase() == selectedZone?.toLowerCase())
                          ? zones.firstWhere((z) => z.toLowerCase() == selectedZone?.toLowerCase())
                          : (zones.isNotEmpty ? zones.first : null),
                      decoration: const InputDecoration(labelText: 'Zone *'),
                      items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: (val) => setDialogState(() => selectedZone = val),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
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
                    decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newMember = ZonalMemberModel(
                    id: member?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    designation: selectedDesignation ?? '',
                    phoneNumber: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    zone: isExecutive ? 'Executive Committee' : (selectedZone ?? ''),
                    photoBase64: photoBase64,
                    createdAt: member?.createdAt ?? DateTime.now().toIso8601String(),
                  );
                  bool success;
                  if (member == null) {
                    success = await context.read<ZonalProvider>().addMember(newMember);
                  } else {
                    success = await context.read<ZonalProvider>().updateMember(newMember);
                  }
                  if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 8. Meeting Minutes (Direct Upload & Approval)
  // ==========================================

  Widget _buildMeetingMinutesView(BuildContext context) {
    final provider = context.watch<MeetingMinutesProvider>();
    final minutes = provider.minutesList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meeting Minutes (${minutes.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showMeetingMinutesDialog(context),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Publish Minutes PDF'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : minutes.isEmpty
                  ? const Center(child: Text('No meeting minutes found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: minutes.length,
                      itemBuilder: (context, index) {
                        final m = minutes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: AppRadius.borderMd),
                              child: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 24),
                            ),
                            title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Date: ${m.date} | Zone: ${m.zone.isNotEmpty ? m.zone : "All"} | Status: ${m.status.toUpperCase()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showMeetingMinutesDialog(context, minute: m),
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
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showMeetingMinutesDialog(BuildContext context, {MeetingMinutesModel? minute}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: minute?.title ?? '');
    final dateCtrl = TextEditingController(text: minute?.date ?? '');
    String pdfName = minute?.pdfName ?? '';
    Uint8List? pdfBytes;
    bool isSaving = false;
    String selectedSection = minute?.section ?? 'all';
    if (selectedSection == 'all' && minute != null && minute.zone.isNotEmpty && minute.zone.toLowerCase() != 'all' && minute.zone.toLowerCase() != 'state' && minute.zone.toLowerCase() != 'executive' && minute.zone.toLowerCase() != 'executive committee') {
      selectedSection = 'zonal';
    }
    final zonesList = context.read<AdminProvider>().zones;
    String? selectedZone = minute?.zone;
    if (selectedZone == null && zonesList.isNotEmpty) selectedZone = zonesList.first;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(minute == null ? 'Publish Meeting Minutes' : 'Update Minutes'),
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
                    onChanged: isSaving ? null : (val) => setDialogState(() => selectedSection = val!),
                  ),
                  if (selectedSection == 'zonal') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedZone != null && zonesList.any((z) => z.toLowerCase() == selectedZone?.toLowerCase())
                          ? zonesList.firstWhere((z) => z.toLowerCase() == selectedZone?.toLowerCase())
                          : (zonesList.isNotEmpty ? zonesList.first : null),
                      decoration: const InputDecoration(labelText: 'Select Zone *'),
                      items: zonesList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: isSaving ? null : (val) => setDialogState(() => selectedZone = val),
                      validator: (v) => selectedSection == 'zonal' && (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Meeting Date *', suffixIcon: Icon(Icons.calendar_today)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onTap: isSaving
                        ? null
                        : () async {
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
                  OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final pickedFile = await pickPdfFile();
                            if (pickedFile != null) {
                              setDialogState(() {
                                pdfBytes = pickedFile.bytes;
                                pdfName = pickedFile.name;
                              });
                            }
                          },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Pick PDF Document *'),
                  ),
                  if (pdfName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Selected: $pdfName', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        if (minute == null && pdfBytes == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF file.')));
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          final newMinute = MeetingMinutesModel(
                            id: minute?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleCtrl.text.trim(),
                            date: dateCtrl.text.trim(),
                            section: selectedSection,
                            zone: selectedSection == 'zonal'
                                ? (selectedZone ?? '')
                                : (selectedSection == 'state'
                                    ? 'State'
                                    : (selectedSection == 'executive' ? 'Executive Committee' : 'All')),
                            pdfName: pdfName,
                            pdfUrl: minute?.pdfUrl ?? '',
                            status: minute?.status ?? 'approved',
                            createdAt: minute?.createdAt ?? DateTime.now().toIso8601String(),
                          );

                          bool success;
                          if (minute == null) {
                            success = await context.read<MeetingMinutesProvider>().addMinutes(newMinute, pdfBytes!);
                            if (success && dialogCtx.mounted) {
                              await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                                title: 'New Meeting Minutes Published',
                                body: newMinute.title,
                                routingPath: AppRoutes.meetingMinutes,
                              );
                            }
                          } else {
                            success = await context.read<MeetingMinutesProvider>().updateMinutes(newMinute, pdfBytes);
                          }

                          if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                        } finally {
                          if (dialogCtx.mounted) setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 9. Minutes Approvals (Super Admin Review)
  // ==========================================

  Widget _buildMinutesApprovalsView() {
    final minutesProv = context.watch<MeetingMinutesProvider>();
    final pendingMinutes = minutesProv.minutesList.where((m) => m.status == 'pending').toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pending Minutes Approvals (${pendingMinutes.length})', style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Review meeting minutes uploaded by zonal administrators before public release.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: AppSpacing.xl),

          pendingMinutes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No pending meeting minutes awaiting approval.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingMinutes.length,
                  itemBuilder: (context, index) {
                    final minute = pendingMinutes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.borderLg,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: AppRadius.borderMd),
                            child: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(minute.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Zone: ${minute.zone.isNotEmpty ? minute.zone : "All"} | Date: ${minute.date}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppPdfViewerScreen(
                                    title: minute.title,
                                    pdfUrl: minute.pdfUrl,
                                    folderName: 'meeting_minutes',
                                    docId: minute.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View PDF'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () async {
                              final success = await minutesProv.updateMinutes(minute.copyWith(status: 'approved'), null);
                              if (success && context.mounted) {
                                await context.read<NotificationProvider>().sendSystemNotification(
                                  title: 'Meeting Minutes Approved',
                                  body: minute.title,
                                  routingPath: AppRoutes.meetingMinutes,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minutes approved and published!'), backgroundColor: Colors.green));
                              }
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ==========================================
  // 10. Government Orders Management
  // ==========================================

  Widget _buildGovernmentOrdersView(BuildContext context) {
    final provider = context.watch<GovernmentOrdersProvider>();
    final orders = provider.orders;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Government Orders (GO) (${orders.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showGovernmentOrderDialog(context),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Add GO PDF'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : orders.isEmpty
                  ? const Center(child: Text('No Government Orders found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final o = orders[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: AppRadius.borderMd),
                              child: const Icon(Icons.gavel, color: Colors.orange, size: 24),
                            ),
                            title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Order No: ${o.orderNumber} | Date: ${o.date} | Section: ${o.section.toUpperCase()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(order == null ? 'Add Government Order' : 'Update Government Order'),
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
                    onChanged: isSaving ? null : (val) => setDialogState(() => selectedSection = val!),
                  ),
                  if (selectedSection == 'zonal') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedZone.isNotEmpty && zonesList.any((z) => z.toLowerCase() == selectedZone.toLowerCase())
                          ? zonesList.firstWhere((z) => z.toLowerCase() == selectedZone.toLowerCase())
                          : (zonesList.isNotEmpty ? zonesList.first : null),
                      decoration: const InputDecoration(labelText: 'Select Zone *'),
                      items: zonesList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: isSaving ? null : (val) => setDialogState(() => selectedZone = val!),
                      validator: (v) => selectedSection == 'zonal' && (v == null || v.isEmpty) ? 'Required' : null,
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
                    onTap: isSaving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked));
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final pickedFile = await pickPdfFile();
                            if (pickedFile != null) {
                              setDialogState(() {
                                pdfBytes = pickedFile.bytes;
                                pdfName = pickedFile.name;
                              });
                            }
                          },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Pick PDF Document *'),
                  ),
                  if (pdfName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Selected: $pdfName', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        if (order == null && pdfBytes == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF file.')));
                          return;
                        }

                        setDialogState(() => isSaving = true);
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
                            zone: selectedSection == 'zonal' ? selectedZone : '',
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

                          if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                        } finally {
                          if (dialogCtx.mounted) setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 11. Forms & Circulars Management
  // ==========================================

  Widget _buildFormsCircularsView(BuildContext context) {
    final provider = context.watch<FormsCircularsProvider>();
    final forms = provider.forms;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Forms & Circulars (${forms.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showFormCircularDialog(context),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Add Form PDF'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : forms.isEmpty
                  ? const Center(child: Text('No Forms or Circulars found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: forms.length,
                      itemBuilder: (context, index) {
                        final f = forms[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: AppRadius.borderMd),
                              child: const Icon(Icons.folder_zip, color: Colors.purple, size: 24),
                            ),
                            title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Circular No: ${f.circularNumber ?? "N/A"} | Date: ${f.date}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                  onPressed: () => _showFormCircularDialog(context, form: f),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.error),
                                  onPressed: () => _confirmDelete(
                                    context,
                                    title: 'Delete Form/Circular',
                                    content: 'Are you sure you want to delete ${f.title}?',
                                    onConfirm: () => provider.deleteForm(f),
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

  void _showFormCircularDialog(BuildContext context, {FormCircularModel? form}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: form?.title ?? '');
    final numCtrl = TextEditingController(text: form?.circularNumber ?? '');
    final dateCtrl = TextEditingController(text: form?.date ?? '');
    final urlCtrl = TextEditingController(text: form?.externalUrl ?? '');
    String pdfName = form?.pdfName ?? '';
    Uint8List? pdfBytes;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(form == null ? 'Add Form/Circular' : 'Update Form/Circular'),
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
                    enabled: !isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: numCtrl,
                    decoration: const InputDecoration(labelText: 'Circular Number (Optional)'),
                    enabled: !isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(labelText: 'External URL (Optional)'),
                    enabled: !isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Publish Date *', suffixIcon: Icon(Icons.calendar_today)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onTap: isSaving
                        ? null
                        : () async {
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
                  OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final pickedFile = await pickPdfFile();
                            if (pickedFile != null) {
                              setDialogState(() {
                                pdfBytes = pickedFile.bytes;
                                pdfName = pickedFile.name;
                              });
                            }
                          },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Pick PDF Document *'),
                  ),
                  if (pdfName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Selected: $pdfName', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        if (form == null && pdfBytes == null && urlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF file or enter an external URL.')));
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          final newForm = FormCircularModel(
                            id: form?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleCtrl.text.trim(),
                            circularNumber: numCtrl.text.trim().isEmpty ? null : numCtrl.text.trim(),
                            date: dateCtrl.text.trim(),
                            pdfName: pdfName,
                            pdfUrl: form?.pdfUrl ?? '',
                            externalUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                            createdAt: form?.createdAt ?? DateTime.now().toIso8601String(),
                          );

                          bool success;
                          if (form == null) {
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

                          if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                        } finally {
                          if (dialogCtx.mounted) setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 12. Updates & Announcements Management
  // ==========================================

  Widget _buildUpdatesView(BuildContext context) {
    final provider = context.watch<UpdatesProvider>();
    final updates = provider.updatesList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Updates & Announcements (${updates.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showUpdateDialog(context),
                icon: const Icon(Icons.add_alert, size: 18),
                label: const Text('New Update'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : updates.isEmpty
                  ? const Center(child: Text('No announcements found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: updates.length,
                      itemBuilder: (context, index) {
                        final u = updates[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: AppRadius.borderMd),
                              child: const Icon(Icons.campaign, color: Colors.teal, size: 24),
                            ),
                            title: Text(u.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Date: ${u.date} | Content: ${u.content.length > 60 ? "${u.content.substring(0, 60)}..." : u.content}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(update == null ? 'Post News Update' : 'Edit Update'),
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
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
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
                        title: 'New Announcement',
                        body: newUpdate.title,
                        routingPath: AppRoutes.updates,
                      );
                    }
                  } else {
                    success = await context.read<UpdatesProvider>().updateUpdate(newUpdate);
                  }

                  if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 13. Live Sessions Management
  // ==========================================

  Widget _buildLiveSessionsView(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();
    final sessions = provider.sessionsList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Sessions (${sessions.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showLiveSessionDialog(context),
                icon: const Icon(Icons.add_link, size: 18),
                label: const Text('Schedule Session'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : sessions.isEmpty
                  ? const Center(child: Text('No active live sessions.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final s = sessions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: AppRadius.borderMd),
                              child: const Icon(Icons.live_tv, color: Colors.red, size: 24),
                            ),
                            title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Date: ${s.date}\nURL: ${s.url}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showLiveSessionDialog(context, session: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.error),
                                  onPressed: () => _confirmDelete(
                                    context,
                                    title: 'Delete Session',
                                    content: 'Are you sure you want to remove session ${s.title}?',
                                    onConfirm: () => provider.deleteLiveSession(s.id),
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

  void _showLiveSessionDialog(BuildContext context, {LiveSessionModel? session}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: session?.title ?? '');
    final descCtrl = TextEditingController(text: session?.description ?? '');
    final urlCtrl = TextEditingController(text: session?.url ?? '');
    final dateCtrl = TextEditingController(text: session?.date ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
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

                  if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 14. Photo Gallery Management
  // ==========================================

  Widget _buildGalleryView(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    final images = provider.imagesList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Photo Gallery (${images.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showGalleryDialog(context),
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Upload Photo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : images.isEmpty
                  ? const Center(child: Text('No gallery photos available.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final img = images[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderLg,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      img.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
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
                                                content: 'Are you sure you want to remove photo ${img.title}?',
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
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  img.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(image == null ? 'Upload Photo to Gallery' : 'Update Gallery Photo'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isSaving
                        ? null
                        : () async {
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
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: Colors.grey.shade300),
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
                                    Icon(Icons.add_a_photo, size: 36, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Tap to pick photo *', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                    decoration: const InputDecoration(labelText: 'Photo Title *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        if (image == null && imageBytes == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a photo.')));
                          return;
                        }

                        setDialogState(() => isSaving = true);

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
                            await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                              title: 'New Gallery Photos Added',
                              body: newImage.title,
                              routingPath: AppRoutes.gallery,
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
                          setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(image == null ? 'Upload' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 15. Educational Videos Catalog
  // ==========================================

  Widget _buildEducationalVideosView(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final videos = provider.videosList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Educational & Training Videos (${videos.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showVideoDialog(context),
                icon: const Icon(Icons.video_call, size: 18),
                label: const Text('Add Video'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : videos.isEmpty
                  ? const Center(child: Text('No videos in the catalog.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final v = videos[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 60,
                              height: 45,
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: AppRadius.borderMd),
                              child: v.thumbnailUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: AppRadius.borderMd,
                                      child: Image.network(v.thumbnailUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.play_circle_filled, color: Colors.red)),
                                    )
                                  : const Icon(Icons.play_circle_filled, color: Colors.red, size: 24),
                            ),
                            title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('URL: ${v.videoUrl}\nDuration: ${(v.duration ~/ 60)}m ${(v.duration % 60)}s'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showVideoDialog(context, video: v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.error),
                                  onPressed: () => _confirmDelete(
                                    context,
                                    title: 'Delete Video',
                                    content: 'Are you sure you want to remove ${v.title}?',
                                    onConfirm: () => provider.deleteVideo(v.id),
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    onChanged: isSaving ? null : (val) => setDialogState(() => selectedSection = val!),
                  ),
                  if (selectedSection == 'zonal') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedZone.isNotEmpty && zonesList.any((z) => z.toLowerCase() == selectedZone.toLowerCase())
                          ? zonesList.firstWhere((z) => z.toLowerCase() == selectedZone.toLowerCase())
                          : (zonesList.isNotEmpty ? zonesList.first : null),
                      decoration: const InputDecoration(labelText: 'Select Zone *'),
                      items: zonesList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: isSaving ? null : (val) => setDialogState(() => selectedZone = val!),
                      validator: (v) => selectedSection == 'zonal' && (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                  const SizedBox(height: 16),
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
                    Text('Video: $videoName', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 16),
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
                    Text('Thumbnail: $thumbnailName', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
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
                  ]
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        if (video == null && videoBytes == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a video file.')));
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
                            zone: selectedSection == 'zonal' ? selectedZone : '',
                          );

                          bool success;
                          if (video == null) {
                            success = await context.read<VideoProvider>().addVideo(
                              newVideo,
                              videoBytes,
                              thumbnailBytes,
                              onVideoProgress: (p) => setDialogState(() => videoProgress = p),
                              onThumbnailProgress: (p) => setDialogState(() => thumbnailProgress = p),
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
                              onVideoProgress: (p) => setDialogState(() => videoProgress = p),
                              onThumbnailProgress: (p) => setDialogState(() => thumbnailProgress = p),
                            );
                          }

                          if (success && dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          } else if (dialogCtx.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                        } catch (e) {
                          if (dialogCtx.mounted) setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 16. Upcoming Events Management
  // ==========================================

  Widget _buildUpcomingEventsView(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final events = provider.eventsList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upcoming Events (${events.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showEventDialog(context),
                icon: const Icon(Icons.event, size: 18),
                label: const Text('Create Event'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : events.isEmpty
                  ? const Center(child: Text('No upcoming events scheduled.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final e = events[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: AppRadius.borderMd),
                              child: const Icon(Icons.event_available, color: Colors.green, size: 24),
                            ),
                            title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Date: ${e.date} | Venue: ${e.location}\nTime: ${e.time}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
    final venueCtrl = TextEditingController(text: event?.location ?? '');
    final descCtrl = TextEditingController(text: event?.link ?? '');
    final dateCtrl = TextEditingController(text: event?.date ?? '');
    final timeCtrl = TextEditingController(text: event?.time ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(event == null ? 'Schedule Upcoming Event' : 'Edit Event'),
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
                    controller: venueCtrl,
                    decoration: const InputDecoration(labelText: 'Venue / Location *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Event Date *', suffixIcon: Icon(Icons.calendar_today)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(labelText: 'Time (e.g. 10:30 AM)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Event Details'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newEvent = EventModel(
                    id: event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text.trim(),
                    location: venueCtrl.text.trim(),
                    date: dateCtrl.text.trim(),
                    time: timeCtrl.text.trim().isNotEmpty ? timeCtrl.text.trim() : '10:30 AM',
                    link: descCtrl.text.trim(),
                    createdAt: event?.createdAt ?? DateTime.now().toIso8601String(),
                  );

                  bool success;
                  if (event == null) {
                    success = await context.read<EventProvider>().addEvent(newEvent);
                    if (success && dialogCtx.mounted) {
                      await dialogCtx.read<NotificationProvider>().sendSystemNotification(
                        title: 'New Upcoming Event',
                        body: '${newEvent.title} on ${newEvent.date} at ${newEvent.location}',
                        routingPath: AppRoutes.home,
                      );
                    }
                  } else {
                    success = await context.read<EventProvider>().updateEvent(newEvent);
                  }

                  if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 17. Ads Carousel Management
  // ==========================================

  Widget _buildAdsView(BuildContext context) {
    final adProv = context.watch<AdProvider>();
    final ads = adProv.adsList;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Promotional Banner Ads (${ads.length})', style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Manage banner ads and promotional carousels displayed on member mobile home screens.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
                onPressed: () => _showAdDialog(context),
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Add New Ad'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          adProv.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : ads.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No promotional ads added yet.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ads.length,
                      itemBuilder: (context, index) {
                        final ad = ads[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderLg,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 120,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.borderMd,
                                  color: Colors.grey.shade100,
                                  image: ad.imageUrl.isNotEmpty
                                      ? (ad.imageUrl.startsWith('http')
                                          ? DecorationImage(image: NetworkImage(ad.imageUrl), fit: BoxFit.cover)
                                          : DecorationImage(image: MemoryImage(base64Decode(ad.imageUrl)), fit: BoxFit.cover))
                                      : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Banner Ad #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (ad.targetUrl != null && ad.targetUrl!.isNotEmpty)
                                      Text('Target URL: ${ad.targetUrl}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                    Text('Created: ${ad.createdAt.split("T").first}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAdDialog(context, ad: ad),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _confirmDelete(
                                  context,
                                  title: 'Delete Ad',
                                  content: 'Are you sure you want to delete this ad?',
                                  onConfirm: () => adProv.deleteAd(ad),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  void _showAdDialog(BuildContext context, {AdModel? ad}) {
    final formKey = GlobalKey<FormState>();
    final urlCtrl = TextEditingController(text: ad?.targetUrl ?? '');
    Uint8List? fileBytes;
    String? existingImageUrl = ad?.imageUrl;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(ad == null ? 'Add Promotional Ad' : 'Edit Ad'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                      if (img != null) {
                        final bytes = await img.readAsBytes();
                        setDialogState(() => fileBytes = bytes);
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: fileBytes != null
                          ? Image.memory(fileBytes!, fit: BoxFit.cover)
                          : (existingImageUrl != null && existingImageUrl.isNotEmpty
                              ? (existingImageUrl.startsWith('http')
                                  ? Image.network(existingImageUrl, fit: BoxFit.cover)
                                  : Image.memory(base64Decode(existingImageUrl), fit: BoxFit.cover))
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 36, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Pick banner image *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(labelText: 'Target Link / URL (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (ad == null && fileBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an ad banner image.')));
                    return;
                  }

                  final newAd = AdModel(
                    id: ad?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    imageUrl: ad?.imageUrl ?? '',
                    targetUrl: urlCtrl.text.trim().isNotEmpty ? urlCtrl.text.trim() : null,
                    createdAt: ad?.createdAt ?? DateTime.now().toIso8601String(),
                  );

                  bool success;
                  if (ad == null) {
                    success = await context.read<AdProvider>().addAd(newAd, fileBytes!);
                  } else {
                    success = await context.read<AdProvider>().updateAd(newAd, fileBytes);
                  }

                  if (success && dialogCtx.mounted) Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 18. Settings & Configuration
  // ==========================================

  Widget _buildSettingsView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portal Configuration', style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Configure administration policies, validation rules, and offline systems.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: AppSpacing.xl),

          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [

                ListTile(
                  title: const Text('Security Clearance Level', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandSecondary)),
                  subtitle: const Text('Root clearance required to modify administrative authority'),
                  trailing: DropdownButton<String>(
                    value: _clearanceLevel,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'General', child: Text('General')),
                      DropdownMenuItem(value: 'Supervisor', child: Text('Supervisor')),
                      DropdownMenuItem(value: 'State Committee', child: Text('State Committee')),
                      DropdownMenuItem(value: 'Superadmin', child: Text('Superadmin (Root)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _clearanceLevel = val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Helper Confirm Delete Dialog
  // ==========================================

  void _confirmDelete(BuildContext context, {required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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
}
