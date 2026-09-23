import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/invoice_record.dart';
import '../../providers/app_state.dart';
import '../../services/pre_filing_validation_engine.dart';
import '../../services/itax_filing_bundle_service.dart';
import '../../services/itax_export_service.dart';
import '../../theme/app_theme.dart';

class ITaxFilingBundleDialog extends StatelessWidget {
  const ITaxFilingBundleDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ITaxFilingBundleDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final report = PreFilingValidationEngine.validateReturn(
      salesRecords: state.erpRecords.where((r) => r.sectionType == SectionType.sectionASales).toList(),
      purchaseRecords: state.erpRecords.where((r) => r.sectionType == SectionType.sectionBPurchases).toList(),
      customsEntries: state.customsEntries,
      whvatRecords: state.whvatRecords,
    );

    final bundle = ITaxFilingBundleService.generateFilingBundle(
      client: state.activeClient,
      taxPeriod: state.selectedTaxPeriod,
      salesRecords: state.erpRecords.where((r) => r.sectionType == SectionType.sectionASales).toList(),
      purchaseRecords: state.erpRecords.where((r) => r.sectionType == SectionType.sectionBPurchases).toList(),
      customsEntries: state.customsEntries,
      whvatRecords: state.whvatRecords,
    );

    return AlertDialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.darkBorder)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.fileSpreadsheet, color: AppColors.mintAccent, size: 22),
              SizedBox(width: 10),
              Text('KRA iTax Form VAT 7 Filing Bundle', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: report.isReadyForFiling ? AppColors.emeraldDark.withValues(alpha: 0.2) : AppColors.crimsonRisk.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: report.isReadyForFiling ? AppColors.mintAccent : AppColors.crimsonRisk),
            ),
            child: Text(
              report.isReadyForFiling ? 'PASSED PRE-FLIGHT AUDIT' : 'ATTENTION REQUIRED',
              style: TextStyle(
                color: report.isReadyForFiling ? AppColors.mintAccent : AppColors.crimsonRisk,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pre-flight audit validated ${report.totalRecordsAudited} records for ${state.activeClient.businessName} (${state.selectedTaxPeriod}).',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Diagnostics Box
              if (report.issues.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.alertTriangle, color: AppColors.kraGold, size: 16),
                          const SizedBox(width: 6),
                          Text('Pre-Flight Diagnostics (${report.errorCount} Errors, ${report.warningCount} Warnings)', style: const TextStyle(color: AppColors.kraGold, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...report.issues.take(5).map((iss) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                iss.severity == ValidationSeverity.error ? LucideIcons.xCircle : LucideIcons.alertCircle,
                                color: iss.severity == ValidationSeverity.error ? AppColors.crimsonRisk : AppColors.kraGold,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '[${iss.section}] ${iss.message}',
                                  style: TextStyle(color: iss.severity == ValidationSeverity.error ? AppColors.crimsonRisk : Colors.white70, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // 4-in-1 Download Schedule Grid
              const Text('Download Form VAT 7 Return Schedules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _scheduleButton(
                    context,
                    title: 'Section A (Sales)',
                    subtitle: 'Output VAT Schedule',
                    icon: LucideIcons.trendingUp,
                    color: AppColors.infoBlue,
                    onTap: () {
                      ITaxExportService.downloadCsvWeb(
                        csvData: bundle.sectionACsv,
                        fileName: 'KRA_VAT7_SectionA_Sales_${state.activeClient.kraPin}.csv',
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _scheduleButton(
                    context,
                    title: 'Section B (Purchases)',
                    subtitle: 'Input VAT Schedule',
                    icon: LucideIcons.shoppingBag,
                    color: AppColors.mintAccent,
                    onTap: () {
                      ITaxExportService.downloadCsvWeb(
                        csvData: bundle.sectionBCsv,
                        fileName: 'KRA_VAT7_SectionB_Purchases_${state.activeClient.kraPin}.csv',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _scheduleButton(
                    context,
                    title: 'Section C (Imports)',
                    subtitle: 'Customs C17 Entry Schedule',
                    icon: LucideIcons.ship,
                    color: AppColors.kraGold,
                    onTap: () {
                      ITaxExportService.downloadCsvWeb(
                        csvData: bundle.sectionCCsv,
                        fileName: 'KRA_VAT7_SectionC_Imports_${state.activeClient.kraPin}.csv',
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _scheduleButton(
                    context,
                    title: 'Section D (2% WHVAT)',
                    subtitle: 'Withholding Credit Schedule',
                    icon: LucideIcons.fileCheck,
                    color: Colors.purpleAccent,
                    onTap: () {
                      ITaxExportService.downloadCsvWeb(
                        csvData: bundle.sectionDCsv,
                        fileName: 'KRA_VAT7_SectionD_WHVAT_${state.activeClient.kraPin}.csv',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _scheduleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.download, color: AppColors.textMuted, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
