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
/// inspect their existing committee status, and assign a committee designation.
class AddCommitteeMemberDialog extends StatefulWidget {
  final bool isState;

  const AddCommitteeMemberDialog({
    super.key,
    required this.isState,
  });

  static Future<void> show(BuildContext context, {required bool isState}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCommitteeMemberDialog(isState: isState),
    );
  }

  @override
  State<AddCommitteeMemberDialog> createState() => _AddCommitteeMemberDialogState();
}

class _AddCommitteeMemberDialogState extends State<AddCommitteeMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserModel? _selectedUser;
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final approvedUsers = adminProvider.approvedUsers;

    // Filter approved users by search
    final query = _searchQuery.trim().toLowerCase();
    final filteredUsers = approvedUsers.where((u) {
      if (query.isEmpty) return true;
      final nameMatches = u.name.toLowerCase().contains(query);
      final phoneMatches = u.phoneNumber.toLowerCase().contains(query);
      final zoneMatches = (u.zone ?? '').toLowerCase().contains(query);
      final desMatches = u.allDesignations.any((d) => d.toLowerCase().contains(query));
      return nameMatches || phoneMatches || zoneMatches || desMatches;
    }).toList();

    final committeeTitle = widget.isState ? 'State Committee' : 'Executive Committee';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
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
                    backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                    child: Icon(
                      widget.isState ? Icons.account_balance : Icons.stars,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Member to $committeeTitle',
                          style: AppTextStyle.titleLg(color: AppColors.brandSecondary)
                              .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select an approved member to add to $committeeTitle.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          final isAlreadyInCommittee = widget.isState
                              ? CommitteeHelper.isStateCommitteeMember(user)
                              : CommitteeHelper.isExecutiveCommitteeMember(user);

                          final currentDisplayDes = CommitteeHelper.getDisplayDesignation(
                            user,
                            widget.isState,
                          );

                          // Profile image
                          final imgBase64 = adminProvider.userImages[user.uid];
                          ImageProvider? imageProvider;
                          if (user.profileImageId != null && user.profileImageId!.startsWith('http')) {
                            imageProvider = NetworkImage(user.profileImageId!);
                          } else if (imgBase64 != null && imgBase64.isNotEmpty) {
                            try {
                              imageProvider = MemoryImage(base64Decode(imgBase64));
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
                                  ? AppColors.brandPrimary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: user.uid,
                                    groupValue: _selectedUser?.uid,
                                    activeColor: AppColors.brandPrimary,
                                    onChanged: _isSaving ? null : (_) => onSelect(),
                                  ),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.08),
                                    backgroundImage: imageProvider,
                                    child: imageProvider == null
                                        ? Text(
                                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: AppRadius.borderSm,
                                                  border: Border.all(color: Colors.green.shade300),
                                                ),
                                                child: Text(
                                                  'Already in: $currentDisplayDes',
                                                  style: TextStyle(
                                                    color: Colors.green.shade800,
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
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    onPressed: (_selectedUser == null || _isSaving)
                        ? null
                        : () async {
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final selectedName = _selectedUser!.name;
                            final roleToSave = (_selectedUser!.designation != null &&
                                    _selectedUser!.designation!.trim().isNotEmpty)
                                ? _selectedUser!.designation!.trim()
                                : (widget.isState
                                    ? 'State Committee Member'
                                    : 'Executive Committee Member');

                            setState(() => _isSaving = true);
                            final success = await adminProvider.addMemberToCommittee(
                              uid: _selectedUser!.uid,
                              isState: widget.isState,
                              role: roleToSave,
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
                                  content: Text(adminProvider.error ?? 'Failed to add member.'),
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
