import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../notification/presentation/screens/notifications_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import 'home_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const NotificationsScreen(showBackButton: false),
      const ProfileScreen(),
      const _MenuScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      // Trigger a fresh fetch of notifications when the Alerts tab is selected
      context.read<NotificationProvider>().fetchNotifications();
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool showBadge = false}) {
    final isSelected = _selectedIndex == index;
    final notificationProvider = context.watch<NotificationProvider>();
    final notificationCount = notificationProvider.totalCount;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onDestinationSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandPrimary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppColors.brandPrimary : const Color(0xFF64748B),
                    size: 22,
                  ),
                  if (showBadge && notificationCount > 0)
                    Positioned(
                      top: -5,
                      right: -7,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.brandPrimary : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFF1F5F9),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LucideIcons.home, 'Home'),
              _buildNavItem(1, LucideIcons.bell, 'Alerts', showBadge: true),
              _buildNavItem(2, LucideIcons.user, 'Profile'),
              _buildNavItem(3, LucideIcons.menu, 'Menu'),
            ],
          ),
        ),
      ),
      // WhatsApp Floating Button in bottom-right corner matching screenshot
      floatingActionButton: _selectedIndex == 0
          ? Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Image.asset(
                                'assets/icon/apple.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text('Opening KGRA WhatsApp Help Desk...'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF25D366),
                          duration: const Duration(seconds: 1),
                        ),
                      );

                      String resolvedNumber = '919747867327'; // Default fallback
                      try {
                        final database = FirebaseDatabase.instance;
                        var ref = database.ref('whatsapp_number');
                        var snapshot = await ref.get();
                        if (!snapshot.exists) {
                          ref = database.ref('settings/whatsapp');
                          snapshot = await ref.get();
                        }
                        if (snapshot.exists && snapshot.value != null) {
                          resolvedNumber = snapshot.value.toString();
                        }
                      } catch (e) {
                        debugPrint('Failed to get WhatsApp number from RTDB: $e');
                      }

                      // Format number for wa.me link
                      String cleanNumber = resolvedNumber.replaceAll(RegExp(r'\D'), '');
                      if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
                        cleanNumber = '91$cleanNumber';
                      }

                      final uri = Uri.parse('https://wa.me/$cleanNumber');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch WhatsApp. Please check if it is installed.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Image.asset(
                      'assets/icon/apple.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}





/// ----------------------------------------------------
/// Menu / More Tab Screen
/// ----------------------------------------------------
class _MenuScreen extends StatelessWidget {
  const _MenuScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: const CompactAppBar(
        title: 'Menu',
        subtitle: 'Explore association features',
        rightIcon: Icons.grid_view_outlined,
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Section 1: Administration
          // _buildMenuSectionTitle('ADMINISTRATION'),
          // _buildMenuItem(
          //   icon: LucideIcons.shieldAlert,
          //   title: 'Access Admin Portal',
          //   subtitle: 'Manage members approvals and settings',
          //   iconColor: AppColors.brandPrimary,
          //   bgColor: AppColors.brandPrimary.withValues(alpha: 0.08),
          //   onTap: () => context.push(AppRoutes.adminUsers),
          // ),
          // const SizedBox(height: AppSpacing.lg),

          // Section 2: General Options
          _buildMenuSectionTitle('ABOUT ASSOCIATION'),
          _buildMenuItem(
            icon: LucideIcons.info,
            title: 'About KGRA',
            subtitle: 'History, objectives, and working committees',
            iconColor: const Color(0xFF475569),
            bgColor: const Color(0xFFF1F5F9),
            onTap: () => context.push(AppRoutes.about),
          ),
          // const SizedBox(height: AppSpacing.sm),
          // _buildMenuItem(
          //   icon: LucideIcons.bookOpen,
          //   title: 'Code of Ethics',
          //   subtitle: 'Professional standards and regulations',
          //   iconColor: const Color(0xFF475569),
          //   bgColor: const Color(0xFFF1F5F9),
          //   onTap: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Displaying Professional Code of Ethics...')),
          //     );
          //   },
          // ),
          const SizedBox(height: AppSpacing.lg),

          // Section 3: Support
          _buildMenuSectionTitle('SUPPORT'),
          _buildMenuItem(
            icon: LucideIcons.helpCircle,
            title: 'Help & FAQs',
            subtitle: 'Frequently asked questions and guides',
            iconColor: const Color(0xFF475569),
            bgColor: const Color(0xFFF1F5F9),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Help Desk FAQs...')),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMenuItem(
            icon: LucideIcons.mail,
            title: 'Contact Secretariat',
            subtitle: 'Support email and office address',
            iconColor: const Color(0xFF475569),
            bgColor: const Color(0xFFF1F5F9),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('KGRA Headquarters, Trivandrum - secretary@kgra.org')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
        ),
      ),
    );
  }
}
