import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:intl/intl.dart';
import '../models/invoice_record.dart';
import '../models/whvat_record.dart';
import '../models/audit_log_entry.dart';

class AuditDefensePackService {
  /// Generates a PDF Audit Defense Binder document
  static Future<Uint8List> generateAuditDefensePdf({
    required String businessName,
    required String kraPin,
    required String taxPeriod,
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> etimsRecords,
    required List<WhvatRecord> whvatRecords,
    required List<AuditLogEntry> auditLogs,
    required String userRole,
    required bool isLocked,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    final erpTotalVat = erpRecords.fold(0.0, (sum, r) => sum + r.vatAmount);
    final etimsTotalVat = etimsRecords.fold(0.0, (sum, r) => sum + r.vatAmount);
    final vaaRiskVat = erpRecords.where((r) => !r.hasEtimsVerification).fold(0.0, (sum, r) => sum + r.vatAmount);
    final whvatTotal = whvatRecords.fold(0.0, (sum, r) => sum + r.whvatAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Title Bar
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RECONIX EXECUTIVE TAX AUDIT BINDER', style: pw.TextStyle(color: PdfColors.amber, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.SizedBox(height: 2),
                      pw.Text('KRA iTax VAT 7 Compliance & Verification Schedule', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PERIOD: $taxPeriod', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text('STATUS: ${isLocked ? "LOCKED & SIGNED" : "DRAFT AUDIT"}', style: pw.TextStyle(color: isLocked ? PdfColors.green300 : PdfColors.orange200, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Entity Details Table
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Taxpayer Name: $businessName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('KRA PIN: $kraPin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue800)),
                  pw.Text('Generated: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Executive Summary Table
            pw.Text('1. Executive Reconciliation Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Audit Metric Category', 'Invoice Count', 'Total Taxable (KES)', 'Total VAT (KES)'],
              data: [
                ['ERP Booked Input Claims', '${erpRecords.length}', currencyFormat.format(erpRecords.fold(0.0, (s, r) => s + r.taxableAmount)), currencyFormat.format(erpTotalVat)],
                ['eTIMS Verified Transmissions', '${etimsRecords.length}', currencyFormat.format(etimsRecords.fold(0.0, (s, r) => s + r.taxableAmount)), currencyFormat.format(etimsTotalVat)],
                ['VAA Disallowance Penalty Risk Pool', '${erpRecords.where((r) => !r.hasEtimsVerification).length}', currencyFormat.format(erpRecords.where((r) => !r.hasEtimsVerification).fold(0.0, (s, r) => s + r.taxableAmount)), currencyFormat.format(vaaRiskVat)],
                ['Section D 2% WHVAT Certificates', '${whvatRecords.length}', currencyFormat.format(whvatRecords.fold(0.0, (s, r) => s + r.grossInvoiceAmount)), currencyFormat.format(whvatTotal)],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: const pw.TextStyle(fontSize: 9),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            ),
            pw.SizedBox(height: 20),

            // VAA Risk Schedule
            pw.Text('2. Section B VAA Disallowance Risk Schedule (Missing eTIMS Codes)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
            pw.SizedBox(height: 6),
            if (erpRecords.where((r) => !r.hasEtimsVerification).isEmpty)
              pw.Text('Zero disallowance risk. 100% of claimed ERP input invoices possess valid eTIMS control codes.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.green800))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Inv #', 'Supplier Name', 'Supplier PIN', 'Date', 'VAT (KES)', 'Disallowance Threat'],
                data: erpRecords.where((r) => !r.hasEtimsVerification).take(10).map((r) {
                  return [
                    r.invoiceNumber,
                    r.supplierName,
                    r.supplierPin,
                    DateFormat('yyyy-MM-dd').format(r.invoiceDate),
                    currencyFormat.format(r.vatAmount),
                    'Missing eTIMS QR Transmission',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
                cellStyle: const pw.TextStyle(fontSize: 8),
              ),
            pw.SizedBox(height: 20),

            // Audit Trail Transcript
            pw.Text('3. Immutable Audit Log Transcript', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Timestamp', 'User Role', 'Action Executed', 'Log ID / Details'],
              data: auditLogs.take(8).map((log) {
                return [
                  DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp),
                  log.userRole.name,
                  log.action,
                  log.id,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 30),

            // Sign-off signature block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Prepared By: Tax Manager', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    pw.SizedBox(height: 15),
                    pw.Container(width: 150, height: 1, color: PdfColors.grey700),
                    pw.Text('Signature & Date', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Approved By: Senior Tax Partner / Auditor', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 15),
                    pw.Container(width: 150, height: 1, color: PdfColors.grey700),
                    pw.Text('Role: $userRole (${isLocked ? "LOCKED" : "UNLOCKED"})', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a multi-tab Excel Workbook for Audit Defense
  static Future<List<int>> generateAuditDefenseExcel({
    required String businessName,
    required String kraPin,
    required String taxPeriod,
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> etimsRecords,
    required List<WhvatRecord> whvatRecords,
    required List<AuditLogEntry> auditLogs,
  }) async {
    final excel = ex.Excel.createExcel();

    // Sheet 1: Executive Summary
    final sheet1 = excel['Executive Summary'];
    sheet1.appendRow([ex.TextCellValue('RECONIX VAT AUDIT DEFENSE BINDER')]);
    sheet1.appendRow([ex.TextCellValue('Taxpayer Name'), ex.TextCellValue(businessName)]);
    sheet1.appendRow([ex.TextCellValue('KRA PIN'), ex.TextCellValue(kraPin)]);
    sheet1.appendRow([ex.TextCellValue('Tax Period'), ex.TextCellValue(taxPeriod)]);
    sheet1.appendRow([ex.TextCellValue('')]);
    sheet1.appendRow([ex.TextCellValue('Metric Category'), ex.TextCellValue('Count'), ex.TextCellValue('Total Taxable KES'), ex.TextCellValue('Total VAT KES')]);

    final erpTaxable = erpRecords.fold(0.0, (s, r) => s + r.taxableAmount);
    final erpVat = erpRecords.fold(0.0, (s, r) => s + r.vatAmount);
    sheet1.appendRow([ex.TextCellValue('ERP Books Input Claims'), ex.IntCellValue(erpRecords.length), ex.DoubleCellValue(erpTaxable), ex.DoubleCellValue(erpVat)]);

    final etimsTaxable = etimsRecords.fold(0.0, (s, r) => s + r.taxableAmount);
    final etimsVat = etimsRecords.fold(0.0, (s, r) => s + r.vatAmount);
    sheet1.appendRow([ex.TextCellValue('eTIMS Verified Transmissions'), ex.IntCellValue(etimsRecords.length), ex.DoubleCellValue(etimsTaxable), ex.DoubleCellValue(etimsVat)]);

    // Sheet 2: ERP Purchase Ledger
    final sheet2 = excel['ERP Purchase Ledger'];
    sheet2.appendRow([
      ex.TextCellValue('Invoice Number'),
      ex.TextCellValue('Supplier Name'),
      ex.TextCellValue('Supplier PIN'),
      ex.TextCellValue('Date'),
      ex.TextCellValue('Taxable KES'),
      ex.TextCellValue('VAT KES'),
      ex.TextCellValue('Total KES'),
      ex.TextCellValue('eTIMS Code'),
    ]);

    for (final r in erpRecords) {
      sheet2.appendRow([
        ex.TextCellValue(r.invoiceNumber),
        ex.TextCellValue(r.supplierName),
        ex.TextCellValue(r.supplierPin),
        ex.TextCellValue(DateFormat('yyyy-MM-dd').format(r.invoiceDate)),
        ex.DoubleCellValue(r.taxableAmount),
        ex.DoubleCellValue(r.vatAmount),
        ex.DoubleCellValue(r.totalAmount),
        ex.TextCellValue(r.etimsControlCode ?? ''),
      ]);
    }

    // Remove default sheet
    excel.delete('Sheet1');

    final List<int>? fileBytes = excel.save();
    return fileBytes ?? [];
  }
}
