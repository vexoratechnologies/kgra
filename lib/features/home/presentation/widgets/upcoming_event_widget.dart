import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../events/presentation/providers/event_provider.dart';

class UpcomingEventWidget extends StatefulWidget {
  const UpcomingEventWidget({super.key});

  @override
  State<UpcomingEventWidget> createState() => _UpcomingEventWidgetState();
}

class _UpcomingEventWidgetState extends State<UpcomingEventWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final events = provider.eventsList;

    if (provider.isLoading) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.brandPrimary),
      );
    }

    // Filter events that occur today or in the future
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final upcomingEvents = events.where((e) => e.date.compareTo(todayStr) >= 0).toList();

    // Sort by date ascending (closest upcoming event first)
    upcomingEvents.sort((a, b) => a.date.compareTo(b.date));

    if (upcomingEvents.isEmpty) {
      return const SizedBox.shrink(); // Hide the section if no events are scheduled
    }

    final event = upcomingEvents.first;
    final dateTime = DateTime.tryParse(event.date);
    final monthStr = dateTime != null ? DateFormat('MMM').format(dateTime).toUpperCase() : 'OCT';
    final dayStr = dateTime != null ? DateFormat('d').format(dateTime) : '24';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Event',
          style: AppTextStyle.titleLg().copyWith(
            color: AppColors.brandSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.borderLg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent blue line on left side
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F4C81),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top info row
                        Row(
                          children: [
                            // Date Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: AppRadius.borderMd,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    monthStr,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                  Text(
                                    dayStr,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F4C81),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Event details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F4C81),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    event.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Registering for ${event.title}...'),
                                  backgroundColor: const Color(0xFF0056B3),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00408B),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                            ),
                            child: const Text(
                              'Register Now',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
