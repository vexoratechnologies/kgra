import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/committee_helper.dart';
import '../../../auth/data/models/user_model.dart';
import '../providers/admin_provider.dart';

/// AddCommitteeMemberDialog enables admins to search approved members,
/// inspect their existing committee status, and assign a committee designation
/// to the State Committee, Executive Committee, or Zonal Committee.
class AddCommitteeMemberDialog extends StatefulWidget {
  final bool isState;
  final CommitteeType committeeType;
  final String? initialZone;

  const AddCommitteeMemberDialog({
    super.key,
    this.isState = true,
    required this.committeeType,
    this.initialZone,
  });

  static Future<void> show(
    BuildContext context, {
    bool? isState,
    CommitteeType? committeeType,
    String? targetZone,
  }) {
    final effectiveType =
        committeeType ??
        (isState == true ? CommitteeType.state : CommitteeType.executive);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCommitteeMemberDialog(
        isState: effectiveType == CommitteeType.state,
        committeeType: effectiveType,
        initialZone: targetZone,
      ),
    );
  }

  @override
  State<AddCommitteeMemberDialog> createState() =>
      _AddCommitteeMemberDialogState();
}

class _AddCommitteeMemberDialogState extends State<AddCommitteeMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserModel? _selectedUser;
  bool _isSaving = false;
  late String? _selectedZoneFilter;

  @override
  void initState() {
    super.initState();
    final init = widget.initialZone?.trim();
    if (init != null && init.isNotEmpty && init.toLowerCase() != 'all') {
      _selectedZoneFilter = init;
    } else {
      _selectedZoneFilter = 'All';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final approvedUsers = adminProvider.approvedUsers;

    // Collect available zones for Zonal filtering
    final Set<String> zonesSet = {};
    for (final z in adminProvider.zones) {
      final clean = z.trim();
      final l = clean.toLowerCase();
      if (clean.isNotEmpty &&
          l != 'all' &&
          l != 'state' &&
          !l.contains('executive')) {
        zonesSet.add(clean);
      }
    }
    for (final u in approvedUsers) {
      final z = u.zone?.trim();
      if (z != null &&
          z.isNotEmpty &&
          z.toLowerCase() != 'all' &&
          !z.toLowerCase().contains('executive')) {
        zonesSet.add(z);
      }
    }
    final availableZones = zonesSet.toList()..sort();

    // Filter approved users by search and zone filter (if Zonal)
    final query = _searchQuery.trim().toLowerCase();
    final filteredUsers = approvedUsers.where((u) {
      if (widget.committeeType == CommitteeType.zonal &&
          _selectedZoneFilter != null &&
          _selectedZoneFilter != 'All') {
        if (!CommitteeHelper.matchesZone(u.zone, _selectedZoneFilter)) {
          return false;
        }
      }

      if (query.isEmpty) return true;
      final nameMatches = u.name.toLowerCase().contains(query);
      final phoneMatches = u.phoneNumber.toLowerCase().contains(query);
      final zoneMatches = (u.zone ?? '').toLowerCase().contains(query);
      final desMatches = u.allDesignations.any(
        (d) => d.toLowerCase().contains(query),
      );
      return nameMatches || phoneMatches || zoneMatches || desMatches;
    }).toList();

    String committeeTitle;
    IconData committeeIcon;
    switch (widget.committeeType) {
      case CommitteeType.state:
        committeeTitle = 'State Committee';
        committeeIcon = Icons.account_balance;
        break;
      case CommitteeType.executive:
        committeeTitle = 'Executive Committee';
        committeeIcon = Icons.stars;
        break;
      case CommitteeType.zonal:
        if (_selectedZoneFilter != null && _selectedZoneFilter != 'All') {
          committeeTitle = '$_selectedZoneFilter Zonal Committee';
        } else {
          committeeTitle = 'Zonal Committee';
        }
        committeeIcon = Icons.group_work;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.brandPrimary.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(committeeIcon, color: AppColors.brandPrimary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Member to $committeeTitle',
                          style: AppTextStyle.titleLg(
                            color: AppColors.brandSecondary,
                          ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select an approved member to add to $committeeTitle.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Zone Filter dropdown for Zonal Committee
              if (widget.committeeType == CommitteeType.zonal) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 18,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Zone:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value:
                                [
                                  'All',
                                  ...availableZones,
                                ].contains(_selectedZoneFilter)
                                ? _selectedZoneFilter
                                : 'All',
                            items: ['All', ...availableZones]
                                .map(
                                  (z) => DropdownMenuItem(
                                    value: z,
                                    child: Text(
                                      z,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (val) =>
                                      setState(() => _selectedZoneFilter = val),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Search Box
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, zone...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderMd,
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderMd,
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // List of Approved Users
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No approved members match "$_searchQuery"'
                              : 'No approved members available',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isSelected = _selectedUser?.uid == user.uid;

                          // Check committee membership
                          final isAlreadyInCommittee =
                              widget.committeeType == CommitteeType.state
                              ? CommitteeHelper.isStateCommitteeMember(user)
                              : widget.committeeType == CommitteeType.executive
                              ? CommitteeHelper.isExecutiveCommitteeMember(user)
                              : CommitteeHelper.isZonalCommitteeMember(
                                  user,
                                  user.zone,
                                );

                          final currentDisplayDes =
                              CommitteeHelper.getDisplayDesignation(
                                user,
                                widget.committeeType,
                              );

                          // Profile image
                          final imgBase64 = adminProvider.userImages[user.uid];
                          ImageProvider? imageProvider;
                          if (user.profileImageId != null &&
                              user.profileImageId!.startsWith('http')) {
                            imageProvider = NetworkImage(user.profileImageId!);
                          } else if (imgBase64 != null &&
                              imgBase64.isNotEmpty) {
                            try {
                              imageProvider = MemoryImage(
                                base64Decode(imgBase64),
                              );
                            } catch (_) {}
                          }

                          void onSelect() {
                            if (_isSaving) return;
                            setState(() => _selectedUser = user);
                          }

                          return InkWell(
                            onTap: onSelect,
                            child: Container(
                              color: isSelected
                                  ? AppColors.brandPrimary.withValues(
                                      alpha: 0.08,
                                    )
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: user.uid,
                                    groupValue: _selectedUser?.uid,
                                    activeColor: AppColors.brandPrimary,
                                    onChanged: _isSaving
                                        ? null
                                        : (_) => onSelect(),
                                  ),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.brandSecondary
                                        .withValues(alpha: 0.08),
                                    backgroundImage: imageProvider,
                                    child: imageProvider == null
                                        ? Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.brandPrimary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (isAlreadyInCommittee)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius:
                                                      AppRadius.borderSm,
                                                  border: Border.all(
                                                    color:
                                                        Colors.green.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Already in: $currentDisplayDes',
                                                  style: TextStyle(
                                                    color:
                                                        Colors.green.shade800,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Profile Designation: ${user.designation?.trim().isNotEmpty == true ? user.designation : "Member"}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.brandPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Phone: ${user.phoneNumber} | Zone: ${user.zone ?? "N/A"} | ID: ${user.membershipId ?? "N/A"}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
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

              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMd,
                      ),
                    ),
                    onPressed: (_selectedUser == null || _isSaving)
                        ? null
                        : () async {
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final selectedName = _selectedUser!.name;

                            String defaultRole;
                            switch (widget.committeeType) {
                              case CommitteeType.state:
                                defaultRole = 'State Committee Member';
                                break;
                              case CommitteeType.executive:
                                defaultRole = 'Executive Committee Member';
                                break;
                              case CommitteeType.zonal:
                                defaultRole = 'Zonal Committee Member';
                                break;
                            }

                            final roleToSave =
                                (_selectedUser!.designation != null &&
                                    _selectedUser!.designation!
                                        .trim()
                                        .isNotEmpty)
                                ? _selectedUser!.designation!.trim()
                                : defaultRole;

                            final targetZone =
                                (_selectedUser!.zone != null &&
                                    _selectedUser!.zone!.trim().isNotEmpty)
                                ? _selectedUser!.zone
                                : (_selectedZoneFilter != null &&
                                          _selectedZoneFilter != 'All'
                                      ? _selectedZoneFilter
                                      : null);

                            setState(() => _isSaving = true);
                            final success = await adminProvider
                                .addMemberToCommittee(
                                  uid: _selectedUser!.uid,
                                  type: widget.committeeType,
                                  role: roleToSave,
                                  zone: targetZone,
                                );
                            if (!mounted) return;
                            setState(() => _isSaving = false);

                            if (success) {
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$selectedName added to $committeeTitle.',
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    adminProvider.error ??
                                        'Failed to add member.',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add to Committee'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
