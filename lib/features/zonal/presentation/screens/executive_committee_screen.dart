import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../../../../core/utils/committee_helper.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../admin/presentation/widgets/add_committee_member_dialog.dart';

/// ExecutiveCommitteeScreen renders the list of Executive Committee members.
class ExecutiveCommitteeScreen extends StatefulWidget {
  const ExecutiveCommitteeScreen({super.key});

  @override
  State<ExecutiveCommitteeScreen> createState() => _ExecutiveCommitteeScreenState();
}

class _ExecutiveCommitteeScreenState extends State<ExecutiveCommitteeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchApprovedUsers();
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
    final isAdmin = adminProvider.currentAdmin != null;

    final execMembers = adminProvider.approvedUsers.where((m) {
      return CommitteeHelper.isExecutiveCommitteeMember(m);
    }).toList();

    final sortedMembers = CommitteeHelper.sortMembers(execMembers, false);

    final filteredMembers = sortedMembers.where((m) {
      final query = _searchQuery.toLowerCase();
      final displayDes = CommitteeHelper.getDisplayDesignation(m, false).toLowerCase();
      return m.name.toLowerCase().contains(query) ||
          displayDes.contains(query) ||
          m.phoneNumber.toLowerCase().contains(query) ||
          (m.zone ?? '').toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: 'Executive Committee Members',
        subtitle: 'Executive Office Bearers & Committee Leaders',
        rightIcon: Icons.stars_outlined,
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
            // Search Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search executive members by name, designation, zone...',
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
                                        ? 'No executive members match search' 
                                        : 'No Executive Committee members found',
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

                                final displayDesignation = CommitteeHelper.getDisplayDesignation(m, false);

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
                                                displayDesignation,
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
                                        if (isAdmin)
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                                            tooltip: 'Remove from Executive Committee',
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Remove from Executive Committee?'),
                                                  content: Text('Are you sure you want to remove ${m.name} ($displayDesignation) from the Executive Committee?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      child: const Text('Remove', style: TextStyle(color: Colors.white)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true && context.mounted) {
                                                await adminProvider.removeMemberFromCommittee(uid: m.uid, isState: false);
                                              }
                                            },
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
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.brandPrimary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => AddCommitteeMemberDialog.show(context, isState: false),
            )
          : null,
    );
  }
}
