import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/routes/app_routes.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showBackButton;
  const NotificationsScreen({super.key, this.showBackButton = true});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().fetchMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notificationsList;

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brandPrimary,
          onRefresh: () => provider.fetchNotifications(),
          child: provider.isLoading && notifications.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : provider.error != null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: Text(provider.error!, style: const TextStyle(color: AppColors.error)),
                      ),
                    )
                  : notifications.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.7,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  'No notifications yet',
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: notifications.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == notifications.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.brandPrimary,
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              );
                            }
                            final n = notifications[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
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
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: AppRadius.borderLg,
                                  onTap: () {
                                    if (n.routingPath.isNotEmpty) {
                                      context.push(n.routingPath);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandPrimary.withValues(alpha: 0.05),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.notifications_active,
                                            color: AppColors.brandPrimary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                n.title,
                                                style: AppTextStyle.titleLg(color: AppColors.brandSecondary).copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                n.body,
                                                style: AppTextStyle.bodyMd(color: AppColors.onSurfaceVariant).copyWith(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (n.routingPath.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Tap to view details',
                                                      style: AppTextStyle.bodySm(color: AppColors.brandPrimary).copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.arrow_forward,
                                                      size: 11,
                                                      color: AppColors.brandPrimary,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
