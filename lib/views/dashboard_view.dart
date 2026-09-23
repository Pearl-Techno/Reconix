import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../models/reconciliation_match.dart';
import '../theme/app_theme.dart';
import 'widgets/invoice_detail_dialog.dart';
import 'widgets/vat7_filing_checklist_dialog.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    // Urgent action items (Critical & High risk)
    final urgentMatches = state.reconciliationResults
        .where((m) => m.riskLevel == RiskLevel.critical || m.riskLevel == RiskLevel.high)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 20th Monthly Filing Deadline Banner
          _buildFilingDeadlineBanner(context, state),
          const SizedBox(height: 24),

          // Executive Metric Cards Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Claimable Input VAT (Matched)',
                  value: 'KES ${numberFormat.format(state.totalInputVatClaimable)}',
                  subtitle: 'Cleared for iTax Section B filing',
                  icon: LucideIcons.checkCircle2,
                  iconColor: AppColors.mintAccent,
                  badgeText: '${state.matchedRatioPercentage.toStringAsFixed(1)}% Matched',
                  badgeColor: AppColors.mintAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Unclaimed Input VAT Risk',
                  value: 'KES ${numberFormat.format(state.totalInputVatAtRisk)}',
                  subtitle: 'Omitted from pre-filled return',
                  icon: LucideIcons.alertTriangle,
                  iconColor: AppColors.warningOrange,
                  badgeText: '${state.unclaimedVatCount} Invoices',
                  badgeColor: AppColors.warningOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: '2026 Expense Disallowance Risk',
                  value: 'KES ${numberFormat.format(state.total2026ExpenseDeductibilityRisk)}',
                  subtitle: 'Books purchases lacking eTIMS code',
                  icon: LucideIcons.shieldAlert,
                  iconColor: AppColors.crimsonRisk,
                  badgeText: '${state.vaaRiskCount} VAA Exposures',
                  badgeColor: AppColors.crimsonRisk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Section 16(1) Corp Tax Risk',
                  value: 'KES ${numberFormat.format(state.totalCorporateTaxDisallowanceLiability)}',
                  subtitle: '30% Income tax penalty exposure',
                  icon: LucideIcons.landmark,
                  iconColor: AppColors.kraGold,
                  badgeText: '30% Corp Tax',
                  badgeColor: AppColors.kraGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Charts & Analytics Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart: Match Distribution
              Expanded(
                flex: 4,
                child: _buildMatchDistributionCard(context, state),
              ),
              const SizedBox(width: 16),
              // Bar Chart: Exception Category Breakdown
              Expanded(
                flex: 6,
                child: _buildExceptionBreakdownCard(context, state),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Urgent Action Items Ledger
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: AppColors.crimsonRisk, size: 22),
                          const SizedBox(width: 10),
                          Text('High-Priority Audit Exposure Items', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.arrowRight, size: 16),
                        label: const Text('Open 3-Way Reconciliation Ledger'),
                        onPressed: () => state.setActiveTab(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (urgentMatches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No critical audit exposures found! All invoices fully reconciled.',
                          style: TextStyle(color: AppColors.mintAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(2.5),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.8),
                        5: FlexColumnWidth(1.0),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(6)),
                          children: [
                            _tableHeader('Match ID'),
                            _tableHeader('Invoice #'),
                            _tableHeader('Supplier & KRA PIN'),
                            _tableHeader('Total Amount'),
                            _tableHeader('Exposure Category'),
                            _tableHeader('Action'),
                          ],
                        ),
                        ...urgentMatches.map((m) {
                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.darkBorder, width: 0.5)),
                            ),
                            children: [
                              _tableCell(m.matchId, isBold: true),
                              _tableCell(m.invoiceNumber),
                              _tableCell('${m.supplierName}\n(${m.supplierPin})'),
                              _tableCell('KES ${numberFormat.format(m.primaryTotal)}', isBold: true),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getStatusColor(m.status).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    m.status.shortTag,
                                    style: TextStyle(
                                      color: AppTheme.getStatusColor(m.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: IconButton(
                                  icon: const Icon(LucideIcons.eye, color: AppColors.mintAccent, size: 18),
                                  tooltip: 'Inspect & Resolve',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => InvoiceDetailDialog(match: m),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilingDeadlineBanner(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emeraldDark,
            AppColors.emeraldPrimary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kraGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.calendarClock, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '20th VAT 7 Filing Readiness Window - ${state.selectedTaxPeriod}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reconcile eTIMS/TIMS invoices against internal ledgers before KRA iTax lock-in.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                icon: const Icon(LucideIcons.listChecks, size: 18),
                label: const Text('VAT 7 Filing Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Vat7FilingChecklistDialog(
                      taxPeriod: state.selectedTaxPeriod,
                      clientName: state.activeClient.businessName,
                      kraPin: state.activeClient.kraPin,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kraGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                icon: const Icon(LucideIcons.fileCheck2, size: 18),
                label: const Text('Evidence Pack PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => state.setActiveTab(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchDistributionCard(BuildContext context, AppState state) {
    final matchedCount = state.reconciliationResults.where((m) => m.status == MatchStatus.matched).length;
    final timingCount = state.timingLatencyCount;
    final riskCount = state.unclaimedVatCount + state.vaaRiskCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('3-Way Matching Ratio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: AppColors.mintAccent,
                      value: matchedCount.toDouble(),
                      title: '$matchedCount',
                      radius: 35,
                      titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    PieChartSectionData(
                      color: AppColors.infoBlue,
                      value: timingCount.toDouble(),
                      title: '$timingCount',
                      radius: 35,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    PieChartSectionData(
                      color: AppColors.crimsonRisk,
                      value: riskCount.toDouble(),
                      title: '$riskCount',
                      radius: 35,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendDot('Fully Matched', AppColors.mintAccent),
                _legendDot('Timing Delay', AppColors.infoBlue),
                _legendDot('Audit Risk', AppColors.crimsonRisk),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExceptionBreakdownCard(BuildContext context, AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Variance Exposure Breakdown by Exception Category', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          switch (val.toInt()) {
                            case 0:
                              return const Text('Matched', style: TextStyle(fontSize: 10, color: AppColors.textMuted));
                            case 1:
                              return const Text('Timing', style: TextStyle(fontSize: 10, color: AppColors.textMuted));
                            case 2:
                              return const Text('Unclaimed', style: TextStyle(fontSize: 10, color: AppColors.textMuted));
                            case 3:
                              return const Text('VAA Risk', style: TextStyle(fontSize: 10, color: AppColors.textMuted));
                            case 4:
                              return const Text('2026 Exp', style: TextStyle(fontSize: 10, color: AppColors.textMuted));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeBarGroup(0, state.reconciliationResults.where((m) => m.status == MatchStatus.matched).length.toDouble(), AppColors.mintAccent),
                    _makeBarGroup(1, state.timingLatencyCount.toDouble(), AppColors.infoBlue),
                    _makeBarGroup(2, state.unclaimedVatCount.toDouble(), AppColors.warningOrange),
                    _makeBarGroup(3, state.vaaRiskCount.toDouble(), AppColors.crimsonRisk),
                    _makeBarGroup(4, state.reconciliationResults.where((m) => m.status == MatchStatus.expenseValidationRisk2026).length.toDouble(), AppColors.kraGold),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Count of invoice items per KRA exception classification category',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  static Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }

  static Widget _tableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textPrimary,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
