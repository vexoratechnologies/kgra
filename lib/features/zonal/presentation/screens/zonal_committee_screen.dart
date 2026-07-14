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
import '../providers/zonal_provider.dart';

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
      context.read<ZonalProvider>().fetchMembers();
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
    final zonalProvider = context.watch<ZonalProvider>();
    final adminProvider = context.watch<AdminProvider>();
    
    final zones = adminProvider.zones;
    
    // Automatically select the first zone if not selected yet
    if (_selectedZone == null && zones.isNotEmpty) {
      _selectedZone = zones.first;
    }

    final filteredMembers = zonalProvider.members.where((m) {
      final matchesZone = m.zone == _selectedZone;
      final matchesQuery = m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.designation.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesZone && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        title: const Text('Zonal Committee'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                    'Select Zone: ',
                    style: AppTextStyle.bodySm().copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedZone,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
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
                  hintText: 'Search members in this zone...',
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
              child: zonalProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
                  : zonalProvider.error != null
                      ? Center(child: Text(zonalProvider.error!, style: const TextStyle(color: AppColors.error)))
                      : filteredMembers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No members match search' : 'No committee members in this zone',
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
                                          backgroundImage: m.photoBase64 != null
                                              ? MemoryImage(base64Decode(m.photoBase64!))
                                              : null,
                                          child: m.photoBase64 == null
                                              ? const Icon(Icons.person, color: AppColors.brandPrimary, size: 30)
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
                                                m.designation,
                                                style: const TextStyle(
                                                  color: AppColors.brandPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone, size: 14, color: AppColors.onSurfaceVariant),
                                                  const SizedBox(width: 4),
                                                  Text(m.phoneNumber, style: const TextStyle(fontSize: 12, color: AppColors.brandSecondary)),
                                                  if (m.email.isNotEmpty) ...[
                                                    const SizedBox(width: AppSpacing.lg),
                                                    const Icon(Icons.email, size: 14, color: AppColors.onSurfaceVariant),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        m.email,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontSize: 12, color: AppColors.brandSecondary),
                                                      ),
                                                    ),
                                                  ],
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
