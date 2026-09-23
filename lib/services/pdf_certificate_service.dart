import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/reconciliation_certificate.dart';
import '../models/reconciliation_match.dart';

class PdfCertificateService {
  /// Generates printable PDF byte array for a Reconciliation Certificate
  static Future<Uint8List> generateCertificatePdf({
    required ReconciliationCertificate cert,
    required List<ReconciliationMatch> matches,
  }) async {
    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm:ss');

    final primaryColor = PdfColor.fromHex('#0F382C'); // Emerald Dark
    final accentColor = PdfColor.fromHex('#D97706'); // KRA Gold/Amber

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Title Bar
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RECONIX PLATFORM',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Kenyan eTIMS - ERP - iTax VAT Audit Evidence Certificate',
                        style: pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'AUDIT READY CERTIFICATE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ID: ${cert.certificateId}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Taxpayer Metadata Block
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Taxpayer Entity: ${cert.taxpayerName}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.SizedBox(height: 2),
                      pw.Text('KRA PIN: ${cert.kraPin}', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Text('Tax Period: ${cert.taxPeriod}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generated: ${dateFormat.format(cert.generatedAt)}', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 2),
                      pw.Text('Signed Advisor: ${cert.signedByAdvisor}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('SHA-256 Hash Digest: ${cert.sha256Hash.substring(0, 16)}...', style: pw.TextStyle(fontSize: 8, color: primaryColor, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Metrics Summary Grid
            pw.Text('1. Executive Reconciliation Metrics Summary',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Metric Category', 'Record Count', 'Financial Amount (KES)'],
              data: [
                ['Total ERP Booked Purchases', '${cert.totalErpRecordsCount} Invoices', 'KES ${numberFormat.format(cert.totalPurchasesErp)}'],
                ['3-Way Fully Matched (Cleared to File)', '${cert.fullyMatchedCount} Invoices', 'KES ${numberFormat.format(cert.totalInputVatClaimable)} (Claimable VAT)'],
                ['Systemic Timing Latency (Batch Delay)', '${cert.timingLatencyCount} Invoices', 'Pending iTax Auto-Populate'],
                ['Unclaimed Input VAT Risk (Omitted in iTax)', '${cert.unclaimedInputVatCount} Invoices', 'KES ${numberFormat.format(cert.totalInputVatDisallowedExposure)} (At Risk)'],
                ['VAA Penalty & 2026 Expense Risk', '${cert.vaaDisallowanceCount + cert.expenseValidationRiskCount} Invoices', 'KES ${numberFormat.format(cert.total2026ExpenseDeductibilityRisk)} (Deduction Exposure)'],
                ['Section 16(1) 30% Corp Tax Risk', 'Tax Laws Amendment 2026', 'KES ${numberFormat.format(cert.total2026ExpenseDeductibilityRisk * 0.30)} (Income Tax Liability)'],
              ],
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            pw.SizedBox(height: 20),

            // Variance & Exception Schedule Table
            pw.Text('2. Variance & Exception Schedule (KRA VAA Audit Evidence)',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: ['Match ID', 'Invoice #', 'Supplier Name & PIN', 'Total (KES)', 'VAT (KES)', 'Status Category', 'Risk Level'],
              data: matches.where((m) => m.status != MatchStatus.matched).map((m) {
                return [
                  m.matchId,
                  m.invoiceNumber,
                  '${m.supplierName}\n${m.supplierPin}',
                  'KES ${numberFormat.format(m.primaryTotal)}',
                  'KES ${numberFormat.format(m.primaryVat)}',
                  m.status.shortTag,
                  m.riskLevel.name.toUpperCase(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            ),
            pw.SizedBox(height: 24),

            // Sign-off & Verification Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CERTIFICATE VALIDATION & NON-MUTABILITY NOTICE:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: primaryColor)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'This Reconciliation Certificate and Evidence Schedule is cryptographically hashed with SHA-256 (${cert.sha256Hash}). '
                    'It serves as an independent, read-only proof of taxpayer input VAT matching for filing defendability against KRA Value Added Automated Audit (VAA) disallowances and Section 16(1) 2026 expense validation.',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Triggers browser/system print modal for PDF certificate
  static Future<void> printCertificate({
    required ReconciliationCertificate cert,
    required List<ReconciliationMatch> matches,
  }) async {
    final pdfBytes = await generateCertificatePdf(cert: cert, matches: matches);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Reconix_Certificate_${cert.taxpayerName.replaceAll(' ', '_')}_${cert.taxPeriod}.pdf',
    );
  }
}
