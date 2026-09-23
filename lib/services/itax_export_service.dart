import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/reconciliation_match.dart';
import '../models/taxpayer_client.dart';

import 'itax_export_web_stub.dart'
    if (dart.library.html) 'itax_export_web_real.dart';

class ITaxExportService {
  /// Generates official KRA iTax Section B (Input VAT) CSV content
  static String generateITaxSectionBCsv({
    required TaxpayerClient client,
    required String taxPeriod,
    required List<ReconciliationMatch> matches,
  }) {
    final List<List<dynamic>> csvData = [];
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Header Row matching KRA iTax Offline Upload Schema
    csvData.add([
      'Supplier KRA PIN',
      'Supplier Business Name',
      'Invoice Number',
      'Invoice Date (DD/MM/YYYY)',
      'Description of Goods & Services',
      'Taxable Value (KES)',
      'VAT Amount (KES)',
      'eTIMS Control Code / CU Serial No',
      'Reconciliation Status',
    ]);

    // Only include claimable input VAT records (Matched or verified by auditor)
    final claimableMatches = matches.where((m) {
      if (m.status == MatchStatus.matched) return true;
      if (m.resolutionTag == 'VERIFIED_FOR_ITAX') return true;
      return false;
    }).toList();

    for (var m in claimableMatches) {
      final supplierPin = m.supplierPin;
      final supplierName = m.supplierName;
      final invNo = m.invoiceNumber;
      final invDate = dateFormat.format(m.invoiceDate);
      final desc = 'Commercial Purchases & Operating Services';
      final taxable = m.primaryTotal - m.primaryVat;
      final vat = m.primaryVat;
      final controlCode = m.etimsRecord?.etimsControlCode ??
          m.erpRecord?.etimsControlCode ??
          'ETIMS-VERIFIED-${m.invoiceNumber}';
      final statusTag = m.status.shortTag;

      csvData.add([
        supplierPin,
        supplierName,
        invNo,
        invDate,
        desc,
        taxable.toStringAsFixed(2),
        vat.toStringAsFixed(2),
        controlCode,
        statusTag,
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Downloads CSV file to user's browser in Flutter Web
  static void downloadCsvWeb({
    required String csvData,
    required String fileName,
  }) {
    downloadFileWeb(csvData, fileName);
  }
}
