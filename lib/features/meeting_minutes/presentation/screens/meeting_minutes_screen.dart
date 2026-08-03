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
    final zonesList = adminProvider.zones;
    final userZone = context.watch<AuthProvider>().currentUser?.zone;

    if (_selectedZone == null || !zonesList.contains(_selectedZone)) {
      if (userZone != null && userZone.isNotEmpty && zonesList.contains(userZone)) {
        _selectedZone = userZone;
      } else if (zonesList.isNotEmpty) {
        _selectedZone = zonesList.first;
      }
    }

    final filteredMinutes = minutes.where((m) {
      final matchesStatus = m.status == 'approved';
      final matchesSearch = m.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSection = _selectedSection == 'all' || m.section == _selectedSection;
      final matchesZone = _selectedSection != 'zonal' || m.zone == _selectedZone;
      return matchesStatus && matchesSearch && matchesSection && matchesZone;
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
