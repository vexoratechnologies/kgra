import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/video_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';

class VideosCatalogScreen extends StatefulWidget {
  const VideosCatalogScreen({super.key});

  @override
  State<VideosCatalogScreen> createState() => _VideosCatalogScreenState();
}

class _VideosCatalogScreenState extends State<VideosCatalogScreen> {
  String _selectedSection = 'all';
  String? _selectedZone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<VideoProvider>().fetchVideos(user.uid);
      }
      context.read<AdminProvider>().fetchZones();
    });
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedSection == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSection = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandPrimary : Colors.transparent,
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: isSelected ? AppColors.brandPrimary : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.brandSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final videos = provider.videosList;
    final progressMap = provider.progressMap;

    final adminProvider = context.watch<AdminProvider>();
    final zonesList = adminProvider.zones;
    final userZone = context.watch<AuthProvider>().currentUser?.zone;

    if (_selectedZone == null || !zonesList.contains(_selectedZone)) {
      if (userZone != null && userZone.isNotEmpty && zonesList.contains(userZone)) {
        _selectedZone = userZone;
      } else if (zonesList.isNotEmpty) {
        _selectedZone = zonesList.first;
      }
    }

    final filteredVideos = videos.where((v) {
      final matchesSection = _selectedSection == 'all' || v.section == _selectedSection;
      final matchesZone = _selectedSection != 'zonal' || v.zone == _selectedZone;
      return matchesSection && matchesZone;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: 'Educational Videos',
        subtitle: 'Learn from experts',
        rightIcon: Icons.play_circle_outline,
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: Colors.white,
              child: Row(
                children: [
                  _buildFilterTab('All', 'all'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterTab('State', 'state'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterTab('Executive', 'executive'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterTab('Zonal', 'zonal'),
                ],
              ),
            ),
            if (_selectedSection == 'zonal' && zonesList.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                color: Colors.white,
                child: DropdownButtonFormField<String>(
                  value: _selectedZone,
                  decoration: InputDecoration(
                    labelText: 'Filter by Zone',
                    filled: true,
                    fillColor: AppColors.brandSecondary.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMd,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: zonesList.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedZone = val;
                      });
                    }
                  },
                ),
              ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
                  : provider.error != null
                      ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
                      : filteredVideos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No educational videos uploaded yet in this section',
                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filteredVideos.length,
                              itemBuilder: (context, index) {
                          final v = filteredVideos[index];
                          final progress = progressMap[v.id];
                          final watchedSecs = progress?.watchedSeconds ?? 0;
                          final isCompleted = progress?.isCompleted ?? false;
                          final percent = v.duration > 0 ? (watchedSecs / v.duration).clamp(0.0, 1.0) : 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                            child: ClipRRect(
                              borderRadius: AppRadius.borderLg,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    context.push(AppRoutes.videoDetails, extra: v);
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Thumbnail placeholder/icon
                                      Container(
                                        width: 120,
                                        height: 90,
                                        color: AppColors.brandSecondary.withValues(alpha: 0.05),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            v.thumbnailUrl.isNotEmpty
                                                ? Image.network(
                                                    v.thumbnailUrl,
                                                    width: 120,
                                                    height: 90,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        const Icon(Icons.video_collection, size: 36, color: AppColors.brandPrimary),
                                                  )
                                                : const Icon(Icons.video_collection, size: 36, color: AppColors.brandPrimary),
                                            if (v.duration > 0)
                                              Positioned(
                                                bottom: 4,
                                                right: 4,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  color: Colors.black.withValues(alpha: 0.7),
                                                  child: Text(
                                                    '${(v.duration ~/ 60).toString().padLeft(2, '0')}:${(v.duration % 60).toString().padLeft(2, '0')}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(AppSpacing.md),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      v.title,
                                                      style: AppTextStyle.bodyLg().copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isCompleted)
                                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                v.description,
                                                style: AppTextStyle.bodySm(color: AppColors.onSurfaceVariant),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (v.duration > 0) ...[
                                                const SizedBox(height: 8),
                                                // Progress Bar
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(2),
                                                        child: LinearProgressIndicator(
                                                          value: percent,
                                                          backgroundColor: Colors.grey.shade100,
                                                          color: isCompleted ? Colors.green : AppColors.brandPrimary,
                                                          minHeight: 4,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${(percent * 100).toInt()}%',
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
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
          ],
        ),
      ),
    );
  }
}
