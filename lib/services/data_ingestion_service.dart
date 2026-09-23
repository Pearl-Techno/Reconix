import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart';
import '../models/invoice_record.dart';
import '../models/whvat_record.dart';
import '../models/customs_entry_record.dart';

CsvIngestionResult _parseAnyFileIsolateEntryPoint(Map<String, dynamic> args) {
  final filePath = args['filePath'] as String;
  final bytes = args['bytes'] as List<int>;
  final sourceType = SourceType.values[args['sourceTypeIndex'] as int];
  final defaultTaxPeriod = args['defaultTaxPeriod'] as String;

  return DataIngestionService.parseAnyFile(
    filePath: filePath,
    bytes: bytes,
    sourceType: sourceType,
    defaultTaxPeriod: defaultTaxPeriod,
  );
}

enum CsvIssueSeverity { info, warning, error }

class CsvLineIssue {
  final int lineNumber;
  final String rawLineSnippet;
  final CsvIssueSeverity severity;
  final String description;

  const CsvLineIssue({
    required this.lineNumber,
    required this.rawLineSnippet,
    required this.severity,
    required this.description,
  });
}

class CsvIngestionResult {
  final SourceType sourceType;
  final int totalLinesRead;
  final int successCount;
  final int warningCount;
  final int errorCount;
  final List<InvoiceRecord> records;
  final List<CsvLineIssue> issues;

  const CsvIngestionResult({
    required this.sourceType,
    required this.totalLinesRead,
    required this.successCount,
    required this.warningCount,
    required this.errorCount,
    required this.records,
    required this.issues,
  });

  bool get hasIssues => issues.isNotEmpty;

  int get recordsWithPinCount => records.where((r) => r.hasValidPin).length;
  int get recordsNoPinCount => records.where((r) => r.isNonVatNoPin).length;

  double get totalTaxableWithPin => records.where((r) => r.hasValidPin).fold(0.0, (sum, r) => sum + r.taxableAmount);
  double get totalTaxableNoPin => records.where((r) => r.isNonVatNoPin).fold(0.0, (sum, r) => sum + r.taxableAmount);
}

class DataIngestionService {
  /// Helper to parse date strings formatted as YYYY-MM-DD or DD/MM/YYYY
  static DateTime? parseDateExact(String input) {
    final str = input.trim();
    if (str.isEmpty) return null;

    final iso = DateTime.tryParse(str);
    if (iso != null) return iso;

    final parts = str.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }

  static DateTime parseDate(String input) {
    return parseDateExact(input) ?? DateTime.now();
  }

  /// Sanitizes control codes/invoice numbers by stripping leading pipes '|' or spaces
  static String sanitizeControlCode(String input) {
    var s = input.trim();
    if (s.startsWith('|')) {
      s = s.substring(1).trim();
    }
    return s;
  }

  /// Parses CSV string into InvoiceRecords based on source type
  static List<InvoiceRecord> parseCsv({
    required String csvContent,
    required SourceType sourceType,
    required String defaultTaxPeriod,
  }) {
    return parseCsvWithDiagnostics(
      csvContent: csvContent,
      sourceType: sourceType,
      defaultTaxPeriod: defaultTaxPeriod,
    ).records;
  }

  /// Offloads CSV/Excel file parsing to a background isolate thread for responsive UI
  static Future<CsvIngestionResult> parseAnyFileAsync({
    required String filePath,
    required List<int> bytes,
    required SourceType sourceType,
    required String defaultTaxPeriod,
  }) async {
    return compute(_parseAnyFileIsolateEntryPoint, {
      'filePath': filePath,
      'bytes': bytes,
      'sourceTypeIndex': sourceType.index,
      'defaultTaxPeriod': defaultTaxPeriod,
    });
  }

