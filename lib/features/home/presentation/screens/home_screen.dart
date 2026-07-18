import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../ads/presentation/widgets/ad_carousel_widget.dart';
import '../widgets/upcoming_event_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final gridItems = [
      _GridItem(
        title: 'State Committee',
        icon: LucideIcons.users,
        iconColor: const Color(0xFF0F4C81),
        bgColor: const Color(0xFFEFF6FF),
        onTap: () {
          context.push(AppRoutes.stateCommittee);
        },
      ),
      _GridItem(
        title: 'Zonal',
        icon: LucideIcons.map,
        iconColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
        onTap: () {
          context.push(AppRoutes.zonalCommittee);
        },
      ),
      _GridItem(
        title: 'Meeting Minutes',
        icon: LucideIcons.fileText,
        iconColor: const Color(0xFF4F46E5),
        bgColor: const Color(0xFFEEF2F6),
        onTap: () {
          context.push(AppRoutes.meetingMinutes);
        },
      ),
      _GridItem(
        title: 'New Membership/\nRenewal',
        icon: LucideIcons.userPlus,
        iconColor: const Color(0xFF0D9488),
        bgColor: const Color(0xFFF0FDF4),
        isComingSoon: true,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Membership Registration...')),
          );
        },
      ),
      _GridItem(
        title: 'Beneficiary\nScheme',
        icon: LucideIcons.heartHandshake,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        isComingSoon: true,
        onTap: () {
          context.push(AppRoutes.beneficiary);
        },
      ),
      _GridItem(
        title: 'Updates',
        icon: LucideIcons.megaphone,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
        onTap: () {
          context.push(AppRoutes.updates);
        },
      ),


      _GridItem(
        title: 'Forms',
        icon: LucideIcons.fileSpreadsheet,
        iconColor: const Color(0xFF0891B2),
        bgColor: const Color(0xFFECFEFF),
        onTap: () {
          context.push(AppRoutes.formsCirculars);
        },
      ),
      _GridItem(
        title: 'Live Session',
        icon: LucideIcons.video,
        iconColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
        onTap: () {
          context.push(AppRoutes.liveSessions);
        },
      ),
      _GridItem(
        title: 'Gallery',
        icon: LucideIcons.image,
        iconColor: const Color(0xFF16A34A),
        bgColor: const Color(0xFFDCFCE7),
        onTap: () {
          context.push(AppRoutes.gallery);
        },
      ),
      _GridItem(
        title: 'Educational\nVideo',
        icon: LucideIcons.video,
        iconColor: const Color(0xFF1E40AF),
        bgColor: const Color(0xFFDBEAFE),
        onTap: () {
          context.push(AppRoutes.videos);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            // App Branding
            Text(
              'KGRA Community',
              style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // Header Notifications icon replacing the headphones/customer care icon
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.brandSecondary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  LucideIcons.bell,
                  color: AppColors.brandSecondary,
                  size: 20,
                ),
                onPressed: () {
                  context.push(AppRoutes.notification);
                },
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade100,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdCarouselWidget(),
              const SizedBox(height: AppSpacing.md),
              // 1. Welcome Card
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.all(AppSpacing.lg),
              //   decoration: BoxDecoration(
              //     borderRadius: AppRadius.borderLg,
              //     gradient: const LinearGradient(
              //       colors: [Color(0xFF0056B3), Color(0xFF0F4C81)],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //     boxShadow: [
              //       BoxShadow(
              //         color: const Color(0xFF0056B3).withValues(alpha: 0.2),
              //         blurRadius: 15,
              //         offset: const Offset(0, 8),
              //       ),
              //     ],
              //   ),
              //   child: Stack(
              //     children: [
              //       // Plus symbol watermark overlay in top-right
              //       Positioned(
              //         right: -10,
              //         top: -10,
              //         child: Opacity(
              //           opacity: 0.08,
              //           child: Icon(
              //             LucideIcons.plus,
              //             size: 100,
              //             color: Colors.white.withValues(alpha: 0.8),
              //           ),
              //         ),
              //       ),
              //       Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             'Welcome back,',
              //             style: AppTextStyle.bodyLg().copyWith(
              //               color: Colors.white.withValues(alpha: 0.9),
              //               fontWeight: FontWeight.w400,
              //             ),
              //           ),
              //           const SizedBox(height: AppSpacing.xs),
              //           Text(
              //             userName,
              //             style: AppTextStyle.headlineLgMobile().copyWith(
              //               color: Colors.white,
              //               fontWeight: FontWeight.w700,
              //             ),
              //           ),
              //           const SizedBox(height: AppSpacing.md),
              //           Text(
              //             'Stay updated with the latest from the Kerala Government Radiographers\' Association.',
              //             style: AppTextStyle.bodyMd().copyWith(
              //               color: Colors.white.withValues(alpha: 0.85),
              //               height: 1.4,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
              
              const SizedBox(height: AppSpacing.lg),

              // 2. Action Grid Layout (12 Items in 3 columns)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.95,
                ),
                itemCount: gridItems.length,
                itemBuilder: (context, index) {
                  return _buildActionGridTile(context, gridItems[index]);
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Upcoming Event section
              const UpcomingEventWidget(),
              const SizedBox(height: 80), // bottom space so we don't overlap with FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionGridTile(BuildContext context, _GridItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.isComingSoon
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.title.replaceAll('\n', ' ')} feature is coming soon!'),
                          backgroundColor: AppColors.brandSecondary,
                        ),
                      );
                    }
                  : item.onTap,
              borderRadius: AppRadius.borderMd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          color: item.iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Center(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (item.isComingSoon)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B), // Amber color
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isComingSoon;

  const _GridItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
    this.isComingSoon = false,
  });
}
