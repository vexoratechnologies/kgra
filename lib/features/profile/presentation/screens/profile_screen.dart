import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// ProfileScreen displays the member's profile card, personal information,
/// and session management actions matching the custom rose theme UI.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final name = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Member';
    final phone = (user?.phoneNumber != null && user!.phoneNumber.isNotEmpty)
        ? (user.phoneNumber.startsWith('+') ? user.phoneNumber : '+91${user.phoneNumber}')
        : '+918590022047';
    final designation = (user?.designation != null && user!.designation!.isNotEmpty)
        ? user.designation!
        : 'Normal';
    final institution = (user?.institution != null && user!.institution!.isNotEmpty)
        ? user.institution!
        : 'Medical';
    final membershipId = (user?.membershipId != null && user!.membershipId!.isNotEmpty)
        ? user.membershipId!
        : 'KGRA-2026-MEMBER';
    final isApproved = user?.isApproved ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CompactAppBar(
        title: 'Membership',
        subtitle: 'Manage your membership',
        rightIcon: Icons.person_outline,
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ----------------------------------------------------
            // Header Profile Card
            // ----------------------------------------------------
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF0F3),
                    Color(0xFFFDE8EC),
                    Color(0xFFFFF5F7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFFCE7F3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF991B1B).withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle decorative watermark dots top-right
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Opacity(
                      opacity: 0.25,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 15,
                    child: Opacity(
                      opacity: 0.35,
                      child: Row(
                        children: List.generate(
                          5,
                          (i) => Container(
                            margin: const EdgeInsets.all(2),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar with Edit pencil button badge
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.editProfile),
                          child: Stack(
                            children: [
                              Builder(
                                builder: (context) {
                                  Widget? avatarImage;
                                  final profileImageId = user?.profileImageId;
                                  if (profileImageId != null && profileImageId.startsWith('http')) {
                                    avatarImage = Image.network(
                                      profileImageId,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(),
                                    );
                                  } else {
                                    final base64Image = authProvider.currentUserPhotoBase64;
                                    if (base64Image != null && base64Image.isNotEmpty) {
                                      try {
                                        final decodedBytes = base64Decode(base64Image);
                                        avatarImage = Image.memory(
                                          decodedBytes,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(),
                                        );
                                      } catch (_) {}
                                    }
                                  }

                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3.0,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: avatarImage ??
                                          Container(
                                            color: const Color(0xFF1E293B),
                                            child: Center(
                                              child: Text(
                                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),
                                  );
                                },
                              ),
                              // Pencil Edit button badge at bottom right of avatar
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    LucideIcons.pencil,
                                    size: 14,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Text Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Status Badge Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isApproved ? Icons.check_circle : Icons.hourglass_top,
                                      color: isApproved ? const Color(0xFF166534) : const Color(0xFFB45309),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isApproved ? 'APPROVED MEMBER' : 'PENDING APPROVAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isApproved ? const Color(0xFF166534) : const Color(0xFFB45309),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Member ID Section
                              const Text(
                                'Member ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                membershipId,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------
            // Personal Information Card
            // ----------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title Row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          color: Color(0xFF991B1B),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Inner List Card Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem(
                          icon: LucideIcons.phone,
                          label: 'Mobile Number',
                          value: phone,
                          onTap: () => context.push(AppRoutes.editProfile),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoItem(
                          icon: LucideIcons.briefcase,
                          label: 'Designation',
                          value: designation,
                          onTap: () => context.push(AppRoutes.editProfile),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildInfoItem(
                          icon: LucideIcons.home,
                          label: 'Institution',
                          value: institution,
                          onTap: () => context.push(AppRoutes.editProfile),
                        ),
                        if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) ...[
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildInfoItem(
                            icon: LucideIcons.calendar,
                            label: 'Date of Birth',
                            value: AppDateFormatter.formatToDateMonthYear(user.dateOfBirth!),
                            onTap: () => context.push(AppRoutes.editProfile),
                          ),
                        ],
                        if (user?.dateOfJoin != null && user!.dateOfJoin!.isNotEmpty) ...[
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildInfoItem(
                            icon: LucideIcons.calendar,
                            label: 'Date of Join',
                            value: AppDateFormatter.formatToDateMonthYear(user.dateOfJoin!),
                            onTap: () => context.push(AppRoutes.editProfile),
                          ),
                        ],
                        if (user?.dateOfRetirement != null && user!.dateOfRetirement!.isNotEmpty) ...[
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildInfoItem(
                            icon: LucideIcons.calendar,
                            label: 'Date of Retirement',
                            value: AppDateFormatter.formatToDateMonthYear(user.dateOfRetirement!),
                            onTap: () => context.push(AppRoutes.editProfile),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------
            // Sign Out Session Action Card
            // ----------------------------------------------------
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: const Color(0xFFFEE2E2),
                  width: 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.0),
                  onTap: () => _showSignOutDialog(context, authProvider),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.logOut,
                            color: Color(0xFF991B1B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign Out Session',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'You will be logged out from this device',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ----------------------------------------------------
            // Delete Profile Action Card
            // ----------------------------------------------------
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: const Color(0xFFFCA5A5),
                  width: 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.0),
                  onTap: () => _showDeleteProfileDialog(context, authProvider),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delete Profile',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Delete profile and sign out',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF991B1B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        content: const Text(
          'Are you sure you want to sign out from your account?',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteProfileDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
        title: const Text(
          'Delete Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
        ),
        content: const Text(
          'Are you sure you want to delete your profile? This will log you out of your account.',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Delete Profile', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