  /// Parses raw CSV string or Excel bytes automatically based on file path/extension
  static CsvIngestionResult parseAnyFile({
    required String filePath,
    required List<int> bytes,
    required SourceType sourceType,
    required String defaultTaxPeriod,
  }) {
    final lowerPath = filePath.toLowerCase();
    if (lowerPath.endsWith('.xlsx') || lowerPath.endsWith('.xls')) {
      return parseExcelBytes(
        bytes: bytes,
        sourceType: sourceType,
        defaultTaxPeriod: defaultTaxPeriod,
      );
    }
    
    // Default CSV decoding
    final csvContent = String.fromCharCodes(bytes);
    return parseCsvWithDiagnostics(
      csvContent: csvContent,
      sourceType: sourceType,
      defaultTaxPeriod: defaultTaxPeriod,
    );
  }

  /// Parses Excel file bytes (.xlsx / .xls) into CsvIngestionResult
  static CsvIngestionResult parseExcelBytes({
    required List<int> bytes,
    required SourceType sourceType,
    required String defaultTaxPeriod,
  }) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final List<List<dynamic>> rows = [];

      for (var tableKey in excel.tables.keys) {
        final sheet = excel.tables[tableKey];
        if (sheet == null) continue;
        for (var row in sheet.rows) {
          final rowData = row.map((cell) {
            if (cell == null || cell.value == null) return '';
            return cell.value.toString();
          }).toList();
          if (rowData.any((element) => element.toString().trim().isNotEmpty)) {
            rows.add(rowData);
          }
        }
        if (rows.isNotEmpty) break; // Take first non-empty sheet
      }

