import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/app_snack_bar.dart';
import '../../../../core/widgets/compact_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/payment_config_model.dart';
import '../../data/models/payment_model.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected fee category
  int _selectedPlanIndex = 0;

  List<Map<String, dynamic>> _buildPlans(PaymentConfigModel config) => [
    {
      'title': config.membershipTitle,
      'amount': config.annualMembershipAmount,
      'purpose': config.membershipPurpose,
      'description': config.membershipDescription,
      'icon': LucideIcons.calendar,
    },
  ];

  double _getPlanAmount(PaymentConfigModel config) {
    final plans = _buildPlans(config);
    if (_selectedPlanIndex >= 0 && _selectedPlanIndex < plans.length) {
      final amt = plans[_selectedPlanIndex]['amount'];
      if (amt is num) return amt.toDouble();
    }
    return config.annualMembershipAmount;
  }

  String _getPlanPurpose(PaymentConfigModel config) {
    final plans = _buildPlans(config);
    if (_selectedPlanIndex >= 0 && _selectedPlanIndex < plans.length) {
      return (plans[_selectedPlanIndex]['purpose'] as String?) ?? config.membershipPurpose;
    }
    return config.membershipPurpose;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final isPaymentAllowed = paymentProvider.isPaymentAllowed;
    final isConfigLoaded = paymentProvider.isConfigLoaded;

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: 'Membership & Fees',
        subtitle: 'Kerala Govt Radiographers Association',
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      body: !isConfigLoaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : !isPaymentAllowed
              ? _buildReviewSafeView()
              : Column(
              children: [
                // Tab bar for Pay vs History
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.secondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelStyle: AppTextStyle.labelMd().copyWith(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Pay Dues / Fees', icon: Icon(LucideIcons.creditCard, size: 18)),
                      Tab(text: 'Payment History', icon: Icon(LucideIcons.history, size: 18)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPaymentForm(paymentProvider, user),
                      _buildPaymentHistory(paymentProvider, user?.uid ?? ''),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// App Store Review Safe View (displayed when payment is toggled off, e.g. for iOS review)
  Widget _buildReviewSafeView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'KGRA Membership Desk',
                  style: AppTextStyle.headlineMd().copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kerala Govt Radiographers Association',
                  style: AppTextStyle.bodySm(color: AppColors.secondary),
                ),
                const Divider(height: 32),
                Text(
                  'Membership verification, renewals, and official state association records are managed through your designated District Committee executives or the state headquarters.',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.bodyMd(color: AppColors.onSurface).copyWith(
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.brandBackground,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'For membership inquiries, please consult your Zonal or State Committee representative.',
                          style: AppTextStyle.bodySm(color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Payment Form View (displayed on Android or when remote switch is enabled)
  Widget _buildPaymentForm(PaymentProvider provider, dynamic user) {
    final plans = _buildPlans(provider.config);
    final currentAmount = _getPlanAmount(provider.config);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Member Profile Summary Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(LucideIcons.user, color: Colors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Association Member',
                        style: AppTextStyle.bodyMd().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Member ID: ${user?.membershipId ?? 'KGRA-MEM'}',
                        style: AppTextStyle.bodySm(color: Colors.white70),
                      ),
                      Text(
                        'Phone: ${user?.phoneNumber ?? 'N/A'}',
                        style: AppTextStyle.bodySm(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Plan Selection Header
          Text(
            'Membership Fee',
            style: AppTextStyle.bodyMd().copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // List of Plans
          ...List.generate(plans.length, (index) {
            final plan = plans[index];
            final isSelected = _selectedPlanIndex == index;
            final badge = plan['badge'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedPlanIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.brandBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          plan['icon'] as IconData,
                          color: isSelected ? AppColors.primary : AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    plan['title'] as String,
                                    style: AppTextStyle.bodySm().copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (badge != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.12)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      badge,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppColors.primary : AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan['description'] as String,
                              style: AppTextStyle.bodySm(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '₹${((plan['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                        style: AppTextStyle.bodyMd().copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.lg),

          // Total & Pay Button
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Payable Amount:', style: AppTextStyle.bodyMd()),
                    Text(
                      '₹${currentAmount.toStringAsFixed(0)}',
                      style: AppTextStyle.headlineMd().copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => _handlePayPressed(provider, user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Center(
                            child: Text(
                              'Pay',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.shield, size: 12, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '100% Secure Payment • UPI, Cards & NetBanking',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodySm(color: AppColors.secondary).copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePayPressed(PaymentProvider provider, dynamic user) {
    final amount = _getPlanAmount(provider.config);
    final purpose = _getPlanPurpose(provider.config);
    provider.startPayment(
      amount: amount,
      userId: user?.uid ?? 'guest',
      userName: user?.name ?? 'Member',
      userPhone: user?.phoneNumber ?? '',
      userEmail: '',
      membershipId: user?.membershipId,
      designation: user?.designation,
      institution: user?.institution,
      zone: user?.zone,
      purpose: purpose,
      onSuccess: () {
        AppSnackBar.showSuccess(context, 'Payment completed successfully!');
        _tabController.animateTo(1); // Switch to history tab
      },
      onError: (err) {
        AppSnackBar.showError(context, err);
      },
    );
  }

  /// Payment History View from PAYMENTS collection
  Widget _buildPaymentHistory(PaymentProvider provider, String userId) {
    if (userId.isEmpty) {
      return Center(
        child: Text('Please log in to view payment history.', style: AppTextStyle.bodyMd()),
      );
    }

    return StreamBuilder<List<PaymentTransactionModel>>(
      stream: provider.watchUserPayments(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.receipt, size: 48, color: AppColors.secondary.withValues(alpha: 0.5)),
                const SizedBox(height: AppSpacing.md),
                Text('No payment records yet', style: AppTextStyle.bodyMd().copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your verified receipts will appear here.',
                  style: AppTextStyle.bodySm(color: AppColors.secondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final payment = payments[index];
            final dateStr = payment.verifiedAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(payment.verifiedAt!)
                : 'Recent';

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.purposeLabel ?? payment.purpose.replaceAll('_', ' '),
                          style: AppTextStyle.bodySm().copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (payment.receiptNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Receipt: ${payment.receiptNumber}',
                            style: AppTextStyle.bodySm(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${payment.paymentId} • ${payment.paymentMethod?.toUpperCase() ?? 'ONLINE'}',
                          style: AppTextStyle.bodySm(color: AppColors.secondary).copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: AppTextStyle.bodySm(color: AppColors.secondary).copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${payment.amount.toStringAsFixed(0)}',
                    style: AppTextStyle.bodyMd().copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
