import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/sample_templates_dialog.dart';

class WhvatReconciliationView extends StatelessWidget {
  const WhvatReconciliationView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final matches = state.whvatMatches;
    final totalWhvatAmount = state.whvatRecords.fold(0.0, (sum, r) => sum + r.whvatAmount);
    final matchedCount = matches.where((m) => m.isMatched).length;
    final unmatchedCount = matches.where((m) => !m.isMatched).length;

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
                          Icon(LucideIcons.fileCheck, color: AppColors.kraGold, size: 24),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Withholding VAT (WHVAT 2%) Certificate Ledger',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reconcile 2% Withholding VAT certificates deducted by appointed withholding agents against sales invoices.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => SampleTemplatesDialog.show(context),
                  icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                  label: const Text('Sample CSV Template', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kraGold,
                    side: const BorderSide(color: AppColors.kraGold),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => state.setActiveTab(3), // Navigate to Ingestion Hub
                  icon: const Icon(LucideIcons.uploadCloud, size: 16),
                  label: const Text('Import WHVAT Certificates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPI Cards Row
            Row(
              children: [
                _kpiCard(
                  title: 'TOTAL WHVAT CERTIFICATES',
                  value: '${state.whvatRecords.length}',
                  subtitle: 'Ingested 2% Credits',
                  icon: LucideIcons.fileText,
                  color: AppColors.infoBlue,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  title: 'TOTAL WHVAT CREDIT AMOUNT',
                  value: 'KES ${totalWhvatAmount.toStringAsFixed(2)}',
                  subtitle: 'Claimable on iTax Section D',
                  icon: LucideIcons.coins,
                  color: AppColors.kraGold,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  title: 'MATCHED CERTIFICATES',
                  value: '$matchedCount / ${state.whvatRecords.length}',
                  subtitle: 'Linked to Sales Invoices',
                  icon: LucideIcons.checkCircle2,
                  color: AppColors.emeraldDark,
                ),
                const SizedBox(width: 16),
                _kpiCard(
                  title: 'UNMATCHED / VARIANCE',
                  value: '$unmatchedCount',
                  subtitle: 'Requires Audit Review',
                  icon: LucideIcons.alertTriangle,
                  color: AppColors.crimsonRisk,
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
                      'WHVAT Certificate Auto-Match Schedule',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    if (state.whvatRecords.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(LucideIcons.fileQuestion, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No WHVAT 2% Certificates Uploaded Yet',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Import KRA WHVAT certificate CSV schedules in the Data Ingestion Hub to begin auto-matching.',
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
                            DataColumn(label: Text('Certificate #', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Withholding Agent PIN', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Agent Business Name', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Invoice #', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Gross Invoice (KES)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('2% WHVAT (KES)', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Match Status', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))),
                          ],
                          rows: matches.map((m) {
                            final r = m.whvatRecord;
                            return DataRow(
                              cells: [
                                DataCell(Text(r.certificateNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                DataCell(Text(r.buyerPin, style: const TextStyle(color: AppColors.kraGold))),
                                DataCell(Text(r.buyerName, style: const TextStyle(color: Colors.white))),
                                DataCell(Text(r.invoiceNumber, style: const TextStyle(color: AppColors.mintAccent))),
                                DataCell(Text('KES ${r.grossInvoiceAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white))),
                                DataCell(Text('KES ${r.whvatAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.kraGold, fontWeight: FontWeight.bold))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: m.isMatched ? AppColors.emeraldDark.withValues(alpha: 0.2) : AppColors.crimsonRisk.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: m.isMatched ? AppColors.emeraldDark : AppColors.crimsonRisk),
                                    ),
                                    child: Text(
                                      m.isMatched ? 'MATCHED' : 'UNMATCHED',
                                      style: TextStyle(
                                        color: m.isMatched ? AppColors.emeraldDark : AppColors.crimsonRisk,
                                        fontSize: 11,
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
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