      return parseRowsWithDiagnostics(
        rows: rows,
        sourceType: sourceType,
        defaultTaxPeriod: defaultTaxPeriod,
      );
    } catch (e) {
      return CsvIngestionResult(
        sourceType: sourceType,
        totalLinesRead: 0,
        successCount: 0,
        warningCount: 0,
        errorCount: 1,
        records: [],
        issues: [
          CsvLineIssue(
            lineNumber: 0,
            rawLineSnippet: '',
            severity: CsvIssueSeverity.error,
            description: 'Failed to parse Excel workbook: ${e.toString()}',
          ),
        ],
      );
    }
  }

  /// Detailed parser returning CsvIngestionResult with line-by-line error logs
  static CsvIngestionResult parseCsvWithDiagnostics({
    required String csvContent,
    required SourceType sourceType,
    required String defaultTaxPeriod,
  }) {
    final sanitizedCsv = csvContent.replaceAll('\r\n', '\n');
    final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(sanitizedCsv);
    return parseRowsWithDiagnostics(
      rows: rows,
      sourceType: sourceType,
      defaultTaxPeriod: defaultTaxPeriod,
    );
  }

  /// Master row parser for 2D matrix of values (CSV or Excel)
  static CsvIngestionResult parseRowsWithDiagnostics({
    required List<List<dynamic>> rows,
    required SourceType sourceType,
    required String defaultTaxPeriod,
  }) {
    if (rows.isEmpty) {
      return CsvIngestionResult(
        sourceType: sourceType,
        totalLinesRead: 0,
        successCount: 0,
        warningCount: 0,
        errorCount: 1,
        records: [],
        issues: [
          const CsvLineIssue(
            lineNumber: 0,
            rawLineSnippet: '',
            severity: CsvIssueSeverity.error,
            description: 'The uploaded file is empty or contains no readable rows.',
          ),
        ],
      );
    }

    final List<InvoiceRecord> records = [];
    final List<CsvLineIssue> issues = [];
    int warningCount = 0;
    int errorCount = 0;

    // Check if the CSV is a KRA Headerless Auto-Populated Schedule (e.g. SEC_B_WITHOUT_PIN_AND_NON-VAT_PIN1.CSV)
    bool isKraHeaderless = false;
    if (rows[0].length >= 5) {
      final col3Str = rows[0][3].toString().trim();
      final col4Str = rows[0][4].toString().trim();
      final sanitizedCol4 = sanitizeControlCode(col4Str);

      final isCol3Date = parseDateExact(col3Str) != null;
      final isCol4ControlCode = col4Str.startsWith('|') || (RegExp(r'^\d+$').hasMatch(sanitizedCol4) && sanitizedCol4.length >= 10);

      if (isCol3Date || isCol4ControlCode) {
        isKraHeaderless = true;
      }
    }

    if (isKraHeaderless) {
      // Process KRA Headerless Auto-Populated CSV (SEC B) starting from row 0
      for (int r = 0; r < rows.length; r++) {
        final lineNo = r + 1;
        final row = rows[r];
        final rowSnippet = row.take(6).join(', ');

        final isRowAllEmpty = row.every((c) => c.toString().trim().isEmpty);
        if (row.isEmpty || isRowAllEmpty) {
          warningCount++;
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: '',
            severity: CsvIssueSeverity.warning,
            description: 'Line $lineNo is empty. Skipped row.',
          ));
          continue;
        }

        if (row.length < 5) {
          errorCount++;
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: rowSnippet,
            severity: CsvIssueSeverity.error,
            description: 'Line $lineNo has insufficient columns (${row.length} found, minimum 5 required). Row skipped.',
          ));
          continue;
        }

        String rawPin = row[0].toString().trim();
        String suppPin = rawPin;
        if (suppPin.isEmpty) {
          suppPin = 'NON-VAT-SUPPLIER';
          warningCount++;
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: rowSnippet,
            severity: CsvIssueSeverity.info,
            description: 'Supplier PIN missing on line $lineNo. Categorized as non-VAT/no-PIN merchant purchase.',
          ));
        }

        String rawName = row[1].toString().trim();
        String suppName = rawName.isNotEmpty ? rawName : (suppPin != 'NON-VAT-SUPPLIER' ? 'Supplier $suppPin' : 'General Merchant');

        String deviceRef = row.length > 2 ? row[2].toString().trim() : 'KRA-DEVICE';

        String dateStr = row.length > 3 ? row[3].toString().trim() : '';
        DateTime? parsedInvDate = parseDateExact(dateStr);
        DateTime invDate = parsedInvDate ?? DateTime.now();

        if (parsedInvDate == null && dateStr.isNotEmpty) {
          warningCount++;
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: rowSnippet,
            severity: CsvIssueSeverity.warning,
            description: 'Line $lineNo has unparseable date "$dateStr". Defaulted to current timestamp.',
          ));
        }

        String rawControlCode = row.length > 4 ? row[4].toString().trim() : 'INV-$lineNo';
        if (rawControlCode.startsWith('|')) {
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: rowSnippet,
            severity: CsvIssueSeverity.info,
            description: 'Line $lineNo: Stripped leading pipe symbol "|" from Control Unit Invoice Number.',
          ));
        }
        String controlCode = sanitizeControlCode(rawControlCode);
        String invNo = controlCode.isNotEmpty ? controlCode : 'INV-$lineNo';

        String categoryDesc = row.length > 5 ? row[5].toString().trim() : 'ETIMS/TIMS sales';

        double taxable = 0.0;
        if (row.length > 6) {
          final parsed = double.tryParse(row[6].toString().replaceAll(',', ''));
          if (parsed != null) {
            taxable = parsed;
          } else {
            errorCount++;
            issues.add(CsvLineIssue(
              lineNumber: lineNo,
              rawLineSnippet: rowSnippet,
              severity: CsvIssueSeverity.error,
              description: 'Line $lineNo: Invalid taxable amount format "${row[6]}". Defaulted to 0.00.',
            ));
          }
        }

        double vat = taxable * 0.16;
        if (row.length > 7 && row[7].toString().trim().isNotEmpty) {
          vat = double.tryParse(row[7].toString().replaceAll(',', '')) ?? (taxable * 0.16);
        }

        double total = taxable + vat;
        if (row.length > 8 && row[8].toString().trim().isNotEmpty) {
          total = double.tryParse(row[8].toString().replaceAll(',', '')) ?? (taxable + vat);
        }

        records.add(InvoiceRecord(
          id: 'REC-${sourceType.name.toUpperCase()}-$lineNo-${DateTime.now().millisecondsSinceEpoch}',
          invoiceNumber: invNo,
          etimsControlCode: controlCode,
          cuSerialNumber: deviceRef,
          supplierPin: suppPin,
          supplierName: suppName,
          buyerPin: 'P051284920A',
          buyerName: 'Apex Enterprises',
          invoiceDate: invDate,
          taxPeriod: defaultTaxPeriod,
          taxableAmount: taxable,
          vatAmount: vat,
          totalAmount: total,
          vatRate: taxable > 0 ? (vat / taxable) : 0.16,
          sourceType: sourceType,
          sectionType: SectionType.sectionBPurchases,
          itemDescription: categoryDesc,
          traderSystemInvoiceNumber: invNo,
          transmissionDate: invDate.add(const Duration(hours: 2)),
        ));
      }

      return CsvIngestionResult(
        sourceType: sourceType,
        totalLinesRead: rows.length,
        successCount: records.length,
        warningCount: warningCount,
        errorCount: errorCount,
        records: records,
        issues: issues,
      );
    }

    // Standard Header-Based Processing (with QuickBooks & Xero ERP Support)
    final firstRowStr = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();

    int findColIndex(List<String> keywords) {
      for (int i = 0; i < firstRowStr.length; i++) {
        for (var kw in keywords) {
          if (firstRowStr[i].contains(kw)) return i;
        }
      }
      return -1;
    }

    final invNoCol = findColIndex(['invoice', 'inv_no', 'document', 'number', 'ref', 'num', 'invoicenumber']);
    final suppPinCol = findColIndex(['supplier_pin', 'vendor_pin', 'seller_pin', 'pin', 'tax_id', 'vat_number']);
    final suppNameCol = findColIndex(['supplier', 'vendor', 'seller', 'name', 'contactname', 'payee']);
    final buyerPinCol = findColIndex(['buyer_pin', 'customer_pin', 'client_pin']);
    final buyerNameCol = findColIndex(['buyer_name', 'customer_name', 'client_name', 'customer']);
    final dateCol = findColIndex(['date', 'created', 'time', 'invoicedate', 'txn_date']);
    final totalCol = findColIndex(['total', 'gross', 'amount', 'unitamount', 'balance', 'total_amount']);
    final taxableCol = findColIndex(['taxable', 'net', 'subtotal']);
    final vatCol = findColIndex(['vat', 'tax_amount', 'taxamount', 'tax']);
    final controlCodeCol = findColIndex(['control', 'qr', 'etims_code', 'cu_code']);
    final cuSerialCol = findColIndex(['serial', 'cu_sn', 'device']);
    final traderInvCol = findColIndex(['trader', 'system_inv', 'erp_ref']);
    final transDateCol = findColIndex(['transmission', 'trans_date']);

    if (invNoCol == -1 && suppPinCol == -1 && totalCol == -1) {
      warningCount++;
      issues.add(const CsvLineIssue(
        lineNumber: 1,
        rawLineSnippet: 'Header Row',
        severity: CsvIssueSeverity.warning,
        description: 'Standard headers (Invoice #, Supplier PIN, Amount) were not clearly identified. Positional fallback applied.',
      ));
    }

    for (int r = 1; r < rows.length; r++) {
      final lineNo = r + 1;
      final row = rows[r];
      final rowSnippet = row.take(5).join(', ');

      final isRowAllEmpty = row.every((c) => c.toString().trim().isEmpty);
      if (row.isEmpty || isRowAllEmpty) {
        warningCount++;
        issues.add(CsvLineIssue(
          lineNumber: lineNo,
          rawLineSnippet: '',
          severity: CsvIssueSeverity.warning,
          description: 'Line $lineNo is empty. Skipped row.',
        ));
        continue;
      }

      if (row.length < 3) {
        errorCount++;
        issues.add(CsvLineIssue(
          lineNumber: lineNo,
          rawLineSnippet: rowSnippet,
          severity: CsvIssueSeverity.error,
          description: 'Line $lineNo has insufficient columns (${row.length} found, minimum 3 required). Row skipped.',
        ));
        continue;
      }

      String invNo = invNoCol != -1 && invNoCol < row.length ? row[invNoCol].toString().trim() : 'INV-$r';
      invNo = sanitizeControlCode(invNo);

      String suppPin = suppPinCol != -1 && suppPinCol < row.length ? row[suppPinCol].toString().trim() : 'P000000000A';
      String suppName = suppNameCol != -1 && suppNameCol < row.length ? row[suppNameCol].toString().trim() : 'Vendor $r';
      String buyerPin = buyerPinCol != -1 && buyerPinCol < row.length ? row[buyerPinCol].toString().trim() : 'P051987654Z';
      String buyerName = buyerNameCol != -1 && buyerNameCol < row.length ? row[buyerNameCol].toString().trim() : 'Apex Enterprises';

      DateTime date = DateTime.now();
      if (dateCol != -1 && dateCol < row.length) {
        date = parseDate(row[dateCol].toString());
      }

      DateTime? transDate;
      if (transDateCol != -1 && transDateCol < row.length) {
        transDate = parseDate(row[transDateCol].toString());
      }

      double total = 0.0;
      if (totalCol != -1 && totalCol < row.length) {
        total = double.tryParse(row[totalCol].toString().replaceAll(',', '')) ?? 0.0;
      }

      double vat = 0.0;
      if (vatCol != -1 && vatCol < row.length) {
        vat = double.tryParse(row[vatCol].toString().replaceAll(',', '')) ?? 0.0;
      } else {
        vat = total * (0.16 / 1.16); // Fallback estimate 16%
      }

      double taxable = total - vat;
      if (taxableCol != -1 && taxableCol < row.length) {
        taxable = double.tryParse(row[taxableCol].toString().replaceAll(',', '')) ?? (total - vat);
      }

      InvoiceType invType = InvoiceType.standard;
      final upperInv = invNo.toUpperCase();
      if (upperInv.contains('CN') || upperInv.contains('CREDIT') || total < 0 || taxable < 0) {
        invType = InvoiceType.creditNote;
      } else if (upperInv.contains('DN') || upperInv.contains('DEBIT')) {
        invType = InvoiceType.debitNote;
      }

      String? controlCode = controlCodeCol != -1 && controlCodeCol < row.length ? sanitizeControlCode(row[controlCodeCol].toString()) : null;
      String? cuSerial = cuSerialCol != -1 && cuSerialCol < row.length ? row[cuSerialCol].toString().trim() : null;
      String? traderInv = traderInvCol != -1 && traderInvCol < row.length ? row[traderInvCol].toString().trim() : null;

      records.add(InvoiceRecord(
        id: 'REC-${sourceType.name.toUpperCase()}-$r-${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: invNo,
        etimsControlCode: controlCode,
        cuSerialNumber: cuSerial,
        supplierPin: suppPin,
        supplierName: suppName,
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: date,
        taxPeriod: defaultTaxPeriod,
        taxableAmount: taxable,
        vatAmount: vat,
        totalAmount: total,
        vatRate: taxable > 0 ? (vat / taxable) : 0.16,
        sourceType: sourceType,
        invoiceType: invType,
        sectionType: SectionType.sectionBPurchases,
        traderSystemInvoiceNumber: traderInv ?? invNo,
        transmissionDate: transDate ?? date.add(const Duration(hours: 2)),
      ));
    }

    return CsvIngestionResult(
      sourceType: sourceType,
      totalLinesRead: rows.length,
      successCount: records.length,
      warningCount: warningCount,
      errorCount: errorCount,
      records: records,
      issues: issues,
    );
  }

  /// Parses KRA 2% Withholding VAT (WHVAT) Certificate CSV schedules
  static List<WhvatRecord> parseWhvatCsv({
    required String csvContent,
    required String defaultTaxPeriod,
  }) {
    final sanitizedCsv = csvContent.replaceAll('\r\n', '\n');
    final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(sanitizedCsv);
    if (rows.isEmpty) return [];

    final List<WhvatRecord> records = [];
    int startRow = 0;

    // Check if header row exists
    if (rows[0].isNotEmpty && rows[0][0].toString().toLowerCase().contains('cert')) {
      startRow = 1;
    }

    for (int i = startRow; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5 || row.every((c) => c.toString().trim().isEmpty)) continue;

      final certNo = row[0].toString().trim();
      final suppPin = row.length > 1 ? row[1].toString().trim() : '';
      final suppName = row.length > 2 ? row[2].toString().trim() : 'Supplier $suppPin';
      final buyerPin = row.length > 3 ? row[3].toString().trim() : 'P051284920A';
      final buyerName = row.length > 4 ? row[4].toString().trim() : 'Apex Enterprises';
      final date = row.length > 5 ? parseDate(row[5].toString()) : DateTime.now();
      final gross = row.length > 6 ? (double.tryParse(row[6].toString().replaceAll(',', '')) ?? 0.0) : 0.0;
      final whvat = row.length > 7 ? (double.tryParse(row[7].toString().replaceAll(',', '')) ?? (gross * 0.02)) : (gross * 0.02);
      final invNo = row.length > 8 ? row[8].toString().trim() : 'INV-$i';

      records.add(WhvatRecord(
        id: 'WHV-$i-${DateTime.now().millisecondsSinceEpoch}',
        certificateNumber: certNo.isNotEmpty ? certNo : 'WHV-2026-$i',
        supplierPin: suppPin,
        supplierName: suppName,
        buyerPin: buyerPin,
        buyerName: buyerName,
        certificateDate: date,
        taxPeriod: defaultTaxPeriod,
        grossInvoiceAmount: gross,
        whvatAmount: whvat,
        invoiceNumber: invNo,
        isClaimedOnItax: true,
      ));
    }
    return records;
  }

  /// Parses KRA SIMBA / ICMS Customs Declaration (Section C Import VAT) CSV schedules
  static List<CustomsEntryRecord> parseCustomsCsv({
    required String csvContent,
    required String defaultTaxPeriod,
  }) {
    final sanitizedCsv = csvContent.replaceAll('\r\n', '\n');
    final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(sanitizedCsv);
    if (rows.isEmpty) return [];

    final List<CustomsEntryRecord> entries = [];
    int startRow = 0;

    if (rows[0].isNotEmpty && rows[0][0].toString().toLowerCase().contains('entry')) {
      startRow = 1;
    }

    for (int i = startRow; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4 || row.every((c) => c.toString().trim().isEmpty)) continue;

      final entryNo = row[0].toString().trim();
      final station = row.length > 1 ? row[1].toString().trim() : 'Mombasa Port / ICD Nairobi';
      final pin = row.length > 2 ? row[2].toString().trim() : 'P051284920A';
      final name = row.length > 3 ? row[3].toString().trim() : 'Apex Enterprises';
      final date = row.length > 4 ? parseDate(row[4].toString()) : DateTime.now();
      final taxable = row.length > 5 ? (double.tryParse(row[5].toString().replaceAll(',', '')) ?? 0.0) : 0.0;
      final importVat = row.length > 6 ? (double.tryParse(row[6].toString().replaceAll(',', '')) ?? (taxable * 0.16)) : (taxable * 0.16);
      final hsCode = row.length > 7 ? row[7].toString().trim() : null;

      entries.add(CustomsEntryRecord(
        id: 'CUST-$i-${DateTime.now().millisecondsSinceEpoch}',
        entryNumber: entryNo.isNotEmpty ? entryNo : 'C17-2026-$i',
        customsStation: station,
        importerPin: pin,
        importerName: name,
        declarationDate: date,
        taxPeriod: defaultTaxPeriod,
        taxableValue: taxable,
        importVatAmount: importVat,
        hsCode: hsCode,
      ));
    }
    return entries;
  }
}
