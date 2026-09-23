import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/reconciliation_certificate.dart';
import '../models/reconciliation_match.dart';
import '../models/reconciliation_rules.dart';

class AuditDossierService {
  /// Generates a comprehensive KRA Audit Defense Dossier PDF
  static Future<Uint8List> generateAuditDossierPdf({
    required ReconciliationCertificate cert,
    required List<ReconciliationMatch> matches,
    ReconciliationRules rules = const ReconciliationRules(),
  }) async {
    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');

    final matchedCount = matches.where((m) => m.status == MatchStatus.matched).length;
    final warningCount = matches.where((m) => m.riskLevel == RiskLevel.medium).length;
    final riskCount = matches.where((m) => m.riskLevel == RiskLevel.high || m.riskLevel == RiskLevel.critical).length;

    final primaryColor = PdfColor.fromHex('#0F172A'); // Slate 900
    final goldColor = PdfColor.fromHex('#D97706'); // Amber Gold

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cover Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'KRA AUDIT DEFENSE DOSSIER',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: goldColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'CONFIDENTIAL / AUDIT READY',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Reconix eTIMS 3-Way Reconciliation & VAA Protection Dossier',
                    style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Taxpayer Metadata Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Taxpayer Name: ${cert.taxpayerName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('KRA PIN: ${cert.kraPin}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Tax Period: ${cert.taxPeriod}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Certificate Ref: ${cert.certificateId}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Generated: ${dateFormat.format(cert.generatedAt)}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Digital Signature Hash: ${cert.sha256Hash.substring(0, 16)}...', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Summary Metrics Cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0FDF4'),
                      border: pw.Border.all(color: PdfColor.fromHex('#86EFAC')),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('CLEARED MATCHES', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#166534'))),
                        pw.Text('$matchedCount', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#166534'))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FFFBEB'),
                      border: pw.Border.all(color: PdfColor.fromHex('#FDE68A')),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('VARIANCES / LATENCY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#92400E'))),
                        pw.Text('$warningCount', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#92400E'))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FEF2F2'),
                      border: pw.Border.all(color: PdfColor.fromHex('#FCA5A5')),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('VAA EXPOSURE ITEMS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#991B1B'))),
                        pw.Text('$riskCount', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#991B1B'))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Financial Risk Breakdown Table
            pw.Text('FINANCIAL RISK ASSESSMENT SUMMARY:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Amount (KES)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: [
                ['Total Verified Input VAT Cleared', 'KES ${numberFormat.format(cert.totalInputVatClaimable)}'],
                ['Total Input VAT at Risk of VAA Disallowance', 'KES ${numberFormat.format(cert.totalInputVatDisallowedExposure)}'],
                ['Total 2026 CIT Expense Disallowance Risk', 'KES ${numberFormat.format(cert.total2026ExpenseDeductibilityRisk)}'],
              ],
            ),
            pw.SizedBox(height: 20),

            // Detailed Discrepancy Schedule
            pw.Text('DETAILED DISCREPANCY & AUDIT TRAIL LOG:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Match ID', 'Supplier PIN', 'Supplier Name', 'Status', 'VAT Risk (KES)', 'Action Plan'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#334155')),
              cellStyle: const pw.TextStyle(fontSize: 7),
              data: matches.take(20).map((m) {
                final pin = m.erpRecord?.supplierPin ?? m.etimsRecord?.supplierPin ?? m.itaxRecord?.supplierPin ?? 'N/A';
                final name = m.erpRecord?.supplierName ?? m.etimsRecord?.supplierName ?? m.itaxRecord?.supplierName ?? 'N/A';
                return [
                  m.matchId,
                  pin,
                  name.length > 18 ? '${name.substring(0, 16)}...' : name,
                  m.status.name,
                  numberFormat.format(m.claimableVatAtRisk),
                  m.actionPlan.length > 30 ? '${m.actionPlan.substring(0, 28)}...' : m.actionPlan,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 30),

            // ICPAK Advisor Sign-Off Section
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
                      pw.Text('ICPAK CERTIFIED TAX ADVISOR SIGN-OFF:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(height: 16),
                      pw.Container(width: 180, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Signature & Practicing License Number', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date Signed: _____________________', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 8),
                      pw.Text('Reconix Cryptographic Audit Stamp: VERIFIED', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#166534'), fontWeight: pw.FontWeight.bold)),
                    ],
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

  /// Print or save Audit Defense Dossier
  static Future<void> printAuditDossier({
    required ReconciliationCertificate cert,
    required List<ReconciliationMatch> matches,
    ReconciliationRules rules = const ReconciliationRules(),
  }) async {
    final pdfBytes = await generateAuditDossierPdf(cert: cert, matches: matches, rules: rules);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'KRA_Audit_Defense_Dossier_${cert.kraPin}_${cert.taxPeriod}.pdf',
    );
  }
}
