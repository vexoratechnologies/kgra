import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/routes/app_routes.dart';
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
      const _AlertsScreen(),
      const _ProfileScreen(),
      const _MenuScreen(),
    ];
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.bell),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.menu),
            label: 'Menu',
          ),
        ],
      ),
      // WhatsApp Floating Button in bottom-right corner matching screenshot
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.chat, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Opening KGRA WhatsApp Help Desk...'),
                      ],
                    ),
                    backgroundColor: Color(0xFF25D366),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: const Color(0xFF25D366), // Official WhatsApp Green
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.chat, size: 28),
            )
          : null,
    );
  }
}

/// ----------------------------------------------------
/// Alerts / Notifications Tab Screen
/// ----------------------------------------------------
class _AlertsScreen extends StatelessWidget {
  const _AlertsScreen();

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {
        'title': 'New Zonal Committee Appointed',
        'desc': 'Kerala Government Radiographers\' Association announces new executive representatives for the Trivandrum zone.',
        'time': '2 hours ago',
        'isNew': true,
      },
      {
        'title': 'Annual Zonal Conference Registration Open',
        'desc': 'Register early for the Annual Zonal Conference at Trivandrum Medical College Auditorium to reserve your seat.',
        'time': '1 day ago',
        'isNew': true,
      },
      {
        'title': 'Radiation Safety Seminar Postponed',
        'desc': 'The upcoming interactive session scheduled for this Saturday has been rescheduled to next month. Stay tuned for details.',
        'time': '3 days ago',
        'isNew': false,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          final isNew = alert['isNew'] as bool;
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: isNew
                    ? AppColors.brandPrimary.withValues(alpha: 0.15)
                    : const Color(0xFFF1F5F9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      alert['time'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  alert['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isNew ? AppColors.brandPrimary : AppColors.brandSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  alert['desc'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ----------------------------------------------------
/// Profile Tab Screen
/// ----------------------------------------------------
class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final name = user?.name ?? 'Member';
    final phone = user?.phoneNumber ?? 'N/A';
    final designation = user?.designation ?? 'Professional Radiographer';
    final institution = user?.institution ?? 'Government Hospital';

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            // Profile Card Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                  // Circle Initial Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0057B8), Color(0xFF0F4C81)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F4C81),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.green.shade700, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'APPROVED MEMBER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: AppSpacing.xxl),
                  _buildProfileRow(LucideIcons.phone, 'Mobile Number', phone),
                  const SizedBox(height: AppSpacing.md),
                  _buildProfileRow(LucideIcons.briefcase, 'Designation', designation),
                  const SizedBox(height: AppSpacing.md),
                  _buildProfileRow(LucideIcons.home, 'Institution', institution),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Logout Action
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('Sign Out Session'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderLg,
                  ),
                ),
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
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
      appBar: AppBar(
        title: Text(
          'Menu',
          style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Section 1: Administration
          _buildMenuSectionTitle('ADMINISTRATION'),
          _buildMenuItem(
            icon: LucideIcons.shieldAlert,
            title: 'Access Admin Portal',
            subtitle: 'Manage members approvals and settings',
            iconColor: AppColors.brandPrimary,
            bgColor: AppColors.brandPrimary.withValues(alpha: 0.08),
            onTap: () => context.push(AppRoutes.adminUsers),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section 2: General Options
          _buildMenuSectionTitle('ABOUT ASSOCIATION'),
          _buildMenuItem(
            icon: LucideIcons.info,
            title: 'About KGRA',
            subtitle: 'History, objectives, and working committees',
            iconColor: const Color(0xFF475569),
            bgColor: const Color(0xFFF1F5F9),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kerala Government Radiographers\' Association founded in 1980...')),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMenuItem(
            icon: LucideIcons.bookOpen,
            title: 'Code of Ethics',
            subtitle: 'Professional standards and regulations',
            iconColor: const Color(0xFF475569),
            bgColor: const Color(0xFFF1F5F9),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Displaying Professional Code of Ethics...')),
              );
            },
          ),
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
