import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/customs_match_result.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/sample_templates_dialog.dart';

class CustomsReconciliationView extends StatelessWidget {
  const CustomsReconciliationView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customsMatches = state.customsMatches;

    final totalCustomsVat = state.customsEntries.fold(0.0, (sum, c) => sum + c.importVatAmount);
    final totalTaxableValue = state.customsEntries.fold(0.0, (sum, c) => sum + c.taxableValue);
    final matchedCount = customsMatches.where((m) => m.isMatched).length;
    final unmatchedCount = customsMatches.where((m) => !m.isMatched).length;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.ship, color: AppColors.mintAccent, size: 24),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Import Customs Entry (Section F VAT) Ledger',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reconcile KRA Customs SIMBA/ICMS declarations (C17 SAD entries) against internal ERP import purchases.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => SampleTemplatesDialog.show(context),
                  icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                  label: const Text('Sample Customs CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.mintAccent,
                    side: const BorderSide(color: AppColors.mintAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => state.setActiveTab(5), // Data Ingestion Hub
                  icon: const Icon(LucideIcons.uploadCloud, size: 16),
                  label: const Text('Import Customs Entries'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPI Cards
            Row(
              children: [
                _kpiCard(
                  title: 'CUSTOMS ENTRIES',
                  value: '${state.customsEntries.length}',
                  subtitle: 'KRA SIMBA / ICMS Declarations',
                  icon: LucideIcons.fileText,
                  color: AppColors.infoBlue,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  title: 'TOTAL IMPORT TAXABLE VALUE',
                  value: 'KES ${totalTaxableValue.toStringAsFixed(2)}',
                  subtitle: 'CIF Customs Valuation Base',
                  icon: LucideIcons.coins,
                  color: AppColors.kraGold,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  title: 'CLAIMABLE IMPORT VAT',
                  value: 'KES ${totalCustomsVat.toStringAsFixed(2)}',
                  subtitle: 'iTax Form 7 Section F Credit',
                  icon: LucideIcons.checkCircle2,
                  color: AppColors.emeraldDark,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  title: 'MATCHED / UNCLAIMED',
                  value: '$matchedCount Matched / $unmatchedCount Unclaimed',
                  subtitle: 'Section F Audit Clearance',
                  icon: LucideIcons.shieldAlert,
                  color: unmatchedCount > 0 ? AppColors.crimsonRisk : AppColors.emeraldDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table Card
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
                      'Section F Import Customs Entry Schedule',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    if (customsMatches.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(LucideIcons.ship, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No Customs Entries Uploaded Yet',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Import KRA Customs C17 / SIMBA CSV dumps in the Data Ingestion Hub to begin Section F reconciliation.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.darkBg),
                          columns: const [
                            DataColumn(label: Text('Entry # (C17 / SAD)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Customs Station', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Importer PIN', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Taxable Value (KES)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Import VAT (KES)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ERP Invoice #', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status Tag', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          ],
                          rows: customsMatches.map((m) {
                            final c = m.customsRecord;
                            return DataRow(
                              cells: [
                                DataCell(Text(c.entryNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                DataCell(Text(c.customsStation, style: const TextStyle(color: AppColors.textSecondary))),
                                DataCell(Text(c.importerPin, style: const TextStyle(color: AppColors.kraGold))),
                                DataCell(Text('KES ${c.taxableValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white))),
                                DataCell(Text('KES ${c.importVatAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.mintAccent, fontWeight: FontWeight.bold))),
                                DataCell(Text(m.matchedErpRecord?.invoiceNumber ?? 'UNMATCHED', style: TextStyle(color: m.matchedErpRecord != null ? Colors.white : AppColors.crimsonRisk))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(m.status).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _statusColor(m.status)),
                                    ),
                                    child: Text(
                                      m.status.displayName,
                                      style: TextStyle(
                                        color: _statusColor(m.status),
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

  Color _statusColor(CustomsMatchStatus status) {
    switch (status) {
      case CustomsMatchStatus.matched:
        return AppColors.emeraldDark;
      case CustomsMatchStatus.unclaimedImportVat:
        return AppColors.kraGold;
      case CustomsMatchStatus.valuationVariance:
        return AppColors.warningOrange;
      case CustomsMatchStatus.missingInBooks:
        return AppColors.crimsonRisk;
    }
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
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
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
