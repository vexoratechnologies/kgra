import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/compact_app_bar.dart';
/// ZonalCommitteeScreen renders the list of zonal committee members for members.
class ZonalCommitteeScreen extends StatefulWidget {
  const ZonalCommitteeScreen({super.key});

  @override
  State<ZonalCommitteeScreen> createState() => _ZonalCommitteeScreenState();
}

class _ZonalCommitteeScreenState extends State<ZonalCommitteeScreen> {
  String? _selectedZone;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchApprovedUsers();
      context.read<AdminProvider>().fetchZones();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    final zonalMembers = adminProvider.approvedUsers.where((m) {
      final des = m.designation?.trim().toLowerCase() ?? '';
      return des == 'zonal committee member';
    }).toList();
    
    bool isNonZonal(String z) {
      final l = z.trim().toLowerCase();
      return l.isEmpty ||
          l == 'all' ||
          l == 'state' ||
          l.contains('executive');
    }

    String formatZoneName(String z) {
      final trimmed = z.trim();
      if (trimmed.isEmpty) return '';
      return trimmed.split(' ').map((word) {
        if (word.isEmpty) return '';
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }).join(' ');
    }

    final Map<String, String> uniqueZones = {};
    for (final z in adminProvider.zones) {
      if (!isNonZonal(z)) {
        uniqueZones.putIfAbsent(z.trim().toLowerCase(), () => formatZoneName(z));
      }
    }
    for (final m in zonalMembers) {
      final mZone = m.zone ?? '';
      if (!isNonZonal(mZone)) {
        uniqueZones.putIfAbsent(mZone.trim().toLowerCase(), () => formatZoneName(mZone));
      }
    }
    final zones = uniqueZones.values.toList()..sort();

    // Automatically select 'All' if not selected yet
    _selectedZone ??= 'All';

    final filteredMembers = zonalMembers.where((m) {
      final matchesZone = _selectedZone == 'All' ||
          (m.zone?.trim().toLowerCase() == _selectedZone?.trim().toLowerCase());
      final matchesQuery = m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m.designation ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.phoneNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m.zone ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesZone && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: 'Zonal Committee Members',
        subtitle: 'Zonal office bearers & leaders',
        rightIcon: Icons.map_outlined,
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Zone Selector Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    'Select Zone / Committee: ',
                    style: AppTextStyle.bodySm().copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: ['All', ...zones].any((z) => z.toLowerCase() == _selectedZone?.toLowerCase())
                          ? ['All', ...zones].firstWhere((z) => z.toLowerCase() == _selectedZone?.toLowerCase())
                          : 'All',
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['All', ...zones].map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: (val) => setState(() => _selectedZone = val),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: _selectedZone == 'All' ? 'Search all zonal members...' : 'Search members in this zone...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.brandSecondary.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderMd,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: adminProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
                  : adminProvider.error != null
                      ? Center(child: Text(adminProvider.error!, style: const TextStyle(color: AppColors.error)))
                      : filteredMembers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty 
                                        ? 'No members match search' 
                                        : (_selectedZone == 'All' ? 'No Zonal Committee members found' : 'No Zonal Committee members in this zone'),
                                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filteredMembers.length,
                              itemBuilder: (context, index) {
                                final m = filteredMembers[index];
                                if (m.profileImageId != null &&
                                    m.profileImageId!.isNotEmpty &&
                                    !adminProvider.userImages.containsKey(m.uid)) {
                                  adminProvider.fetchUserImage(m.profileImageId!, m.uid);
                                }
                                final imgBase64 = adminProvider.userImages[m.uid];
                                ImageProvider? imageProvider;
                                if (m.profileImageId != null && m.profileImageId!.startsWith('http')) {
                                  imageProvider = NetworkImage(m.profileImageId!);
                                } else if (imgBase64 != null && imgBase64.isNotEmpty) {
                                  try {
                                    imageProvider = MemoryImage(base64Decode(imgBase64));
                                  } catch (_) {}
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.06),
                                          backgroundImage: imageProvider,
                                          child: imageProvider == null
                                              ? Text(
                                                  m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                                  style: const TextStyle(
                                                    color: AppColors.brandPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.name,
                                                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${m.designation ?? "Zonal Committee Member"} | Zone: ${m.zone ?? "N/A"}',
                                                style: const TextStyle(
                                                  color: AppColors.brandPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 4,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.phone, size: 14, color: AppColors.onSurfaceVariant),
                                                      const SizedBox(width: 4),
                                                      Text(m.phoneNumber, style: const TextStyle(fontSize: 12, color: AppColors.brandSecondary)),
                                                    ],
                                                  ),
                                                  if (m.zone != null && m.zone!.isNotEmpty)
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.map_outlined, size: 14, color: AppColors.onSurfaceVariant),
                                                        const SizedBox(width: 4),
                                                        Text(m.zone!, style: const TextStyle(fontSize: 12, color: AppColors.brandSecondary)),
                                                      ],
                                                    ),
                                                ],
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
      ),
    );
  }
}
