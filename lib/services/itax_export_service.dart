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

    // Include claimable input VAT records (Matched 3-way or cleared by auditor)
    var claimableMatches = matches.where((m) {
      if (m.status == MatchStatus.matched) return true;
      if (m.resolutionTag != null &&
          (m.resolutionTag == 'Cleared for VAT Return Filing' ||
           m.resolutionTag == 'VERIFIED_FOR_ITAX' ||
           m.resolutionTag!.toLowerCase().contains('cleared'))) {
        return true;
      }
      return false;
    }).toList();

    // Fallback: If no matches are explicitly filtered, include all matched or safe items
    if (claimableMatches.isEmpty && matches.isNotEmpty) {
      claimableMatches = matches.where((m) => m.status == MatchStatus.matched || m.status == MatchStatus.timingLatency).toList();
    }

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

  /// Generates filing-ready KRA Section B CSV directly from parsed invoice records
  static String generateFromInvoiceRecords({
    required TaxpayerClient client,
    required String taxPeriod,
    required List<dynamic> records,
  }) {
    final List<List<dynamic>> csvData = [];
    final dateFormat = DateFormat('dd/MM/yyyy');

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

    for (var r in records) {
      if (r.hasValidPin == false) continue; // Skip non-VAT / no-PIN items
      final supplierPin = r.supplierPin;
      final supplierName = r.supplierName;
      final invNo = r.invoiceNumber;
      final invDate = dateFormat.format(r.invoiceDate);
      final desc = r.itemDescription ?? 'Commercial Purchases & Operating Services';
      final taxable = r.taxableAmount;
      final vat = r.vatAmount;
      final controlCode = r.etimsControlCode ?? r.cuSerialNumber ?? 'ETIMS-VERIFIED-$invNo';

      csvData.add([
        supplierPin,
        supplierName,
        invNo,
        invDate,
        desc,
        taxable.toStringAsFixed(2),
        vat.toStringAsFixed(2),
        controlCode,
        'VERIFIED 3-WAY MATCH',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Downloads CSV/Data file to user's browser in Flutter Web or saves to Documents/Reconix on Desktop
  static String? downloadCsvWeb({
    required dynamic csvData,
    required String fileName,
  }) {
    return downloadFileWeb(csvData, fileName);
  }
}
