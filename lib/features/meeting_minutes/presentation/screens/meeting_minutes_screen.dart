import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_pdf_viewer_screen.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../providers/meeting_minutes_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MeetingMinutesScreen extends StatefulWidget {
  const MeetingMinutesScreen({super.key});

  @override
  State<MeetingMinutesScreen> createState() => _MeetingMinutesScreenState();
}

class _MeetingMinutesScreenState extends State<MeetingMinutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSection = 'all';
  String? _selectedZone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingMinutesProvider>().fetchAllMinutes();
      context.read<AdminProvider>().fetchZones();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final provider = context.watch<MeetingMinutesProvider>();
    final minutes = provider.minutesList;
    
    final adminProvider = context.watch<AdminProvider>();
    final rawZonesList = adminProvider.zones;
    final userZone = context.watch<AuthProvider>().currentUser?.zone;

    bool isNonZonal(String z) {
      final l = z.trim().toLowerCase();
      return l.isEmpty ||
          l == 'all' ||
          l == 'state' ||
          l.contains('executive');
    }

    String formatZoneName(String z) {
      final trimmed = z.trim();
      if (trimmed.isEmpty) return '';
      return trimmed.split(' ').map((word) {
        if (word.isEmpty) return '';
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }).join(' ');
    }

    // Build unified zones list excluding non-zonal entries (Executive, State, All)
    final Map<String, String> uniqueZones = {};
    for (final z in rawZonesList) {
      if (!isNonZonal(z)) {
        final key = z.trim().toLowerCase();
        uniqueZones.putIfAbsent(key, () => formatZoneName(z));
      }
    }
    for (final m in minutes) {
      if (!isNonZonal(m.zone)) {
        final key = m.zone.trim().toLowerCase();
        uniqueZones.putIfAbsent(key, () => formatZoneName(m.zone));
      }
    }
    final zonesList = uniqueZones.values.toList()..sort();

    if (_selectedZone == null || !zonesList.any((z) => z.toLowerCase() == _selectedZone?.toLowerCase())) {
      if (userZone != null && userZone.isNotEmpty && zonesList.any((z) => z.toLowerCase() == userZone.toLowerCase())) {
        _selectedZone = zonesList.firstWhere((z) => z.toLowerCase() == userZone.toLowerCase());
      } else if (zonesList.isNotEmpty) {
        _selectedZone = zonesList.first;
      }
    }

    final filteredMinutes = minutes.where((m) {
      final matchesStatus = m.status.toLowerCase() == 'approved';
      final matchesSearch = m.title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final bool matchesSectionAndZone;
      if (_selectedSection == 'all') {
        matchesSectionAndZone = true;
      } else if (_selectedSection == 'zonal') {
        final zoneMatches = _selectedZone != null &&
            m.zone.trim().isNotEmpty &&
            m.zone.trim().toLowerCase() == _selectedZone!.trim().toLowerCase();
        final isZonal = m.section.toLowerCase() == 'zonal' ||
            (m.zone.trim().isNotEmpty &&
                m.zone.trim().toLowerCase() != 'state' &&
                m.zone.trim().toLowerCase() != 'all' &&
                m.zone.trim().toLowerCase() != 'executive' &&
                m.zone.trim().toLowerCase() != 'executive committee');
        matchesSectionAndZone = isZonal && zoneMatches;
      } else if (_selectedSection == 'state') {
        matchesSectionAndZone = m.section.toLowerCase() == 'state' ||
            m.zone.trim().toLowerCase() == 'state' ||
            (m.section.toLowerCase() == 'all' &&
                (m.zone.trim().isEmpty || m.zone.trim().toLowerCase() == 'all'));
      } else if (_selectedSection == 'executive') {
        matchesSectionAndZone = m.section.toLowerCase() == 'executive' ||
            m.zone.trim().toLowerCase() == 'executive' ||
            m.zone.trim().toLowerCase() == 'executive committee';
      } else {
        matchesSectionAndZone = m.section.toLowerCase() == _selectedSection.toLowerCase();
      }

      return matchesStatus && matchesSearch && matchesSectionAndZone;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: 'Meeting Minutes',
        subtitle: 'Previous meeting records',
        rightIcon: Icons.assignment_outlined,
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
            // Search Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search meeting minutes by title...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.brandSecondary.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderMd,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
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
                  value: zonesList.any((z) => z.toLowerCase() == _selectedZone?.toLowerCase())
                      ? zonesList.firstWhere((z) => z.toLowerCase() == _selectedZone?.toLowerCase())
                      : (zonesList.isNotEmpty ? zonesList.first : null),
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
                      : filteredMinutes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.file_present_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No meeting minutes match search' : 'No meeting minutes archive found',
                                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filteredMinutes.length,
                              itemBuilder: (context, index) {
                                final m = filteredMinutes[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: AppRadius.borderLg,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: AppRadius.borderMd,
                                      ),
                                      child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                                    ),
                                    title: Text(
                                      m.title,
                                      style: AppTextStyle.bodyLg(color: AppColors.brandSecondary).copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Meeting Date: ${m.date}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AppPdfViewerScreen(
                                            title: m.title,
                                            pdfUrl: m.pdfUrl,
                                            folderName: 'meeting_minutes',
                                            docId: m.id,
                                          ),
                                        ),
                                      );
                                    },
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
