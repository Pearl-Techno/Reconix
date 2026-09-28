import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/taxpayer_client.dart';

class VatApportionmentResult {
  final double taxableSales16Percent;
  final double zeroRatedSales;
  final double exemptSales;
  final double totalSales;
  final double totalInputVatPaid;

  final double apportionmentRatio; // Percentage (0 - 100)
  final bool is100PercentClaimable; // > 90%
  final bool is0PercentClaimable; // < 10%
  final double claimableInputVat;
  final double nonDeductibleInputVat;
  final String complianceAdvice;

  const VatApportionmentResult({
    required this.taxableSales16Percent,
    required this.zeroRatedSales,
    required this.exemptSales,
    required this.totalSales,
    required this.totalInputVatPaid,
    required this.apportionmentRatio,
    required this.is100PercentClaimable,
    required this.is0PercentClaimable,
    required this.claimableInputVat,
    required this.nonDeductibleInputVat,
    required this.complianceAdvice,
  });
}

class VatApportionmentService {
  /// Calculates Section 17 Partial Exemption Apportionment ratio and deductible input VAT
  static VatApportionmentResult calculate({
    required double taxableSales16Percent,
    required double zeroRatedSales,
    required double exemptSales,
    required double totalInputVatPaid,
  }) {
    final taxableTotal = taxableSales16Percent + zeroRatedSales;
    final totalSales = taxableTotal + exemptSales;

    if (totalSales <= 0) {
      return const VatApportionmentResult(
        taxableSales16Percent: 0,
        zeroRatedSales: 0,
        exemptSales: 0,
        totalSales: 0,
        totalInputVatPaid: 0,
        apportionmentRatio: 100.0,
        is100PercentClaimable: true,
        is0PercentClaimable: false,
        claimableInputVat: 0,
        nonDeductibleInputVat: 0,
        complianceAdvice: 'Zero turnover reported. Standard 100% input VAT claim applies.',
      );
    }

    final rawRatio = (taxableTotal / totalSales) * 100.0;
    bool is100 = false;
    bool is0 = false;
    double effectiveRatio = rawRatio;
    double claimable = 0;
    double nonDeductible = 0;
    String advice = '';

    if (rawRatio > 90.0) {
      is100 = true;
      effectiveRatio = 100.0;
      claimable = totalInputVatPaid;
      nonDeductible = 0.0;
      advice = 'Section 17 De Minimis Exemption: Taxable supplies exceed 90% of total turnover. Taxpayer is entitled to claim 100% of input VAT.';
    } else if (rawRatio < 10.0) {
      is0 = true;
      effectiveRatio = 0.0;
      claimable = 0.0;
      nonDeductible = totalInputVatPaid;
      advice = 'Section 17 Restriction: Taxable supplies are under 10% of total turnover. Input VAT is 100% non-deductible and must be expensed.';
    } else {
      claimable = totalInputVatPaid * (rawRatio / 100.0);
      nonDeductible = totalInputVatPaid - claimable;
      advice = 'Pro-Rata Apportionment Applied: Taxpayer can claim ${rawRatio.toStringAsFixed(2)}% of total input VAT (KES ${claimable.toStringAsFixed(2)}). Balance (KES ${nonDeductible.toStringAsFixed(2)}) is non-deductible expense.';
    }

    return VatApportionmentResult(
      taxableSales16Percent: taxableSales16Percent,
      zeroRatedSales: zeroRatedSales,
      exemptSales: exemptSales,
      totalSales: totalSales,
      totalInputVatPaid: totalInputVatPaid,
      apportionmentRatio: effectiveRatio,
      is100PercentClaimable: is100,
      is0PercentClaimable: is0,
      claimableInputVat: claimable,
      nonDeductibleInputVat: nonDeductible,
      complianceAdvice: advice,
    );
  }

  /// Generates Section 17 Partial Exemption Audit Certificate PDF
  static Future<Uint8List> generateApportionmentPdf({
    required TaxpayerClient client,
    required String taxPeriod,
    required VatApportionmentResult result,
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0.00');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RECONIX KENYA - TAX AUDIT EVIDENCE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                      pw.Text('Section 17 Partial VAT Exemption Apportionment Certificate', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(color: PdfColors.amber100, borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Text('SEC 17 VAT ACT 2013', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),

              // Taxpayer metadata
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TAXPAYER NAME: ${client.businessName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('KRA PIN: ${client.kraPin}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TAX PERIOD: $taxPeriod', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('DATE: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Text('TURNOVER BREAKDOWN & RATIO ANALYSIS', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                headers: ['Sales Category', 'Turnover Amount (KES)', 'Turnover % Share'],
                data: [
                  ['16% Taxable Standard Sales', fmt.format(result.taxableSales16Percent), '${(result.totalSales > 0 ? (result.taxableSales16Percent / result.totalSales * 100) : 0).toStringAsFixed(2)}%'],
                  ['0% Zero-Rated Export / Local Sales', fmt.format(result.zeroRatedSales), '${(result.totalSales > 0 ? (result.zeroRatedSales / result.totalSales * 100) : 0).toStringAsFixed(2)}%'],
                  ['Exempt Supplies (Financial / Exempt)', fmt.format(result.exemptSales), '${(result.totalSales > 0 ? (result.exemptSales / result.totalSales * 100) : 0).toStringAsFixed(2)}%'],
                  ['TOTAL GROSS TURNOVER', fmt.format(result.totalSales), '100.00%'],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              ),

              pw.SizedBox(height: 20),
              pw.Text('INPUT VAT DEDUCTIBILITY SUMMARY', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              pw.SizedBox(height: 8),

              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(
                  children: [
                    _pdfMetricRow('Total Invoiced Input VAT Paid:', 'KES ${fmt.format(result.totalInputVatPaid)}'),
                    pw.SizedBox(height: 6),
                    _pdfMetricRow('Section 17 Apportionment Ratio:', '${result.apportionmentRatio.toStringAsFixed(2)}%'),
                    pw.SizedBox(height: 6),
                    _pdfMetricRow('ALLOWABLE INPUT VAT (Claimable on iTax):', 'KES ${fmt.format(result.claimableInputVat)}', isBold: true, color: PdfColors.green800),
                    pw.SizedBox(height: 6),
                    _pdfMetricRow('DISALLOWED INPUT VAT (Expensed):', 'KES ${fmt.format(result.nonDeductibleInputVat)}', isBold: true, color: PdfColors.red800),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: PdfColors.blue300)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('AUDIT & COMPLIANCE FINDING', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                    pw.SizedBox(height: 4),
                    pw.Text(result.complianceAdvice, style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue900)),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Reconix VAT Engine', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('ICPAK Auditor Compliance Standard', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfMetricRow(String label, String val, {bool isBold = false, PdfColor color = PdfColors.black}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        pw.Text(val, style: pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
      ],
    );
  }
}
