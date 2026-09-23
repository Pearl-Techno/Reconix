import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/historical_trend_service.dart';
import '../theme/app_theme.dart';

class HistoricalTrendView extends StatelessWidget {
  const HistoricalTrendView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final periodSummaries = HistoricalTrendService.generateMultiPeriodAnalytics(
      allErpRecords: state.erpRecords,
      allEtimsRecords: state.etimsRecords,
      allItaxRecords: state.itaxRecords,
    );

    final supplierProfiles = HistoricalTrendService.calculateSupplierRiskProfiles(
      erpRecords: state.erpRecords,
      etimsRecords: state.etimsRecords,
    );

    final totalErpVat = periodSummaries.fold(0.0, (s, p) => s + p.erpInputVat);
    final totalEtimsVat = periodSummaries.fold(0.0, (s, p) => s + p.etimsInputVat);
    final totalVaaRisk = periodSummaries.fold(0.0, (s, p) => s + p.vaaRiskVat);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.barChart2, color: AppColors.mintAccent, size: 24),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Multi-Period Historical VAT Analytics & Behavioral Scoring',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comparative multi-month VAT trend ledgers, KRA compliance rates, and vendor behavioral delay analysis.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.calendar, color: AppColors.kraGold, size: 16),
                      SizedBox(width: 6),
                      Text('6-MONTH COMPARATIVE AUDIT', style: TextStyle(color: AppColors.kraGold, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Metrics Cards
            Row(
              children: [
                _metricCard('ERP INPUT VAT (6-MON)', 'KES ${totalErpVat.toStringAsFixed(2)}', 'Total Booked Claims', LucideIcons.bookOpen, AppColors.infoBlue),
                const SizedBox(width: 16),
                _metricCard('eTIMS VERIFIED VAT', 'KES ${totalEtimsVat.toStringAsFixed(2)}', 'Safe Input Credits', LucideIcons.checkCircle, AppColors.mintAccent),
                const SizedBox(width: 16),
                _metricCard('CUMULATIVE VAA EXPOSURE', 'KES ${totalVaaRisk.toStringAsFixed(2)}', 'Penalty Risk Pool', LucideIcons.alertTriangle, AppColors.crimsonRisk),
              ],
            ),
            const SizedBox(height: 24),

            // Period Comparison Table Card
            Card(
              color: AppColors.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.darkBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly VAT Period Comparison Schedule',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.darkBg),
                        columns: const [
                          DataColumn(label: Text('Tax Period', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ERP Books VAT (KES)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('eTIMS Transmitted (KES)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('iTax Auto-Filled (KES)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('2% WHVAT Credit', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Compliance Rate', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                        ],
                        rows: periodSummaries.map((p) {
                          return DataRow(
                            cells: [
                              DataCell(Text(p.taxPeriod, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              DataCell(Text('KES ${p.erpInputVat.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.infoBlue))),
                              DataCell(Text('KES ${p.etimsInputVat.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.mintAccent))),
                              DataCell(Text('KES ${p.itaxInputVat.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.kraGold))),
                              DataCell(Text('KES ${p.whvatCredits.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: p.compliancePercentage >= 80 ? AppColors.emeraldDark.withValues(alpha: 0.2) : AppColors.crimsonRisk.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${p.compliancePercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: p.compliancePercentage >= 80 ? AppColors.mintAccent : AppColors.crimsonRisk,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Supplier Behavioral Risk Scorecard Card
            Card(
              color: AppColors.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.darkBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Supplier Behavioral Latency Scorecard',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Scored by transmission delay frequency',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.darkBg),
                        columns: const [
                          DataColumn(label: Text('Supplier Name', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('KRA PIN', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Orders', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Delayed eTIMS (>3 days)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Missing eTIMS Invoices', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Behavioral Risk Tier', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                        ],
                        rows: supplierProfiles.map((s) {
                          return DataRow(
                            cells: [
                              DataCell(Text(s.supplierName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              DataCell(Text(s.supplierPin, style: const TextStyle(color: AppColors.kraGold))),
                              DataCell(Text('${s.totalOrdersCount}', style: const TextStyle(color: Colors.white))),
                              DataCell(Text('${s.delayedEtimsCount}', style: const TextStyle(color: Colors.orange))),
                              DataCell(Text('${s.missingEtimsCount}', style: const TextStyle(color: AppColors.crimsonRisk, fontWeight: FontWeight.bold))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: s.riskScore >= 50 ? AppColors.crimsonRisk.withValues(alpha: 0.2) : AppColors.emeraldDark.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: s.riskScore >= 50 ? AppColors.crimsonRisk : AppColors.mintAccent),
                                  ),
                                  child: Text(
                                    s.riskTier,
                                    style: TextStyle(
                                      color: s.riskScore >= 50 ? AppColors.crimsonRisk : AppColors.mintAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
