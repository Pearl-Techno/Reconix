import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class EvidencePackView extends StatelessWidget {
  const EvidencePackView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cert = state.generateCertificate();
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm:ss');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audit Evidence Hub & Reconciliation Certificates', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Generate non-mutable, timestamped audit evidence packs to defend input VAT claims against KRA VAA disallowances and Section 16(1) 2026 expense rules.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Primary Export Actions Banner Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.darkCard, AppColors.emeraldDark],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mintAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.shieldCheck, color: AppColors.mintAccent, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax Period: ${cert.taxPeriod} • Reconciliation Status: READY FOR DEFENSE',
                        style: const TextStyle(color: AppColors.mintAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Certificate ID: ${cert.certificateId}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SHA-256 Cryptographic Hash Digest: ${cert.sha256Hash}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Monospace'),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: state.isTaxPeriodLocked ? AppColors.mintAccent : AppColors.warningOrange,
                        side: BorderSide(color: state.isTaxPeriodLocked ? AppColors.mintAccent : AppColors.warningOrange),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      icon: Icon(state.isTaxPeriodLocked ? LucideIcons.lock : LucideIcons.unlock, size: 16),
                      label: Text(state.isTaxPeriodLocked ? 'Locked & Signed' : 'Sign-Off & Lock', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => state.toggleTaxPeriodLock(),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.infoBlue,
                        side: const BorderSide(color: AppColors.infoBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                      label: const Text('Export Excel Audit Pack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () async {
                        try {
                          final bytes = await state.generateAuditDefenseExcel();
                          final path = await FilePicker.platform.saveFile(
                            dialogTitle: 'Save Multi-Tab Excel Audit Pack',
                            fileName: 'reconix_vat_audit_pack_${state.selectedTaxPeriod}.xlsx',
                            type: FileType.custom,
                            allowedExtensions: ['xlsx'],
                          );
                          if (path != null && bytes.isNotEmpty) {
                            final file = File(path);
                            await file.writeAsBytes(bytes);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Saved Excel Audit Defense Pack to: $path'), backgroundColor: AppColors.emeraldPrimary),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error exporting Excel pack: $e'), backgroundColor: AppColors.crimsonRisk),
                            );
                          }
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.printer, size: 18),
                      label: const Text('PDF Audit Defense Binder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () async {
                        final pdfBytes = await state.generateAuditDefensePdf();
                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => pdfBytes,
                          name: 'reconix_audit_defense_binder_${state.selectedTaxPeriod}.pdf',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Certificate Preview Document Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Certificate Header Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(color: AppColors.mintAccent, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'RECONIX VAT EVIDENCE CERTIFICATE',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Issued pursuant to Tax Procedures Act & VAT Regulations 2026',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Generated: ${dateFormat.format(cert.generatedAt)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text('Advisor: ${cert.signedByAdvisor}', style: const TextStyle(color: AppColors.kraGold, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Taxpayer Profile Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _certMetaBox('TAXPAYER ENTITY', cert.taxpayerName),
                      _certMetaBox('KRA PIN NUMBER', cert.kraPin),
                      _certMetaBox('TAX PERIOD', cert.taxPeriod),
                      _certMetaBox('TOTAL PURCHASES (ERP)', 'KES ${numberFormat.format(cert.totalPurchasesErp)}'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Summary Metrics Breakdown Table
                  Text('Reconciliation Evidence Breakdown', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),

                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(2.5),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(6)),
                        children: [
                          _tableHeader('Reconciliation Category'),
                          _tableHeader('Invoice Count'),
                          _tableHeader('Financial Value (KES)'),
                        ],
                      ),
                      TableRow(
                        children: [
                          _tableCell('1. 3-Way Matched Input VAT (Cleared to Claim)'),
                          _tableCell('${cert.fullyMatchedCount} Invoices'),
                          _tableCell('KES ${numberFormat.format(cert.totalInputVatClaimable)}', color: AppColors.mintAccent, isBold: true),
                        ],
                      ),
                      TableRow(
                        children: [
                          _tableCell('2. Systemic Timing Latency (KRA Batch Queue)'),
                          _tableCell('${cert.timingLatencyCount} Invoices'),
                          _tableCell('Pending iTax Auto-Populate', color: AppColors.infoBlue),
                        ],
                      ),
                      TableRow(
                        children: [
                          _tableCell('3. Unclaimed Input VAT Risk (Omitted in iTax)'),
                          _tableCell('${cert.unclaimedInputVatCount} Invoices'),
                          _tableCell('KES ${numberFormat.format(cert.totalInputVatDisallowedExposure)}', color: AppColors.warningOrange, isBold: true),
                        ],
                      ),
                      TableRow(
                        children: [
                          _tableCell('4. VAA Penalty Exposure & 2026 Expense Risk'),
                          _tableCell('${cert.vaaDisallowanceCount + cert.expenseValidationRiskCount} Invoices'),
                          _tableCell('KES ${numberFormat.format(cert.total2026ExpenseDeductibilityRisk)}', color: AppColors.crimsonRisk, isBold: true),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Non-Mutability Digest Verification Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(LucideIcons.lock, color: AppColors.mintAccent, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'SHA-256 CRYPTOGRAPHIC INTEGRITY VERIFICATION DIGEST',
                                    style: TextStyle(color: AppColors.mintAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                cert.sha256Hash,
                                style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Monospace', fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(LucideIcons.copy, size: 14),
                          label: const Text('Copy Hash'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: cert.sha256Hash));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SHA-256 hash copied to clipboard!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _certMetaBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  static Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
    );
  }

  static Widget _tableCell(String text, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? AppColors.textPrimary,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
