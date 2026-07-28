import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../auth/data/models/admin_model.dart';
import '../../../meeting_minutes/presentation/providers/meeting_minutes_provider.dart';
import '../../../meeting_minutes/data/models/meeting_minutes_model.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
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
  String _activeTab = 'Zonal Admins';
  final _adminFormKey = GlobalKey<FormState>();
  final _zoneFormKey = GlobalKey<FormState>();
  final _designationFormKey = GlobalKey<FormState>();
  
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  String? _selectedAdminZone;
  final _zoneNameController = TextEditingController();
  final _designationNameController = TextEditingController();

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
    super.dispose();
  }

  void _refreshData() {
    context.read<AdminProvider>().fetchAdmins();
    context.read<AdminProvider>().fetchZones();
    context.read<AdminProvider>().fetchDesignations();
    context.read<MeetingMinutesProvider>().fetchAllMinutes();
    context.read<AdProvider>().fetchAds(force: true);
  }

  void _onTabChanged(String label) {
    if (label == 'Ads Carousel') {
      context.read<AdProvider>().fetchAds(force: true);
    } else if (label == 'Zonal Admins') {
      context.read<AdminProvider>().fetchAdmins();
    } else if (label == 'Zones') {
      context.read<AdminProvider>().fetchZones();
    } else if (label == 'Designations') {
      context.read<AdminProvider>().fetchDesignations();
    } else if (label == 'Meeting Minutes') {
      context.read<MeetingMinutesProvider>().fetchAllMinutes();
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
}
