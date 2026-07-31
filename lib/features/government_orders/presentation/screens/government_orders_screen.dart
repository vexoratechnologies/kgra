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
import '../providers/government_orders_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class GovernmentOrdersScreen extends StatefulWidget {
  const GovernmentOrdersScreen({super.key});

  @override
  State<GovernmentOrdersScreen> createState() => _GovernmentOrdersScreenState();
}

class _GovernmentOrdersScreenState extends State<GovernmentOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSection = 'all';
  String? _selectedZone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GovernmentOrdersProvider>().fetchAllOrders();
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
    final provider = context.watch<GovernmentOrdersProvider>();
    final orders = provider.orders;

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

    final filteredOrders = orders.where((o) {
      final matchesSearch = o.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSection = o.section == _selectedSection;
      final matchesZone = _selectedSection != 'zonal' || o.zone == _selectedZone;
      return matchesSearch && matchesSection && matchesZone;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: 'Government Orders',
        subtitle: 'Official G.O. documents',
        rightIcon: Icons.gavel_outlined,
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
                  hintText: 'Search orders by title or order number...',
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
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterTab('State', 'state'),
                  const SizedBox(width: AppSpacing.sm),
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
                      : filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.gavel_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No government orders match search' : 'No government orders found',
                                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final o = filteredOrders[index];
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
                                        color: Colors.orange.shade50,
                                        borderRadius: AppRadius.borderMd,
                                      ),
                                      child: const Icon(Icons.gavel, color: Colors.orange, size: 24),
                                    ),
                                    title: Text(
                                      o.title,
                                      style: AppTextStyle.bodyLg(color: AppColors.brandSecondary).copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Order No: ${o.orderNumber} | Date: ${o.date}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AppPdfViewerScreen(
                                            title: o.title,
                                            pdfUrl: o.pdfUrl,
                                            folderName: 'government_orders',
                                            docId: o.id,
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
