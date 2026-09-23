import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/services/data_ingestion_service.dart';
import 'package:reconix/models/invoice_record.dart';

void main() {
  group('CSV Ingestion Diagnostics & Error Tracking Tests', () {
    test('parseCsvWithDiagnostics identifies malformed lines, empty lines, and calculates stats correctly', () {
      const csvWithErrors = '''
supplier_pin,supplier_name,invoice_number,date,total_amount
P051234567A,Safaricom PLC,INV-001,2026-08-01,100000.00
,,

P051999999Z,Vendor Bad Date,INV-002,INVALID_DATE,50000.00
P051888888X,Vendor Short Row
''';

      final res = DataIngestionService.parseCsvWithDiagnostics(
        csvContent: csvWithErrors,
        sourceType: SourceType.erp,
        defaultTaxPeriod: '2026-08',
      );

      expect(res.totalLinesRead, equals(6)); // Header + 5 lines
      expect(res.successCount, equals(2)); // Row 1 (valid) and Row 3 (parsed with date warning)
      expect(res.hasIssues, isTrue);

      // Verify line issues recorded
      final emptyLineIssue = res.issues.firstWhere((i) => i.description.contains('empty'));
      expect(emptyLineIssue.severity, equals(CsvIssueSeverity.warning));

      final shortRowIssue = res.issues.firstWhere((i) => i.description.contains('insufficient columns'));
      expect(shortRowIssue.severity, equals(CsvIssueSeverity.error));
    });

    test('parseCsvWithDiagnostics tracks KRA pipe stripping and missing PIN info messages', () {
      const kraHeaderlessCsv = '''
"",,KRAMW001202203019736,08/06/2026,|0010197360000115685,ETIMS/TIMS sales,3636.21,,,
''';

      final res = DataIngestionService.parseCsvWithDiagnostics(
        csvContent: kraHeaderlessCsv,
        sourceType: SourceType.itax,
        defaultTaxPeriod: '2026-06',
      );

      expect(res.successCount, equals(1));
      expect(res.records.first.supplierPin, equals('NON-VAT-SUPPLIER'));
      expect(res.records.first.hasValidPin, isFalse);
      expect(res.records.first.isNonVatNoPin, isTrue);
      expect(res.recordsNoPinCount, equals(1));
      expect(res.recordsWithPinCount, equals(0));
      expect(res.records.first.etimsControlCode, equals('0010197360000115685'));

      final pipeIssue = res.issues.firstWhere((i) => i.description.contains('Stripped leading pipe'));
      expect(pipeIssue.severity, equals(CsvIssueSeverity.info));
    });
  });
}
