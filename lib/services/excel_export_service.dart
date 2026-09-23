import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/reconciliation_match.dart';
import '../models/taxpayer_client.dart';
import '../models/whvat_record.dart';

class ExcelExportService {
  /// Generates a comprehensive multi-tab Excel (.xlsx) Audit Ledger workbook
  static List<int>? generateAuditLedgerExcel({
    required TaxpayerClient client,
    required String taxPeriod,
    required List<ReconciliationMatch> matches,
    List<WhvatRecord> whvatRecords = const [],
  }) {
    final excel = Excel.createExcel();

    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Remove default sheet
    excel.rename('Sheet1', 'Executive Summary');

    // 1. SHEET 1: Executive Summary
    final Sheet summarySheet = excel['Executive Summary'];
    summarySheet.appendRow([TextCellValue('RECONIX 3-WAY VAT AUDIT & VAA EXPOSURE REPORT')]);
    summarySheet.appendRow([TextCellValue('Taxpayer Name:'), TextCellValue(client.businessName)]);
    summarySheet.appendRow([TextCellValue('KRA PIN:'), TextCellValue(client.kraPin)]);
    summarySheet.appendRow([TextCellValue('Tax Period:'), TextCellValue(taxPeriod)]);
    summarySheet.appendRow([TextCellValue('Generated At:'), TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()))]);
    summarySheet.appendRow([]);

    final totalMatched = matches.where((m) => m.status == MatchStatus.matched).length;
    final totalVaaRisk = matches.where((m) => m.status == MatchStatus.vaaDisallowanceRisk).length;
    final totalClaimableVat = matches.where((m) => m.status == MatchStatus.matched).fold(0.0, (sum, m) => sum + m.primaryVat);
    final totalVatAtRisk = matches.where((m) => m.status == MatchStatus.unclaimedInputVat || m.status == MatchStatus.vaaDisallowanceRisk).fold(0.0, (sum, m) => sum + m.claimableVatAtRisk);

    summarySheet.appendRow([TextCellValue('COMPLIANCE KPI METRIC'), TextCellValue('VALUE')]);
    summarySheet.appendRow([TextCellValue('Total Audited Invoices'), IntCellValue(matches.length)]);
    summarySheet.appendRow([TextCellValue('Fully Matched 3-Way Invoices'), IntCellValue(totalMatched)]);
    summarySheet.appendRow([TextCellValue('Critical VAA Penalty Risk Invoices'), IntCellValue(totalVaaRisk)]);
    summarySheet.appendRow([TextCellValue('Verified Safe Claimable Input VAT (KES)'), TextCellValue(currencyFormat.format(totalClaimableVat))]);
    summarySheet.appendRow([TextCellValue('Input VAT Exposure at Risk (KES)'), TextCellValue(currencyFormat.format(totalVatAtRisk))]);

    // 2. SHEET 2: Section B Verified Input VAT
    final Sheet verifiedSheet = excel['Section B Verified VAT'];
    verifiedSheet.appendRow([
      TextCellValue('Match ID'),
      TextCellValue('Invoice Number'),
      TextCellValue('Invoice Date'),
      TextCellValue('Supplier Name'),
      TextCellValue('Supplier PIN'),
      TextCellValue('Match Status'),
      TextCellValue('ERP Total (KES)'),
      TextCellValue('eTIMS Total (KES)'),
      TextCellValue('iTax Total (KES)'),
      TextCellValue('Claimable Input VAT (KES)'),
    ]);

    final safeMatches = matches.where((m) => m.status == MatchStatus.matched || m.status == MatchStatus.timingLatency);
    for (var m in safeMatches) {
      verifiedSheet.appendRow([
        TextCellValue(m.matchId),
        TextCellValue(m.invoiceNumber),
        TextCellValue(dateFormat.format(m.invoiceDate)),
        TextCellValue(m.supplierName),
        TextCellValue(m.supplierPin),
        TextCellValue(m.status.shortTag),
        DoubleCellValue(m.erpRecord?.totalAmount ?? 0.0),
        DoubleCellValue(m.etimsRecord?.totalAmount ?? 0.0),
        DoubleCellValue(m.itaxRecord?.totalAmount ?? 0.0),
        DoubleCellValue(m.primaryVat),
      ]);
    }

    // 3. SHEET 3: VAA Risk Exposure
    final Sheet vaaSheet = excel['VAA Risk Exposure'];
    vaaSheet.appendRow([
      TextCellValue('Match ID'),
      TextCellValue('Invoice Number'),
      TextCellValue('Supplier Name'),
      TextCellValue('Supplier PIN'),
      TextCellValue('Risk Level'),
      TextCellValue('Claimable VAT at Risk (KES)'),
      TextCellValue('Income Tax Disallowance (KES)'),
      TextCellValue('Recommendation & Action Plan'),
    ]);

    final riskMatches = matches.where((m) => m.riskLevel == RiskLevel.critical || m.riskLevel == RiskLevel.high);
    for (var m in riskMatches) {
      vaaSheet.appendRow([
        TextCellValue(m.matchId),
        TextCellValue(m.invoiceNumber),
        TextCellValue(m.supplierName),
        TextCellValue(m.supplierPin),
        TextCellValue(m.riskLevel.name.toUpperCase()),
        DoubleCellValue(m.claimableVatAtRisk),
        DoubleCellValue(m.incomeTaxDisallowanceRisk),
        TextCellValue(m.actionPlan),
      ]);
    }

    // 4. SHEET 4: WHVAT 2% Certificates
    if (whvatRecords.isNotEmpty) {
      final Sheet whvatSheet = excel['WHVAT 2% Certificates'];
      whvatSheet.appendRow([
        TextCellValue('Certificate #'),
        TextCellValue('Invoice #'),
        TextCellValue('Certificate Date'),
        TextCellValue('Supplier Name'),
        TextCellValue('Supplier PIN'),
        TextCellValue('Gross Invoice Amount (KES)'),
        TextCellValue('Withheld VAT 2% (KES)'),
        TextCellValue('iTax Status'),
      ]);

      for (var w in whvatRecords) {
        whvatSheet.appendRow([
          TextCellValue(w.certificateNumber),
          TextCellValue(w.invoiceNumber),
          TextCellValue(dateFormat.format(w.certificateDate)),
          TextCellValue(w.supplierName),
          TextCellValue(w.supplierPin),
          DoubleCellValue(w.grossInvoiceAmount),
          DoubleCellValue(w.whvatAmount),
          TextCellValue(w.isClaimedOnItax ? 'CLAIMED ON ITAX' : 'UNCLAIMED'),
        ]);
      }
    }

    return excel.encode();
  }
}
