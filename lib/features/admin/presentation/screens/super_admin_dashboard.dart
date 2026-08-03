import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../auth/data/models/admin_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../meeting_minutes/presentation/providers/meeting_minutes_provider.dart';
import '../../../meeting_minutes/data/models/meeting_minutes_model.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../zonal/presentation/providers/zonal_provider.dart';
import '../../../zonal/data/models/zonal_member_model.dart';
import '../providers/admin_provider.dart';
import '../../../ads/presentation/providers/ad_provider.dart';
import '../../../ads/data/models/ad_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

/// SuperAdminDashboard renders the super administrative operations panel.
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  String _activeTab = 'All Members';
  final _adminFormKey = GlobalKey<FormState>();
  final _zoneFormKey = GlobalKey<FormState>();
  final _designationFormKey = GlobalKey<FormState>();
  
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  String? _selectedAdminZone;
  final _zoneNameController = TextEditingController();
  final _designationNameController = TextEditingController();
  final _userSearchController = TextEditingController();
  final _committeeSearchController = TextEditingController();
  String _userSearchQuery = '';
  String _statusFilter = 'All Statuses';
  String _committeeZoneFilter = 'All';
  String _committeeSearchQuery = '';
  String? _expandedUserUid;

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
    context.read<MeetingMinutesProvider>().fetchAllMinutes();
    context.read<AdProvider>().fetchAds(force: true);
    context.read<ZonalProvider>().fetchMembers();
  }

  void _onTabChanged(String label) {
    final adminProv = context.read<AdminProvider>();
    if (label == 'Ads Carousel') {
      context.read<AdProvider>().fetchAds(force: true);
    } else if (label == 'Zonal Admins') {
      adminProv.fetchAdmins();
    } else if (label == 'Zones') {
      adminProv.fetchZones();
    } else if (label == 'Designations') {
      adminProv.fetchDesignations();
    } else if (label == 'Minutes Approvals') {
      context.read<MeetingMinutesProvider>().fetchAllMinutes();
    } else if (label == 'All Members') {
      adminProv.fetchPendingUsers();
      adminProv.fetchApprovedUsers();
      adminProv.fetchRejectedUsers();
    } else if (label == 'Pending Approvals') {
      adminProv.fetchPendingUsers();
    } else if (label == 'Approved Members') {
      adminProv.fetchApprovedUsers();
    } else if (label == 'Rejected Requests') {
      adminProv.fetchRejectedUsers();
    } else if (label == 'Committee Members') {
      context.read<ZonalProvider>().fetchMembers();
      adminProv.fetchZones();
      adminProv.fetchDesignations();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final minutesProvider = context.watch<MeetingMinutesProvider>();
    
    final currentAdmin = adminProvider.currentAdmin;
    if (currentAdmin == null || currentAdmin.role != 'super_admin') {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pendingMinutes = minutesProvider.minutesList
        .where((m) => m.status == 'pending')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow, // Background Gutter
      body: SafeArea(
        child: Row(
          children: [
            // Fixed dark sidebar (bg-inverse-surface) on the far left.
            _buildSidebar(context),
            
            // Background Gutter and Main Content Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header Frame
                    _buildHeaderFrame(context),
                    const SizedBox(height: 16),
                    // Main Frame
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
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: _buildTabContent(adminProvider, pendingMinutes),
                        ),
                      ),
                    ),
                  ],
                ),
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
                child: Icon(Icons.security, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Super Admin',
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

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220, // Slimmer profile
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow, // Soft background
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
                      'Super Admin',
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
                _buildSidebarItem('All Members', Icons.groups_outlined),
                _buildSidebarItem('Pending Approvals', Icons.hourglass_top_outlined),
                _buildSidebarItem('Approved Members', Icons.verified_user_outlined),
                _buildSidebarItem('Rejected Requests', Icons.cancel_outlined),
                _buildSidebarItem('Committee Members', Icons.account_box_outlined),
                _buildSidebarItem('Zonal Admins', Icons.people_outline),
                _buildSidebarItem('Zones', Icons.map_outlined),
                _buildSidebarItem('Designations', Icons.badge_outlined),
                _buildSidebarItem('Minutes Approvals', Icons.approval_outlined),
                _buildSidebarItem('Ads Carousel', Icons.photo_library_outlined),
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

  Widget _buildSidebarItem(String label, IconData icon) {
    final isSelected = _activeTab == label;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () {
              setState(() => _activeTab = label);
              _onTabChanged(label);
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

  Widget _buildTabContent(AdminProvider adminProvider, List<MeetingMinutesModel> pendingMinutes) {
    switch (_activeTab) {
      case 'All Members':
        return _buildSuperAdminUsersView(context, 'all', adminProvider);
      case 'Pending Approvals':
        return _buildSuperAdminUsersView(context, 'pending', adminProvider);
      case 'Approved Members':
        return _buildSuperAdminUsersView(context, 'approved', adminProvider);
      case 'Rejected Requests':
        return _buildSuperAdminUsersView(context, 'rejected', adminProvider);
      case 'Committee Members':
        return _buildCommitteeMembersView(adminProvider);
      case 'Zonal Admins':
        return _buildZonalAdminsView(adminProvider);
      case 'Zones':
        return _buildZonesView(adminProvider);
      case 'Designations':
        return _buildDesignationsView(adminProvider);
      case 'Minutes Approvals':
        return _buildMinutesApprovalsView(pendingMinutes);
      case 'Ads Carousel':
        return _buildAdsView(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildZonalAdminsView(AdminProvider adminProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Create Admin Form
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Form(
              key: _adminFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create Zonal Admin',
                    style: AppTextStyle.headlineSm(color: AppColors.brandPrimary).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Text('Username', style: AppTextStyle.labelSm(color: AppColors.brandSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _adminUsernameController,
                    decoration: const InputDecoration(hintText: 'Enter username'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Username required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Text('Password', style: AppTextStyle.labelSm(color: AppColors.brandSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _adminPasswordController,
                    decoration: const InputDecoration(hintText: 'Enter password'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Password required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Text('Assign Zone', style: AppTextStyle.labelSm(color: AppColors.brandSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    value: _selectedAdminZone,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    items: adminProvider.zones.map((zone) {
                      return DropdownMenuItem(value: zone, child: Text(zone));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAdminZone = val),
                    hint: const Text('Select a zone'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleAddAdmin,
                      child: const Text('Create Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        
        // Admins List
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zonal Administrators',
                  style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: adminProvider.admins.isEmpty
                      ? const Center(child: Text('No zonal admins found.'))
                      : ListView.builder(
                          itemCount: adminProvider.admins.length,
                          itemBuilder: (context, index) {
                            final admin = adminProvider.admins[index];
                            if (admin.role == 'super_admin') return const SizedBox.shrink();
                            
                            return ListTile(
                              title: Text(admin.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Zone: ${admin.zone ?? "None"}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () => adminProvider.deleteAdmin(admin.username),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZonesView(AdminProvider adminProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Create Zone Form
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Form(
              key: _zoneFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Zone',
                    style: AppTextStyle.headlineSm(color: AppColors.brandPrimary).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Text('Zone Name', style: AppTextStyle.labelSm(color: AppColors.brandSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _zoneNameController,
                    decoration: const InputDecoration(hintText: 'e.g. North Zone'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Zone name required';
                      }
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) {
                        return 'Zone name must contain alphabets only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleAddZone,
                      child: const Text('Add Zone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        
        // Zones List
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Zones',
                  style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: adminProvider.zones.isEmpty
                      ? const Center(child: Text('No active zones found.'))
                      : ListView.builder(
                          itemCount: adminProvider.zones.length,
                          itemBuilder: (context, index) {
                            final zone = adminProvider.zones[index];
                            return ListTile(
                              title: Text(zone, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () => adminProvider.deleteZone(zone),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinutesApprovalsView(List<MeetingMinutesModel> pendingMinutes) {
    final minutesProvider = context.read<MeetingMinutesProvider>();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Minutes Approval',
            style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: pendingMinutes.isEmpty
                ? const Center(child: Text('No pending meeting minutes.'))
                : ListView.builder(
                    itemCount: pendingMinutes.length,
                    itemBuilder: (context, index) {
                      final m = pendingMinutes[index];
                      return ListTile(
                        title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Date: ${m.date}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12)),
                              onPressed: () async {
                                // Approve: Set pdfName (which holds status in current model or custom updates) to 'approved'
                                await minutesProvider.updateMinutesStatus(m.id, 'approved');
                                if (context.mounted) {
                                  await context.read<NotificationProvider>().sendSystemNotification(
                                    title: 'Meeting Minutes Approved',
                                    body: 'New meeting minutes "${m.title}" are now available.',
                                    routingPath: AppRoutes.meetingMinutes,
                                  );
                                }
                                _refreshData();
                              },
                              child: const Text('Approve', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: 12)),
                              onPressed: () async {
                                // Reject
                                await minutesProvider.updateMinutesStatus(m.id, 'rejected');
                                _refreshData();
                              },
                              child: const Text('Reject', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsView(BuildContext context) {
    final provider = context.watch<AdProvider>();
    final ads = provider.adsList;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ads Carousel Management',
                style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showAdDialog(context),
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Add Ad Banner'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
                : provider.error != null
                    ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                    : ads.isEmpty
                        ? const Center(child: Text('No ads banners uploaded.'))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: ads.length,
                            itemBuilder: (context, index) {
                              final ad = ads[index];
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: AppRadius.borderMd,
                                ),
                                child: ClipRRect(
                                  borderRadius: AppRadius.borderMd,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        ad.imageUrl,
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
                                                onPressed: () => _showAdDialog(context, ad: ad),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Colors.white.withValues(alpha: 0.9),
                                              child: IconButton(
                                                icon: const Icon(Icons.delete, size: 12, color: AppColors.error),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text('Delete Ad banner'),
                                                      content: const Text('Are you sure you want to delete this ad?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    await provider.deleteAd(ad);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
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
      ),
    );
  }

  void _showAdDialog(BuildContext context, {AdModel? ad}) {
    final formKey = GlobalKey<FormState>();
    Uint8List? imageBytes;
    String? originalFileName;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(ad == null ? 'Upload Ad Banner' : 'Update Ad Banner'),
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
                          height: 120,
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
                              : (ad != null
                                  ? ClipRRect(
                                      borderRadius: AppRadius.borderMd,
                                      child: Image.network(
                                        ad.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, size: 36, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Select Ad Image *', style: TextStyle(color: Colors.grey)),
                                      ],
                                    )),
                        ),
                      ),
                      if (originalFileName != null) ...[
                        const SizedBox(height: 8),
                        Text('Selected: $originalFileName', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
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
                            if (ad == null && imageBytes == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select an image.')),
                              );
                              return;
                            }
                            setDialogState(() {
                              isSaving = true;
                            });
                            
                            final newAd = AdModel(
                              id: ad?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              imageUrl: ad?.imageUrl ?? '',
                              targetUrl: null, // Target URL removed
                              createdAt: ad?.createdAt ?? DateTime.now().toIso8601String(),
                            );

                            final adProvider = context.read<AdProvider>();
                            bool success;
                            if (ad == null) {
                              success = await adProvider.addAd(newAd, imageBytes!);
                            } else {
                              success = await adProvider.updateAd(newAd, imageBytes);
                            }
                            
                            if (success && dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _refreshData();
                            } else {
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(content: Text(adProvider.error ?? 'Failed to save ad banner.')),
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

  Widget _buildDesignationsView(AdminProvider adminProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Designation Form
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Form(
              key: _designationFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Designation',
                    style: AppTextStyle.headlineSm(color: AppColors.brandPrimary).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Text('Designation Name', style: AppTextStyle.labelSm(color: AppColors.brandSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _designationNameController,
                    decoration: const InputDecoration(hintText: 'e.g. President'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Designation name required' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleAddDesignation,
                      child: const Text('Add Designation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        
        // Designations List
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Designations',
                  style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: adminProvider.designations.isEmpty
                      ? const Center(child: Text('No active designations found.'))
                      : ListView.builder(
                          itemCount: adminProvider.designations.length,
                          itemBuilder: (context, index) {
                            final designation = adminProvider.designations[index];
                            return ListTile(
                              title: Text(designation, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () => adminProvider.deleteDesignation(designation),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuperAdminUsersView(BuildContext context, String status, AdminProvider adminProvider) {
    List<UserModel> usersList;
    if (status == 'pending') {
      usersList = adminProvider.pendingUsers;
    } else if (status == 'approved') {
      usersList = adminProvider.approvedUsers;
    } else if (status == 'rejected') {
      usersList = adminProvider.rejectedUsers;
    } else {
      final map = <String, UserModel>{};
      for (final u in adminProvider.pendingUsers) {
        map[u.uid] = u;
      }
      for (final u in adminProvider.approvedUsers) {
        map[u.uid] = u;
      }
      for (final u in adminProvider.rejectedUsers) {
        map[u.uid] = u;
      }
      usersList = map.values.toList();
    }

    final query = _userSearchQuery.trim().toLowerCase();
    final selectedZone = adminProvider.selectedZoneFilter;

    final filteredUsers = usersList.where((u) {
      if (status == 'all' && _statusFilter != 'All Statuses') {
        if (u.status.toLowerCase() != _statusFilter.toLowerCase()) {
          return false;
        }
      }
      if (selectedZone != 'All Zones' && u.zone != selectedZone) {
        return false;
      }
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) ||
          u.phoneNumber.toLowerCase().contains(query) ||
          (u.designation?.toLowerCase().contains(query) ?? false) ||
          (u.institution?.toLowerCase().contains(query) ?? false) ||
          (u.membershipId?.toLowerCase().contains(query) ?? false);
    }).toList();

    String titleText;
    if (status == 'all') {
      titleText = 'All Registered Members (${filteredUsers.length})';
    } else if (status == 'pending') {
      titleText = 'Pending Registration Approvals (${filteredUsers.length})';
    } else if (status == 'approved') {
      titleText = 'Approved Members (${filteredUsers.length})';
    } else {
      titleText = 'Rejected Requests (${filteredUsers.length})';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Filters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titleText,
              style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                if (status == 'all') ...[
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
                        icon: const Icon(Icons.filter_list, size: 18, color: AppColors.brandPrimary),
                        style: const TextStyle(color: AppColors.brandSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                        onChanged: (val) {
                          if (val != null) setState(() => _statusFilter = val);
                        },
                        items: ['All Statuses', 'Pending', 'Approved', 'Rejected']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Zone Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: adminProvider.selectedZoneFilter,
                      icon: const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.brandPrimary),
                      style: const TextStyle(color: AppColors.brandSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      onChanged: (val) {
                        if (val != null) adminProvider.setSelectedZoneFilter(val);
                      },
                      items: ['All Zones', ...adminProvider.zones].map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Search TextField
                SizedBox(
                  width: 260,
                  height: 42,
                  child: TextField(
                    controller: _userSearchController,
                    onChanged: (val) => setState(() => _userSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _userSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                setState(() {
                                  _userSearchQuery = '';
                                  _userSearchController.clear();
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: AppRadius.borderMd),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // User Items List
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No $status members found.',
                        style: const TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isExpanded = _expandedUserUid == user.uid;
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderLg,
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary Bar
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
                                    child: Text(
                                      user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: user.isApproved ? Colors.green.withValues(alpha: 0.1) : (user.status == 'rejected' ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                user.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: user.isApproved ? Colors.green : (user.status == 'rejected' ? Colors.red : Colors.orange),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('${user.designation ?? "Member"} • Zone: ${user.zone ?? "Not Specified"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                                    onPressed: () {
                                      setState(() {
                                        _expandedUserUid = isExpanded ? null : user.uid;
                                      });
                                      if (!isExpanded && user.profileImageId != null) {
                                        adminProvider.fetchUserImage(user.profileImageId!, user.uid);
                                      }
                                    },
                                  ),
                                  if (user.status == 'pending') ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      onPressed: () async {
                                        final ok = await adminProvider.approveUser(user.uid);
                                        if (ok && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${user.name} approved successfully')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                                      label: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      onPressed: () async {
                                        final ok = await adminProvider.rejectUser(user.uid);
                                        if (ok && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${user.name} request rejected')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                      label: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ),

                              // Expanded Profile Details Card
                              if (isExpanded) ...[
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(child: _buildUserDetailTile(Icons.phone, 'Mobile', user.phoneNumber)),
                                    Expanded(child: _buildUserDetailTile(Icons.cake_outlined, 'Date of Birth', user.dateOfBirth ?? 'Not Provided')),
                                    Expanded(child: _buildUserDetailTile(Icons.event_outlined, 'Date of Join', user.dateOfJoin ?? 'Not Provided')),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildUserDetailTile(Icons.card_membership_outlined, 'Member ID', user.membershipId ?? 'Not Provided')),
                                    Expanded(child: _buildUserDetailTile(Icons.work_off_outlined, 'Date of Retirement', user.dateOfRetirement ?? 'Not Provided')),
                                    Expanded(child: _buildUserDetailTile(Icons.business_outlined, 'Institution', user.institution ?? 'Not Provided')),
                                  ],
                                ),
                                if (user.reviewedByName != null || user.reviewedById != null || user.reviewedAt != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildUserDetailTile(
                                          Icons.verified_user_outlined,
                                          user.status == 'approved' ? 'Approved By' : (user.status == 'rejected' ? 'Rejected By' : 'Reviewed By'),
                                          '${user.reviewedByName ?? "Admin"}${user.reviewedById != null ? " (ID: ${user.reviewedById})" : ""}',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildUserDetailTile(
                                          Icons.access_time_outlined,
                                          'Reviewed At',
                                          user.reviewedAt ?? 'Not Provided',
                                        ),
                                      ),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ],
                                if (user.profileImageId != null) ...[
                                  const SizedBox(height: 16),
                                  const Text('Submitted Profile Photo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Builder(
                                    builder: (context) {
                                      final imgBase64 = adminProvider.userImages[user.uid];
                                      if (user.profileImageId!.startsWith('http')) {
                                        return ClipRRect(
                                          borderRadius: AppRadius.borderMd,
                                          child: Image.network(user.profileImageId!, width: 120, height: 120, fit: BoxFit.cover),
                                        );
                                      } else if (imgBase64 != null) {
                                        return ClipRRect(
                                          borderRadius: AppRadius.borderMd,
                                          child: Image.memory(base64Decode(imgBase64), width: 120, height: 120, fit: BoxFit.cover),
                                        );
                                      } else {
                                        return const SizedBox(width: 120, height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                                      }
                                    },
                                  ),
                                ],
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

  Widget _buildUserDetailTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brandPrimary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommitteeMembersView(AdminProvider adminProvider) {
    final zonalProv = context.watch<ZonalProvider>();
    final members = zonalProv.members;
    final zones = adminProvider.zones;

    final filtered = members.where((m) {
      final matchesZone = _committeeZoneFilter == 'All' || m.zone == _committeeZoneFilter;
      final matchesQuery = _committeeSearchQuery.isEmpty ||
          m.name.toLowerCase().contains(_committeeSearchQuery.toLowerCase()) ||
          m.designation.toLowerCase().contains(_committeeSearchQuery.toLowerCase());
      return matchesZone && matchesQuery;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Executive & Zonal Committee (${filtered.length})',
              style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
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
                      icon: const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.brandPrimary),
                      style: const TextStyle(color: AppColors.brandSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      onChanged: (val) {
                        if (val != null) setState(() => _committeeZoneFilter = val);
                      },
                      items: ['All', ...zones].map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  height: 42,
                  child: TextField(
                    controller: _committeeSearchController,
                    onChanged: (val) => setState(() => _committeeSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search leaders...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: AppRadius.borderMd),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => _showCommitteeMemberDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Member'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        Expanded(
          child: zonalProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('No committee members found.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final member = filtered[index];
                        final isExec = member.zone == 'Executive Committee';
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderLg,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isExec ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.grey.shade100,
                                backgroundImage: member.photoBase64 != null
                                    ? MemoryImage(base64Decode(member.photoBase64!))
                                    : null,
                                child: member.photoBase64 == null
                                    ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : 'C',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isExec ? AppColors.brandPrimary : Colors.grey))
                                    : null,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isExec ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            member.zone.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isExec ? AppColors.brandPrimary : Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${member.designation} • ${member.phoneNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.brandPrimary, size: 20),
                                onPressed: () => _showCommitteeMemberDialog(context, member: member),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                onPressed: () async {
                                  final ok = await zonalProv.deleteMember(member.id);
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${member.name} removed')),
                                    );
                                  }
                                },
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

  void _showCommitteeMemberDialog(BuildContext context, {ZonalMemberModel? member}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final phoneCtrl = TextEditingController(text: member?.phoneNumber ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    String? selectedZone = member?.zone;
    String? photoBase64 = member?.photoBase64;
    final designations = context.read<AdminProvider>().designations;
    String? selectedDesignation = member?.designation;
    if (selectedDesignation == null && designations.isNotEmpty) {
      selectedDesignation = designations.first;
    }

    final zones = context.read<AdminProvider>().zones;
    if (selectedZone == null && zones.isNotEmpty) {
      selectedZone = zones.first;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(member == null ? 'Add Committee Member' : 'Edit Committee Member'),
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
                          radius: 36,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64!)) : null,
                          child: photoBase64 == null
                              ? const Icon(Icons.add_a_photo, size: 28, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      DropdownButtonFormField<String>(
                        value: selectedZone,
                        decoration: const InputDecoration(labelText: 'Zone / Committee *'),
                        items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                        onChanged: (val) => setDialogState(() => selectedZone = val),
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
                      final newMember = ZonalMemberModel(
                        id: member?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        designation: selectedDesignation ?? '',
                        phoneNumber: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        zone: selectedZone!,
                        photoBase64: photoBase64,
                        createdAt: member?.createdAt ?? DateTime.now().toIso8601String(),
                      );
                      bool success;
                      if (member == null) {
                        success = await context.read<ZonalProvider>().addMember(newMember);
                      } else {
                        success = await context.read<ZonalProvider>().updateMember(newMember);
                      }
                      if (success && dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(member == null ? 'Committee member added' : 'Committee member updated')),
                        );
                      }
                    }
                  },
                  child: Text(member == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
