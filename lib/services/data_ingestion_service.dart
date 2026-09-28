import 'package:archive/archive.dart';
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
  final autoCalculate16PercentVat = args['autoCalculate16PercentVat'] as bool? ?? false;

  return DataIngestionService.parseAnyFile(
    filePath: filePath,
    bytes: bytes,
    sourceType: sourceType,
    defaultTaxPeriod: defaultTaxPeriod,
    autoCalculate16PercentVat: autoCalculate16PercentVat,
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
  /// Helper to parse date strings formatted as YYYY-MM-DD, DD/MM/YYYY, or Excel serial numbers (e.g. 46074)
  static DateTime? parseDateExact(String input) {
    final str = input.trim();
    if (str.isEmpty) return null;

    final iso = DateTime.tryParse(str);
    if (iso != null) return iso;

    // Excel serial date number check (e.g. 46074 or 46074.5)
    final numVal = double.tryParse(str);
    if (numVal != null && numVal >= 10000 && numVal <= 100000) {
      final millis = (numVal * 86400000).round();
      return DateTime(1899, 12, 30).add(Duration(milliseconds: millis));
    }

    // Strip time portion if present (e.g. "21/02/2026 00:00:00")
    final dateOnly = str.contains(' ') ? str.split(' ')[0] : str;

    final parts = dateOnly.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final p1 = int.tryParse(parts[0]);
      const monthMap = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
      };
      final p2Str = parts[1].toLowerCase();
      final p2 = int.tryParse(parts[1]) ?? monthMap[p2Str];
      var p3 = int.tryParse(parts[2]);

      if (p1 != null && p2 != null && p3 != null) {
        if (p3 < 100) {
          p3 += 2000;
        }

        if (p1 > 1000) {
          return DateTime(p1, p2, p3);
        }

        int day = p1;
        int month = p2;
        int year = p3;

        if (month > 12 && day <= 12) {
          final temp = day;
          day = month;
          month = temp;
        }

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
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
    bool autoCalculate16PercentVat = false,
  }) async {
    return compute(_parseAnyFileIsolateEntryPoint, {
      'filePath': filePath,
      'bytes': bytes,
      'sourceTypeIndex': sourceType.index,
      'defaultTaxPeriod': defaultTaxPeriod,
      'autoCalculate16PercentVat': autoCalculate16PercentVat,
    });
  }

  /// Parses raw CSV string or Excel bytes automatically based on file path/extension
  static CsvIngestionResult parseAnyFile({
    required String filePath,
    required List<int> bytes,
    required SourceType sourceType,
    required String defaultTaxPeriod,
    bool autoCalculate16PercentVat = false,
  }) {
    final lowerPath = filePath.toLowerCase();
    if (lowerPath.endsWith('.xlsx') || lowerPath.endsWith('.xls')) {
      return parseExcelBytes(
        bytes: bytes,
        sourceType: sourceType,
        defaultTaxPeriod: defaultTaxPeriod,
        autoCalculate16PercentVat: autoCalculate16PercentVat,
      );
    }

    // Default CSV decoding
    final csvContent = String.fromCharCodes(bytes);
    return parseCsvWithDiagnostics(
      csvContent: csvContent,
      sourceType: sourceType,
      defaultTaxPeriod: defaultTaxPeriod,
      autoCalculate16PercentVat: autoCalculate16PercentVat,
    );
  }

  /// Parses Excel file bytes (.xlsx / .xls) into CsvIngestionResult
  static CsvIngestionResult parseExcelBytes({
    required List<int> bytes,
    required SourceType sourceType,
    required String defaultTaxPeriod,
    bool autoCalculate16PercentVat = false,
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

      if (rows.isNotEmpty) {
        return parseRowsWithDiagnostics(
          rows: rows,
          sourceType: sourceType,
          defaultTaxPeriod: defaultTaxPeriod,
          autoCalculate16PercentVat: autoCalculate16PercentVat,
        );
      } else {
        return _parseXlsxFallbackViaArchive(
          bytes: bytes,
          sourceType: sourceType,
          defaultTaxPeriod: defaultTaxPeriod,
          autoCalculate16PercentVat: autoCalculate16PercentVat,
        );
      }
    } catch (e) {
      // Primary excel decoder failed (e.g. custom numFmtId exception). Fall back to raw XLSX Zip decoder.
      final fallbackResult = _parseXlsxFallbackViaArchive(
        bytes: bytes,
        sourceType: sourceType,
        defaultTaxPeriod: defaultTaxPeriod,
        autoCalculate16PercentVat: autoCalculate16PercentVat,
      );

      if (fallbackResult.records.isNotEmpty) {
        return fallbackResult;
      }

      // Secondary fallback: Attempt decoding as plain CSV string (in case user renamed .csv to .xlsx)
      try {
        final csvStr = String.fromCharCodes(bytes);
        final csvResult = parseCsvWithDiagnostics(
          csvContent: csvStr,
          sourceType: sourceType,
          defaultTaxPeriod: defaultTaxPeriod,
          autoCalculate16PercentVat: autoCalculate16PercentVat,
        );
        if (csvResult.records.isNotEmpty) {
          return csvResult;
        }
      } catch (_) {}

      return fallbackResult;
    }
  }

  /// Fallback XML zip parser for XLSX files when `excel` package fails due to custom number format IDs (numFmtId)
  static CsvIngestionResult _parseXlsxFallbackViaArchive({
    required List<int> bytes,
    required SourceType sourceType,
    required String defaultTaxPeriod,
    bool autoCalculate16PercentVat = false,
  }) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Extract sharedStrings.xml
      final sharedStrings = <String>[];
      final sharedStringsFile = archive.files.firstWhere(
        (f) => f.name.toLowerCase().endsWith('sharedstrings.xml'),
        orElse: () => ArchiveFile('', 0, []),
      );

      if (sharedStringsFile.content.isNotEmpty) {
        final contentStr = String.fromCharCodes(sharedStringsFile.content as List<int>);
        final siMatches = RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(contentStr);
        for (var si in siMatches) {
          final siInner = si.group(1) ?? '';
          final tMatches = RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true).allMatches(siInner);
          final textBuffer = StringBuffer();
          for (var t in tMatches) {
            textBuffer.write(t.group(1) ?? '');
          }
          String cleanText = textBuffer
              .toString()
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&apos;', "'");
          sharedStrings.add(cleanText);
        }
      }

      // 2. Extract first sheet file from xl/worksheets/
      final sheetFile = archive.files.firstWhere(
        (f) => f.name.toLowerCase().contains('worksheets/sheet') && f.name.toLowerCase().endsWith('.xml'),
        orElse: () => ArchiveFile('', 0, []),
      );

      if (sheetFile.content.isEmpty) {
        throw Exception('No worksheet XML found in XLSX package.');
      }

      final sheetXml = String.fromCharCodes(sheetFile.content as List<int>);
      final List<List<dynamic>> rows = [];

      final rowMatches = RegExp(r'<row[^>]*>(.*?)</row>', dotAll: true).allMatches(sheetXml);
      for (var rowMatch in rowMatches) {
        final rowContent = rowMatch.group(1) ?? '';
        final cellMatches = RegExp(r'<c([^>]*)>(.*?)</c>', dotAll: true).allMatches(rowContent);
        final List<dynamic> rowData = [];

        for (var cellMatch in cellMatches) {
          final attrs = cellMatch.group(1) ?? '';
          final cellInner = cellMatch.group(2) ?? '';

          final isSharedString = attrs.contains('t="s"');
          final isInlineString = attrs.contains('t="inlineStr"') || cellInner.contains('<is>');

          String cellVal = '';
          if (isSharedString) {
            final vMatch = RegExp(r'<v>(.*?)</v>').firstMatch(cellInner);
            if (vMatch != null) {
              final idx = int.tryParse(vMatch.group(1) ?? '');
              if (idx != null && idx >= 0 && idx < sharedStrings.length) {
                cellVal = sharedStrings[idx];
              }
            }
          } else if (isInlineString) {
            final tMatch = RegExp(r'<t[^>]*>(.*?)</t>').firstMatch(cellInner);
            if (tMatch != null) {
              cellVal = tMatch.group(1) ?? '';
            }
          } else {
            final vMatch = RegExp(r'<v>(.*?)</v>').firstMatch(cellInner);
            if (vMatch != null) {
              cellVal = vMatch.group(1) ?? '';
            }
          }

          cellVal = cellVal
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&apos;', "'");

          rowData.add(cellVal);
        }

        if (rowData.any((element) => element.toString().trim().isNotEmpty)) {
          rows.add(rowData);
        }
      }

      if (rows.isEmpty) {
        throw Exception('Worksheet contains no readable data rows.');
      }

      return parseRowsWithDiagnostics(
        rows: rows,
        sourceType: sourceType,
        defaultTaxPeriod: defaultTaxPeriod,
        autoCalculate16PercentVat: autoCalculate16PercentVat,
      );
    } catch (fallbackError) {
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
            description: 'Failed to parse Excel workbook: ${fallbackError.toString()}',
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
    bool autoCalculate16PercentVat = false,
  }) {
    final sanitizedCsv = csvContent.replaceAll('\r\n', '\n');
    final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(sanitizedCsv);
    return parseRowsWithDiagnostics(
      rows: rows,
      sourceType: sourceType,
      defaultTaxPeriod: defaultTaxPeriod,
      autoCalculate16PercentVat: autoCalculate16PercentVat,
    );
  }

  /// Master row parser for 2D matrix of values (CSV or Excel)
  static CsvIngestionResult parseRowsWithDiagnostics({
    required List<List<dynamic>> rows,
    required SourceType sourceType,
    required String defaultTaxPeriod,
    bool autoCalculate16PercentVat = false,
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

    // Check if the CSV/Excel is a KRA Auto-Populated Schedule (e.g. SEC_B_WITH_VAT_PIN.CSV / SEC_B_WITHOUT_PIN.CSV / Sales Returns)
    bool isKraHeaderless = false;

    // Exclude files that have standard explicit header rows
    final row0Upper = rows[0].join(' ').toUpperCase();
    final hasStandardHeaders = (row0Upper.contains('INVOICE') || row0Upper.contains('INV_NO') || row0Upper.contains('DOCUMENT')) &&
        (row0Upper.contains('PIN') || row0Upper.contains('SUPPLIER') || row0Upper.contains('VENDOR') || row0Upper.contains('AMOUNT') || row0Upper.contains('TOTAL'));

    if (!hasStandardHeaders) {
      for (int i = 0; i < (rows.length < 5 ? rows.length : 5); i++) {
        final rowStr = rows[i].join(' ').toUpperCase();
        if (rowStr.contains('ETIMS') ||
            rowStr.contains('TIMS') ||
            rowStr.contains('KRACU') ||
            rowStr.contains('KRAMW') ||
            rowStr.contains('|') ||
            rowStr.contains('LOCAL') ||
            rowStr.contains('EXPORT')) {
          isKraHeaderless = true;
          break;
        }
      }

      if (!isKraHeaderless && rows[0].length >= 4) {
        final col0 = rows[0][0].toString().trim().toUpperCase();
        final col4 = rows[0].length > 4 ? rows[0][4].toString().trim() : '';
        final col5 = rows[0].length > 5 ? rows[0][5].toString().trim().toUpperCase() : '';
        if ((col0.isEmpty || RegExp(r'^[A-Z]\d{9}[A-Z]$').hasMatch(col0) || col0 == 'LOCAL' || col0 == 'EXPORT') &&
            (col4.contains('|') || col4.contains('/') || col5.contains('SALES') || col5.contains('PURCHASES'))) {
          isKraHeaderless = true;
        }
      }
    }

    if (isKraHeaderless) {
      // Process KRA Auto-Populated CSV/Excel starting from row 0
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

        if (row.length < 4) {
          errorCount++;
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: rowSnippet,
            severity: CsvIssueSeverity.error,
            description: 'Line $lineNo has insufficient columns (${row.length} found, minimum 4 required). Row skipped.',
          ));
          continue;
        }

        // Semantic Cell Classifier per row
        String? foundPin;
        String? foundName;
        String? foundDevice;
        DateTime? foundDate;
        String? foundDateRaw;
        String? foundControlCode;
        String? foundCategory;

        int dateCellIdx = -1;
        int controlCodeCellIdx = -1;

        // Pass 1: Semantic Identification of Date, Control Code, Device, Category, PIN
        for (int c = 0; c < row.length; c++) {
          final rawVal = row[c].toString().trim();
          if (rawVal.isEmpty) continue;
          final upperVal = rawVal.toUpperCase();

          // 1. Date (parseDateExact != null, provided c is not the last column)
          if (foundDate == null && c < row.length - 1) {
            final parsedDate = parseDateExact(rawVal);
            if (parsedDate != null) {
              foundDate = parsedDate;
              foundDateRaw = rawVal;
              dateCellIdx = c;
              continue;
            }
          }

          // 2. Control Code (starts with '|' or contains '/' without being a date)
          if (foundControlCode == null && (rawVal.startsWith('|') || (rawVal.contains('/') && parseDateExact(rawVal) == null))) {
            foundControlCode = sanitizeControlCode(rawVal);
            controlCodeCellIdx = c;
            continue;
          }

          // 3. Device Serial Number (starts with KRACU, KRAMW, TIMS, CU without '/' or '|')
          if (foundDevice == null &&
              (upperVal.startsWith('KRACU') || upperVal.startsWith('KRAMW') || upperVal.startsWith('TIMS')) &&
              !rawVal.contains('/') &&
              !rawVal.startsWith('|')) {
            foundDevice = rawVal;
            continue;
          }

          // 4. Category Description
          if (foundCategory == null &&
              (upperVal.contains('ETIMS') ||
               upperVal.contains('TIMS') ||
               upperVal.contains('SALES') ||
               upperVal.contains('PURCHASES'))) {
            foundCategory = rawVal;
            continue;
          }

          // 5. KRA PIN
          if (foundPin == null && upperVal != 'LOCAL' && upperVal != 'EXPORT') {
            if (RegExp(r'^[A-Z]\d{9}[A-Z]$', caseSensitive: false).hasMatch(rawVal) ||
                upperVal.startsWith('P05') ||
                upperVal.startsWith('A00') ||
                upperVal.startsWith('A01') ||
                upperVal.startsWith('P00') ||
                upperVal.startsWith('P01')) {
              foundPin = upperVal;
              continue;
            }
          }
        }

        // Pass 2: Extract Trader Name (first non-numeric, unmapped string cell)
        for (int c = 0; c < row.length; c++) {
          final rawVal = row[c].toString().trim();
          final upperVal = rawVal.toUpperCase();
          if (rawVal.isEmpty) continue;
          if (c == dateCellIdx || c == controlCodeCellIdx) continue;
          if (upperVal == 'LOCAL' || upperVal == 'EXPORT') continue;
          if (foundPin != null && upperVal == foundPin) continue;
          if (foundCategory != null && rawVal == foundCategory) continue;
          if (foundDevice != null && rawVal == foundDevice) continue;
          if (double.tryParse(rawVal.replaceAll(',', '')) != null) continue;

          foundName = rawVal;
          break;
        }

        // Pass 3: Extract all numeric cells in row (forward order)
        final List<double> numericVals = [];
        for (int c = 0; c < row.length; c++) {
          if (c == dateCellIdx || c == controlCodeCellIdx) continue;
          final rawVal = row[c].toString().replaceAll(',', '').trim();
          if (rawVal.isEmpty) continue;
          final dVal = double.tryParse(rawVal);
          if (dVal != null) {
            // Ignore row sequence index numbers in column 0 (e.g. 1, 2, 3...)
            if (c == 0 && dVal <= 1000 && dVal == dVal.roundToDouble()) continue;
            numericVals.add(dVal);
          }
        }

        // Consolidate & Apply Defaults
        String suppPin = foundPin ?? 'NON-VAT-SUPPLIER';
        if (foundPin == null) {
          warningCount++;
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: rowSnippet,
            severity: CsvIssueSeverity.info,
            description: 'Merchant KRA PIN missing on line $lineNo. Categorized as non-VAT / un-registered merchant transaction.',
          ));
        }

        String suppName = foundName ?? (suppPin != 'NON-VAT-SUPPLIER' ? 'Supplier $suppPin' : 'General Merchant');

        DateTime invDate = foundDate ?? DateTime.now();
        if (foundDate == null && foundDateRaw != null) {
          warningCount++;
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: rowSnippet,
            severity: CsvIssueSeverity.warning,
            description: 'Line $lineNo has unparseable date "$foundDateRaw". Defaulted to current timestamp.',
          ));
        }

        String controlCode = foundControlCode ?? 'INV-$lineNo';
        if (rowSnippet.contains('|')) {
          issues.add(CsvLineIssue(
            lineNumber: lineNo,
            rawLineSnippet: rowSnippet,
            severity: CsvIssueSeverity.info,
            description: 'Line $lineNo: Stripped leading pipe symbol "|" from KRA Control Unit Invoice Number.',
          ));
        }
        String invNo = controlCode.isNotEmpty ? controlCode : 'INV-$lineNo';

        String deviceRef = foundDevice ??
            (controlCode.contains('/') ? controlCode.split('/')[0].trim() : 'KRA-ETIMS-DEVICE');

        String categoryDesc = foundCategory ?? 'ETIMS/TIMS sales';
        double taxable = 0.0;
        double vat = 0.0;
        double total = 0.0;

        if (numericVals.length >= 3) {
          taxable = numericVals[0];
          vat = numericVals[1];
          total = numericVals[2];
        } else if (numericVals.length == 2) {
          final v1 = numericVals[0];
          final v2 = numericVals[1];
          if (v2 > v1) {
            taxable = v1;
            total = v2;
            vat = total - taxable;
          } else {
            taxable = v1;
            vat = v2;
            total = taxable + vat;
          }
        } else if (numericVals.isNotEmpty) {
          total = numericVals[0];
          if (suppPin != 'NON-VAT-SUPPLIER' && autoCalculate16PercentVat) {
            vat = total * (0.16 / 1.16); // Extract 16% VAT from gross total
            taxable = total - vat;
          } else {
            vat = 0.0;
            taxable = total;
          }
        }

        final catUpper = '$categoryDesc $suppName'.toUpperCase();
        final bool isKraRowPurchase = catUpper.contains('PURCHASE') ||
            catUpper.contains('VENDOR') ||
            catUpper.contains('SUPPLIER') ||
            catUpper.contains('INPUT') ||
            catUpper.contains('SEC B') ||
            catUpper.contains('SECTION B') ||
            catUpper.contains('BILL') ||
            catUpper.contains('EXPENSE') ||
            catUpper.contains('COST');
        final SectionType kraSectionType = isKraRowPurchase ? SectionType.sectionBPurchases : SectionType.sectionASales;

        records.add(InvoiceRecord(
          id: 'REC-${sourceType.name.toUpperCase()}-$lineNo-${DateTime.now().millisecondsSinceEpoch}',
          invoiceNumber: invNo,
          etimsControlCode: controlCode,
          cuSerialNumber: deviceRef,
          supplierPin: suppPin,
          supplierName: suppName,
          buyerPin: 'P051000000Z',
          buyerName: 'Taxpayer Entity',
          invoiceDate: invDate,
          taxPeriod: defaultTaxPeriod,
          taxableAmount: taxable,
          vatAmount: vat,
          totalAmount: total,
          vatRate: taxable > 0 ? (vat / taxable) : 0.0,
          sourceType: sourceType,
          sectionType: kraSectionType,
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

    // Standard Header-Based Processing (with Tally Prime, QuickBooks & Xero ERP Support)
    int headerRowIndex = 0;
    List<String> headerRowStr = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();

    // Scan up to the first 15 rows to find the actual table header row (skipping company title blocks)
    for (int i = 0; i < (rows.length < 15 ? rows.length : 15); i++) {
      final rowStrList = rows[i].map((e) => e.toString().toLowerCase().trim()).toList();
      final rowJoined = rowStrList.join(' ');

      final matchCount = [
        'date', 'particulars', 'vch', 'voucher', 'type', 'number', 'ref',
        'invoice', 'customer', 'supplier', 'debit', 'credit', 'amount', 'total', 'party'
      ].where((kw) => rowJoined.contains(kw)).length;

      if (matchCount >= 2) {
        headerRowIndex = i;
        headerRowStr = rowStrList;
        break;
      }
    }

    int findColIndex(List<String> keywords) {
      for (int i = 0; i < headerRowStr.length; i++) {
        for (var kw in keywords) {
          if (headerRowStr[i].contains(kw)) return i;
        }
      }
      return -1;
    }

    final invNoCol = findColIndex(['vch no', 'voucher no', 'vch_no', 'vch. no', 'invoice', 'inv_no', 'document', 'number', 'ref', 'num', 'invoicenumber']);
    final suppPinCol = findColIndex(['supplier_pin', 'vendor_pin', 'seller_pin', 'pin', 'tax_id', 'vat_number']);
    final suppNameCol = findColIndex(['particulars', 'supplier', 'vendor', 'seller', 'name', 'contactname', 'payee', 'party']);
    final buyerPinCol = findColIndex(['buyer_pin', 'customer_pin', 'client_pin']);
    final buyerNameCol = findColIndex(['buyer_name', 'customer_name', 'client_name', 'customer', 'party']);
    final dateCol = findColIndex(['date', 'created', 'time', 'invoicedate', 'txn_date']);
    final debitCol = findColIndex(['debit', 'debit amount']);
    final creditCol = findColIndex(['credit', 'credit amount']);
    final totalCol = findColIndex(['total', 'gross', 'amount', 'unitamount', 'balance', 'total_amount']);
    final vchTypeCol = findColIndex(['vch type', 'voucher type', 'vch_type', 'type']);
    final taxableCol = findColIndex(['taxable', 'net', 'subtotal']);
    final vatCol = findColIndex(['vat', 'tax_amount', 'taxamount', 'tax']);
    final controlCodeCol = findColIndex(['control', 'qr', 'etims_code', 'cu_code']);
    final cuSerialCol = findColIndex(['serial', 'cu_sn', 'device']);
    final traderInvCol = findColIndex(['trader', 'system_inv', 'erp_ref']);
    final transDateCol = findColIndex(['transmission', 'trans_date']);

    final allTopText = rows.take(15).map((r) => r.join(' ')).join(' ').toLowerCase();
    final headerJoined = headerRowStr.join(' ').toLowerCase();

    // Rule: Unless something is explicitly declared as a purchase, they are all sales (Section A Output VAT)
    final bool isDeclaredPurchase = allTopText.contains('purchase') ||
        allTopText.contains('sec b') ||
        allTopText.contains('sec_b') ||
        allTopText.contains('section b') ||
        allTopText.contains('input vat') ||
        allTopText.contains('vendor') ||
        allTopText.contains('supplier') ||
        allTopText.contains('bill') ||
        allTopText.contains('expense') ||
        allTopText.contains('cost') ||
        allTopText.contains('c17') ||
        allTopText.contains('import') ||
        headerJoined.contains('supplier') ||
        headerJoined.contains('vendor') ||
        headerJoined.contains('purchase') ||
        headerJoined.contains('bill');

    final bool isSalesLedger = !isDeclaredPurchase;
    final SectionType sectionType = isSalesLedger ? SectionType.sectionASales : SectionType.sectionBPurchases;

    if (invNoCol == -1 && suppPinCol == -1 && buyerPinCol == -1 && totalCol == -1 && debitCol == -1) {
      warningCount++;
      issues.add(const CsvLineIssue(
        lineNumber: 1,
        rawLineSnippet: 'Header Row',
        severity: CsvIssueSeverity.warning,
        description: 'Standard headers (Invoice #, PIN, Amount) were not clearly identified. Positional fallback applied.',
      ));
    }

    for (int r = headerRowIndex + 1; r < rows.length; r++) {
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

      final col0Text = row[0].toString().trim().toLowerCase();
      final col1Text = row.length > 1 ? row[1].toString().trim().toLowerCase() : '';
      if (col0Text.contains('total') || col0Text.contains('carried') || col1Text.contains('total') || col1Text.contains('carried')) {
        continue;
      }

      String invNo = invNoCol != -1 && invNoCol < row.length ? row[invNoCol].toString().trim() : 'INV-$r';
      invNo = sanitizeControlCode(invNo);

      String suppPin = suppPinCol != -1 && suppPinCol < row.length ? row[suppPinCol].toString().trim() : 'P000000000A';
      String suppName = suppNameCol != -1 && suppNameCol < row.length ? row[suppNameCol].toString().trim() : 'Vendor $r';
      
      String buyerPin = 'P051987654Z';
      if (buyerPinCol != -1 && buyerPinCol < row.length) {
        buyerPin = row[buyerPinCol].toString().trim();
      } else if (isSalesLedger && suppPinCol != -1 && suppPinCol < row.length) {
        buyerPin = suppPin;
      }

      String buyerName = 'Apex Enterprises';
      if (buyerNameCol != -1 && buyerNameCol < row.length) {
        buyerName = row[buyerNameCol].toString().trim();
      } else if (isSalesLedger && suppNameCol != -1 && suppNameCol < row.length) {
        buyerName = suppName;
      }

      if (isSalesLedger && (buyerPin.isEmpty || buyerPin == 'NO-PIN' || buyerPin == 'B2C-CONSUMER' || buyerPin.contains('NON-VAT') || buyerPin == 'P000000000A')) {
        buyerPin = 'NO-PIN';
        if (buyerName.isEmpty || buyerName.startsWith('Vendor')) {
          buyerName = 'Walk-in Cash Consumer (B2C)';
        }
      }

      DateTime date = DateTime.now();
      if (dateCol != -1 && dateCol < row.length) {
        date = parseDate(row[dateCol].toString());
      }

      DateTime? transDate;
      if (transDateCol != -1 && transDateCol < row.length) {
        transDate = parseDate(row[transDateCol].toString());
      }

      double debitVal = 0.0;
      double creditVal = 0.0;

      if (debitCol != -1 && debitCol < row.length) {
        debitVal = double.tryParse(row[debitCol].toString().replaceAll(',', '')) ?? 0.0;
      }
      if (creditCol != -1 && creditCol < row.length) {
        creditVal = double.tryParse(row[creditCol].toString().replaceAll(',', '')) ?? 0.0;
      }

      double rawAmount = 0.0;
      if (debitVal > 0) {
        rawAmount = debitVal;
      } else if (creditVal > 0) {
        rawAmount = creditVal;
      } else if (totalCol != -1 && totalCol < row.length) {
        rawAmount = double.tryParse(row[totalCol].toString().replaceAll(',', '')) ?? 0.0;
      } else if (taxableCol != -1 && taxableCol < row.length) {
        rawAmount = double.tryParse(row[taxableCol].toString().replaceAll(',', '')) ?? 0.0;
      }

      double total = rawAmount;
      double vat = 0.0;

      if (vatCol != -1 && vatCol < row.length) {
        vat = double.tryParse(row[vatCol].toString().replaceAll(',', '')) ?? 0.0;
      } else if (autoCalculate16PercentVat && suppPin != 'NON-VAT-SUPPLIER') {
        vat = total * (0.16 / 1.16); // Extract 16% VAT from gross total if auto-calc requested
      } else {
        vat = 0.0;
      }

      double taxable = total - vat;

      InvoiceType invType = InvoiceType.standard;
      final upperInv = invNo.toUpperCase();
      String vchType = vchTypeCol != -1 && vchTypeCol < row.length ? row[vchTypeCol].toString().trim().toUpperCase() : '';
      if (upperInv.contains('CN') || upperInv.contains('CREDIT') || vchType.contains('CREDIT') || creditVal > 0 || total < 0 || taxable < 0) {
        invType = InvoiceType.creditNote;
      } else if (upperInv.contains('DN') || upperInv.contains('DEBIT') || vchType.contains('DEBIT')) {
        invType = InvoiceType.debitNote;
      }

      String? controlCode = controlCodeCol != -1 && controlCodeCol < row.length ? sanitizeControlCode(row[controlCodeCol].toString()) : null;
      String? cuSerial = cuSerialCol != -1 && cuSerialCol < row.length ? row[cuSerialCol].toString().trim() : null;
      String? traderInv = traderInvCol != -1 && traderInvCol < row.length ? row[traderInvCol].toString().trim() : null;

      if (controlCode == null && (invNo.contains('/') || invNo.toUpperCase().startsWith('KRACU') || invNo.toUpperCase().startsWith('KRAMW'))) {
        controlCode = invNo;
      }
      if (cuSerial == null && controlCode != null && controlCode.contains('/')) {
        cuSerial = controlCode.split('/')[0].trim();
      }

      records.add(InvoiceRecord(
        id: 'REC-${sourceType.name.toUpperCase()}-$r-${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: invNo,
        etimsControlCode: controlCode,
        cuSerialNumber: cuSerial,
        supplierPin: isSalesLedger ? 'P051284920A' : suppPin,
        supplierName: isSalesLedger ? 'Mineksha Healthcare Limited' : suppName,
        buyerPin: isSalesLedger ? buyerPin : 'P051284920A',
        buyerName: isSalesLedger ? buyerName : 'Apex Enterprises',
        invoiceDate: date,
        taxPeriod: defaultTaxPeriod,
        taxableAmount: taxable,
        vatAmount: vat,
        totalAmount: total,
        vatRate: taxable > 0 ? (vat / taxable) : 0.0,
        sourceType: sourceType,
        invoiceType: invType,
        sectionType: sectionType,
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
