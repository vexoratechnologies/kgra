import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open: $urlString'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: 'About MY KGRA',
        subtitle: 'Kerala Govt Radiographers Association',
        rightIcon: Icons.info_outline,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Header Card with Logo
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.borderXl,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Circular App Logo with Brand Border and Shadow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        width: 4,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/icon/kgra.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback in case the image fails to load
                          return Container(
                            color: AppColors.brandPrimary,
                            child: const Center(
                              child: Icon(
                                LucideIcons.activity,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'MY KGRA',
                    style: AppTextStyle.headlineMd(color: AppColors.brandPrimary).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: AppTextStyle.labelSm(color: AppColors.brandPrimary).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Welcome & Description Section
            Text(
              'Welcome to MY KGRA',
              style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY KGRA is the official mobile application of the Kerala Government Radiographers’ Association (KGRA), developed to provide members with a secure and convenient digital platform for accessing association services and updates.',
                    style: AppTextStyle.bodyMd(color: const Color(0xFF334155)).copyWith(
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'The application helps members stay connected through educational resources, committee information, official announcements, government orders, meeting minutes, live sessions, and membership services—all in one place.',
                    style: AppTextStyle.bodyMd(color: const Color(0xFF334155)).copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Key App Features Section
            Text(
              'Application Services & Features',
              style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureGrid(),
            const SizedBox(height: AppSpacing.xl),

            // Developer & Contact Info Section
            Text(
              'Information & Support',
              style: AppTextStyle.headlineSm(color: AppColors.brandSecondary).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildSupportRow(
                    icon: LucideIcons.code,
                    title: 'Developed By',
                    value: 'Vexora Technologies',
                    onTap: null,
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildSupportRow(
                    icon: LucideIcons.mail,
                    title: 'Contact Support',
                    value: 'info@vexoratechnologies.in',
                    onTap: () => _launchUrl(context, 'mailto:info@vexoratechnologies.in'),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildSupportRow(
                    icon: LucideIcons.globe,
                    title: 'Official Website',
                    value: 'www.vexoratechnologies.in',
                    onTap: () => _launchUrl(context, 'https://www.vexoratechnologies.in'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Footer association info
            Text(
              '© ${DateTime.now().year} Kerala Government Radiographers’ Association\nAll Rights Reserved.',
              textAlign: TextAlign.center,
              style: AppTextStyle.labelSm(color: const Color(0xFF94A3B8)).copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(
        icon: LucideIcons.bookOpen,
        label: 'Educational Resources',
        color: const Color(0xFF0F4C81),
      ),
      _FeatureItem(
        icon: LucideIcons.users,
        label: 'Committee Information',
        color: const Color(0xFF2563EB),
      ),
      _FeatureItem(
        icon: LucideIcons.megaphone,
        label: 'Official Announcements',
        color: const Color(0xFFD97706),
      ),
      _FeatureItem(
        icon: LucideIcons.fileText,
        label: 'Government Orders',
        color: const Color(0xFF0D9488),
      ),
      _FeatureItem(
        icon: LucideIcons.clock,
        label: 'Meeting Minutes',
        color: const Color(0xFF4F46E5),
      ),
      _FeatureItem(
        icon: LucideIcons.video,
        label: 'Live Sessions',
        color: const Color(0xFFDC2626),
      ),
      _FeatureItem(
        icon: LucideIcons.award,
        label: 'Membership Services',
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyle.bodySm(color: const Color(0xFF1E293B)).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 20),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.labelSm(color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyle.bodyMd(
                      color: onTap != null ? AppColors.brandPrimary : const Color(0xFF1E293B),
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                LucideIcons.externalLink,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
