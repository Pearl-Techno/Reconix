import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice_record.dart';

class VaaDemandNoticeService {
  /// Generates a PDF Demand Notice addressed to a non-compliant supplier
  static Future<Uint8List> generateDemandNoticePdf({
    required String supplierName,
    required String supplierPin,
    required String buyerName,
    required String buyerPin,
    required List<InvoiceRecord> unfiledInvoices,
    required DateTime deadlineDate,
  }) async {
    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMMM yyyy');

    final double totalVatAtRisk = unfiledInvoices.fold(0.0, (sum, i) => sum + i.vatAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // Header Bar
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#991B1B'), // Deep Crimson Red Warning
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FORMAL eTIMS COMPLIANCE & VAA DEMAND NOTICE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Pursuant to Kenya Tax Laws & KRA eTIMS Regulations',
                        style: pw.TextStyle(color: PdfColors.grey200, fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Text(
                    'URGENT',
                    style: pw.TextStyle(
                      color: PdfColors.amber300,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Metadata Grid
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TO (SUPPLIER DETAILS):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(supplierName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('KRA PIN: $supplierPin', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FROM (BUYER / CLAIMANT):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(buyerName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('KRA PIN: $buyerPin', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Date Issued: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Notice Body
            pw.Text(
              'RE: DEMAND FOR eTIMS INVOICE TRANSMISSION & VAA DISALLOWANCE PREVENTIVE NOTICE',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B')),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'We are writing to inform you that our automated KRA eTIMS reconciliation audit system (Reconix) has detected unmatched purchase transactions issued by your company without corresponding eTIMS electronic signatures transmitted to the Kenya Revenue Authority portal.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Under the Value Added Tax Act and Tax Procedures Act, failure to generate eTIMS invoices exposes us to KRA VAT Automated Assessment (VAA) disallowance of KES ${numberFormat.format(totalVatAtRisk)} in Input VAT, and potential 30% Corporate Income Tax expense disallowance under Section 16(1).',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 16),

            // Schedule Table
            pw.Text('SCHEDULE OF UNMATCHED / UNTRANSMITTED TRANSACTIONS:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Invoice / Ref No', 'Date', 'Taxable (KES)', 'VAT (16%) (KES)', 'Total (KES)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E293B')),
              cellStyle: const pw.TextStyle(fontSize: 8),
              data: List.generate(unfiledInvoices.length, (idx) {
                final inv = unfiledInvoices[idx];
                return [
                  (idx + 1).toString(),
                  inv.invoiceNumber,
                  dateFormat.format(inv.invoiceDate),
                  numberFormat.format(inv.taxableAmount),
                  numberFormat.format(inv.vatAmount),
                  numberFormat.format(inv.totalAmount),
                ];
              }),
            ),
            pw.SizedBox(height: 12),

            // Summary Totals Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FEF2F2'),
                border: pw.Border.all(color: PdfColor.fromHex('#FCA5A5')),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL INPUT VAT AT RISK OF DISALLOWANCE:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#991B1B'))),
                  pw.Text('KES ${numberFormat.format(totalVatAtRisk)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColor.fromHex('#991B1B'))),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Action Required & Deadline
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MANDATORY ACTION REQUIRED:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '1. Transmit the above invoices on your eTIMS / TIMS fiscal device to KRA immediately.\n'
                    '2. Provide eTIMS QR Control Codes for manual verification.\n'
                    '3. Resolve before the strict compliance deadline: ${dateFormat.format(deadlineDate)}.',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Sign-off
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Authorized Signature:', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 20),
                    pw.Container(width: 160, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Tax & Compliance Department', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(buyerName, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated by Reconix Audit System', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('Hash: ${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
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

  /// Directly displays preview/print dialog
  static Future<void> printDemandNotice({
    required String supplierName,
    required String supplierPin,
    required String buyerName,
    required String buyerPin,
    required List<InvoiceRecord> unfiledInvoices,
    required DateTime deadlineDate,
  }) async {
    final pdfBytes = await generateDemandNoticePdf(
      supplierName: supplierName,
      supplierPin: supplierPin,
      buyerName: buyerName,
      buyerPin: buyerPin,
      unfiledInvoices: unfiledInvoices,
      deadlineDate: deadlineDate,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'VAA_Demand_Notice_${supplierPin.replaceAll(RegExp(r'[^A-Z0-9]'), '')}.pdf',
    );
  }
}
