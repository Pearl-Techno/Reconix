import 'package:csv/csv.dart';
import '../models/invoice_record.dart';

class ErpConnectorService {
  /// Ingests Tally Prime / ERP 9 XML dumps
  static List<InvoiceRecord> parseTallyXml({
    required String xmlContent,
    required String defaultTaxPeriod,
  }) {
    final List<InvoiceRecord> records = [];
    final voucherRegex = RegExp(r'<VOUCHER[^>]*>([\s\S]*?)<\/VOUCHER>');
    final matches = voucherRegex.allMatches(xmlContent);

    int index = 1;
    for (var m in matches) {
      final voucherSnippet = m.group(1) ?? '';
      
      final invNoMatch = RegExp(r'<VOUCHERNUMBER>(.*?)<\/VOUCHERNUMBER>').firstMatch(voucherSnippet);
      final partyMatch = RegExp(r'<PARTYLEDGERNAME>(.*?)<\/PARTYLEDGERNAME>').firstMatch(voucherSnippet);
      final amountMatch = RegExp(r'<AMOUNT>(.*?)<\/AMOUNT>').firstMatch(voucherSnippet);

      final invNo = invNoMatch?.group(1)?.trim() ?? 'TALLY-$index';
      final partyName = partyMatch?.group(1)?.trim() ?? 'Tally Party $index';
      final rawAmount = double.tryParse(amountMatch?.group(1) ?? '0.0') ?? 0.0;

      final taxable = rawAmount.abs() / 1.16;
      final vat = rawAmount.abs() - taxable;

      final vchUpper = voucherSnippet.toUpperCase();
      final isPurchase = vchUpper.contains('PURCHASE') ||
          vchUpper.contains('BILL') ||
          vchUpper.contains('EXPENSE') ||
          vchUpper.contains('VENDOR') ||
          vchUpper.contains('SUPPLIER') ||
          vchUpper.contains('SEC B') ||
          vchUpper.contains('INPUT');

      records.add(InvoiceRecord(
        id: 'TALLY-$index-${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: invNo,
        supplierPin: 'P051999888Z',
        supplierName: partyName,
        buyerPin: 'P051284920A',
        buyerName: 'Apex Enterprises',
        invoiceDate: DateTime.now(),
        taxPeriod: defaultTaxPeriod,
        taxableAmount: taxable,
        vatAmount: vat,
        totalAmount: rawAmount.abs(),
        sourceType: SourceType.erp,
        sectionType: isPurchase ? SectionType.sectionBPurchases : SectionType.sectionASales,
        itemDescription: 'Tally Prime Voucher Entry',
      ));
      index++;
    }
    return records;
  }

  /// Ingests QuickBooks Online & Desktop CSV exports
  static List<InvoiceRecord> parseQuickBooksCsv({
    required String csvContent,
    required String defaultTaxPeriod,
  }) {
    final sanitizedCsv = csvContent.replaceAll('\r\n', '\n');
    final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(sanitizedCsv);
    if (rows.isEmpty) return [];

    final List<InvoiceRecord> records = [];
    final bool isCsvPurchase = csvContent.toLowerCase().contains('purchase') ||
        csvContent.toLowerCase().contains('vendor') ||
        csvContent.toLowerCase().contains('supplier') ||
        csvContent.toLowerCase().contains('bill') ||
        csvContent.toLowerCase().contains('expense');

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4 || row.every((c) => c.toString().trim().isEmpty)) continue;

      final invNo = row[0].toString().trim();
      final vendor = row.length > 1 ? row[1].toString().trim() : 'Vendor $i';
      final pin = row.length > 2 ? row[2].toString().trim() : 'P051987654Z';
      final total = row.length > 3 ? (double.tryParse(row[3].toString().replaceAll(',', '')) ?? 0.0) : 0.0;
      final vat = total * (0.16 / 1.16);
      final taxable = total - vat;

      final rowUpper = row.join(' ').toUpperCase();
      final isRowPurchase = isCsvPurchase ||
          rowUpper.contains('PURCHASE') ||
          rowUpper.contains('VENDOR') ||
          rowUpper.contains('SUPPLIER') ||
          rowUpper.contains('BILL') ||
          rowUpper.contains('EXPENSE');

      records.add(InvoiceRecord(
        id: 'QB-$i-${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: invNo.isNotEmpty ? invNo : 'QB-INV-$i',
        supplierPin: pin,
        supplierName: vendor,
        buyerPin: 'P051284920A',
        buyerName: 'Apex Enterprises',
        invoiceDate: DateTime.now(),
        taxPeriod: defaultTaxPeriod,
        taxableAmount: taxable,
        vatAmount: vat,
        totalAmount: total,
        sourceType: SourceType.erp,
        sectionType: isRowPurchase ? SectionType.sectionBPurchases : SectionType.sectionASales,
        itemDescription: 'QuickBooks Ingested Journal',
      ));
    }
    return records;
  }
}
