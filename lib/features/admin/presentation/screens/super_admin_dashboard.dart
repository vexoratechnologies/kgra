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
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../injection.dart';
import 'dart:convert';
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
  
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  String? _selectedAdminZone;
  final _zoneNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentAdmin = context.read<AdminProvider>().currentAdmin;
      if (currentAdmin == null || currentAdmin.role != 'super_admin') {
        context.go(AppRoutes.adminLogin);
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
    super.dispose();
  }

  void _refreshData() {
    context.read<AdminProvider>().fetchAdmins();
    context.read<AdminProvider>().fetchZones();
    context.read<MeetingMinutesProvider>().fetchAllMinutes();
    context.read<AdProvider>().fetchAds();
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
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        title: const Text('Super Admin Control Panel'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AdminProvider>().logoutAdmin();
              context.go(AppRoutes.adminLogin);
            },
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar Navigation (Desktop design layout)
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _buildSidebarItem('Zonal Admins', Icons.people_outline),
                  _buildSidebarItem('Zones', Icons.map_outlined),
                  _buildSidebarItem('Minutes Approvals', Icons.approval_outlined),
                  _buildSidebarItem('Ads Carousel', Icons.photo_library_outlined),
                ],
              ),
            ),
            
            // Main Panel Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _buildTabContent(adminProvider, pendingMinutes),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String label, IconData icon) {
    final isSelected = _activeTab == label;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.brandPrimary : AppColors.brandSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.brandPrimary : AppColors.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.brandPrimary.withValues(alpha: 0.05),
      onTap: () => setState(() => _activeTab = label),
    );
  }

  Widget _buildTabContent(AdminProvider adminProvider, List<MeetingMinutesModel> pendingMinutes) {
    switch (_activeTab) {
      case 'Zonal Admins':
        return _buildZonalAdminsView(adminProvider);
      case 'Zones':
        return _buildZonesView(adminProvider);
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
                    validator: (v) => v == null || v.trim().isEmpty ? 'Zone name required' : null,
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
                                      ad.imageUrl.startsWith('mock://')
                                          ? Image.memory(
                                              base64Decode(
                                                locator<SharedPreferences>().getString('mock_storage_ads_${ad.id}') ?? ''
                                              ),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.broken_image);
                                              },
                                            )
                                          : Image.network(
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
    final urlCtrl = TextEditingController(text: ad?.targetUrl ?? '');
    Uint8List? imageBytes;
    String? originalFileName;

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
                        onTap: () async {
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
                                      child: ad.imageUrl.startsWith('mock://')
                                          ? Image.memory(
                                              base64Decode(locator<SharedPreferences>().getString('mock_storage_ads_${ad.id}') ?? ''),
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(ad.imageUrl, fit: BoxFit.cover),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(labelText: 'Target URL (Optional)'),
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
                      if (ad == null && imageBytes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select an image.')),
                        );
                        return;
                      }
                      final newAd = AdModel(
                        id: ad?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        imageUrl: ad?.imageUrl ?? '',
                        targetUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                        createdAt: ad?.createdAt ?? DateTime.now().toIso8601String(),
                      );
                      bool success;
                      if (ad == null) {
                        success = await context.read<AdProvider>().addAd(newAd, imageBytes!);
                      } else {
                        success = await context.read<AdProvider>().updateAd(newAd, imageBytes);
                      }
                      if (success && dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                        _refreshData();
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
