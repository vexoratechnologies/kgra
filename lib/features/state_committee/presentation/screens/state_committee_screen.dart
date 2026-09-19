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
import '../../../admin/presentation/providers/admin_provider.dart';

class StateCommitteeScreen extends StatefulWidget {
  const StateCommitteeScreen({super.key});

  @override
  State<StateCommitteeScreen> createState() => _StateCommitteeScreenState();
}

class _StateCommitteeScreenState extends State<StateCommitteeScreen> {
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
    final stateMembers = adminProvider.approvedUsers.where((m) {
      final des = m.designation?.trim().toLowerCase() ?? '';
      return des == 'state committee member';
    }).toList();

    final filteredMembers = stateMembers.where((m) {
      final query = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(query) ||
          (m.designation ?? '').toLowerCase().contains(query) ||
          m.phoneNumber.toLowerCase().contains(query) ||
          (m.zone ?? '').toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: 'State Committee Members',
        subtitle: 'Office bearers & committee leaders',
        rightIcon: Icons.people_outline,
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
                  hintText: 'Search members by name, designation, zone...',
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
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(adminProvider.error!, style: const TextStyle(color: AppColors.error)),
                          ),
                        )
                      : filteredMembers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No members match your search' : 'No State Committee members found',
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(color: Colors.grey.shade100),
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
                                                m.designation ?? 'State Committee Member',
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
