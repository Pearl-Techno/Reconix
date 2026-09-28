import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/services/data_ingestion_service.dart';
import 'package:reconix/models/invoice_record.dart';

void main() {
  group('KRA Auto-Populated Section B CSV Ingestion Tests', () {
    test('parses headerless KRA CSV with leading pipe control code and DD/MM/YYYY dates correctly', () {
      const sampleCsv = '''
"",,KRAMW001202203019736,08/06/2026,|0010197360000115685,ETIMS/TIMS sales,3636.21,,,
"A006633624S","Cynthia Khanguhi Adolwa","KRAMW001202203019736","09/06/2026","|0010197360000115706","ETIMS/TIMS sales","2377.58",,,
"P051320148P","WOODSMAN AGENCIES LIMITED","KRAMW001202203019736","05/06/2026","|0010197360000115341","ETIMS/TIMS sales","12299.13",,,
''';

      final records = DataIngestionService.parseCsv(
        csvContent: sampleCsv,
        sourceType: SourceType.itax,
        defaultTaxPeriod: '2026-06',
      );

      expect(records.length, equals(3));

      // Row 1: Non-VAT / No PIN row
      final rec1 = records[0];
      expect(rec1.supplierPin, equals('NON-VAT-SUPPLIER'));
      expect(rec1.etimsControlCode, equals('0010197360000115685')); // Stripped leading '|'
      expect(rec1.invoiceDate, equals(DateTime(2026, 6, 8)));
      expect(rec1.taxableAmount, equals(3636.21));

      // Row 2: Cynthia Khanguhi Adolwa
      final rec2 = records[1];
      expect(rec2.supplierPin, equals('A006633624S'));
      expect(rec2.supplierName, equals('Cynthia Khanguhi Adolwa'));
      expect(rec2.etimsControlCode, equals('0010197360000115706'));
      expect(rec2.invoiceDate, equals(DateTime(2026, 6, 9)));

      // Row 3: WOODSMAN AGENCIES LIMITED
      final rec3 = records[2];
      expect(rec3.supplierPin, equals('P051320148P'));
      expect(rec3.supplierName, equals('WOODSMAN AGENCIES LIMITED'));
      expect(rec3.etimsControlCode, equals('0010197360000115341'));
      expect(rec3.totalAmount, equals(12299.13));
    });

    test('parses KRA CSV with PIN present but blank supplier name correctly', () {
      const csvWithPinNoName = '''
"P051543892Q","","KRAMW001202203019736","06/06/2026","|0010197360000115480","ETIMS/TIMS sales","513.79",,,
''';

      final records = DataIngestionService.parseCsv(
        csvContent: csvWithPinNoName,
        sourceType: SourceType.itax,
        defaultTaxPeriod: '2026-06',
      );

      expect(records.length, equals(1));
      expect(records.first.supplierPin, equals('P051543892Q'));
      expect(records.first.supplierName, equals('Supplier P051543892Q'));
      expect(records.first.etimsControlCode, equals('0010197360000115480'));
      expect(records.first.totalAmount, equals(513.79));
    });

    test('parses KRA data with Excel serial date numbers (e.g. 46074) correctly without warning', () {
      const csvWithExcelDate = '''
"P051208794R","Eastleigh Pharmaceutical Company Limited","KRACU0200119725","46074","|KRACU0200119725/274","ETIMS/TIMS sales","1500.00",,,
''';

      final result = DataIngestionService.parseCsvWithDiagnostics(
        csvContent: csvWithExcelDate,
        sourceType: SourceType.itax,
        defaultTaxPeriod: '2026-02',
      );

      expect(result.records.length, equals(1));
      final rec = result.records.first;
      expect(rec.supplierPin, equals('P051208794R'));
      expect(rec.supplierName, equals('Eastleigh Pharmaceutical Company Limited'));
      expect(rec.invoiceDate, equals(DateTime(2026, 2, 21)));
      expect(result.issues.any((i) => i.description.contains('unparseable date')), isFalse);
    });

    test('parses KRA data with "Local" prefix and dynamic column offset correctly', () {
      const csvWithLocalPrefix = '''
"Local","P051690651G","NORTHERN PHARMACY LIMITED","21/04/2026","|KRACU0200119725/337","ETIMS/TIMS sales","6120.00"
"Local","","","24/04/2026","|KRACU0200119725/351","ETIMS/TIMS sales","350.00"
''';

      final result = DataIngestionService.parseCsvWithDiagnostics(
        csvContent: csvWithLocalPrefix,
        sourceType: SourceType.itax,
        defaultTaxPeriod: '2026-04',
      );

      expect(result.records.length, equals(2));

      // Row 1: NORTHERN PHARMACY LIMITED
      final rec1 = result.records[0];
      expect(rec1.supplierPin, equals('P051690651G'));
      expect(rec1.supplierName, equals('NORTHERN PHARMACY LIMITED'));
      expect(rec1.invoiceDate, equals(DateTime(2026, 4, 21)));
      expect(rec1.etimsControlCode, equals('KRACU0200119725/337'));
      expect(rec1.cuSerialNumber, equals('KRACU0200119725'));
      expect(rec1.totalAmount, equals(6120.00));

      // Row 2: Blank PIN/Name with Local prefix
      final rec2 = result.records[1];
      expect(rec2.supplierPin, equals('NON-VAT-SUPPLIER'));
      expect(rec2.supplierName, equals('General Merchant'));
      expect(rec2.invoiceDate, equals(DateTime(2026, 4, 24)));
      expect(rec2.etimsControlCode, equals('KRACU0200119725/351'));
      expect(rec2.cuSerialNumber, equals('KRACU0200119725'));
      expect(rec2.totalAmount, equals(350.00));
    });

    test('parses KRA data starting with row sequence indices (e.g. 2, 46077) correctly with 0 date warnings', () {
      const csvWithRowIndex = '''
"2","46077","|KRACU0200119725/282","ETIMS/TIMS sales","3200"
"3","46078","|KRACU0200119725/285","ETIMS/TIMS sales","2308"
''';

      final result = DataIngestionService.parseCsvWithDiagnostics(
        csvContent: csvWithRowIndex,
        sourceType: SourceType.itax,
        defaultTaxPeriod: '2026-02',
      );

      expect(result.records.length, equals(2));

      final rec1 = result.records[0];
      expect(rec1.invoiceDate, equals(DateTime(2026, 2, 24)));
      expect(rec1.etimsControlCode, equals('KRACU0200119725/282'));
      expect(rec1.cuSerialNumber, equals('KRACU0200119725'));
      expect(rec1.totalAmount, equals(3200.00));

      final rec2 = result.records[1];
      expect(rec2.invoiceDate, equals(DateTime(2026, 2, 25)));
      expect(rec2.etimsControlCode, equals('KRACU0200119725/285'));
      expect(rec2.cuSerialNumber, equals('KRACU0200119725'));
      expect(rec2.totalAmount, equals(2308.00));

      expect(result.issues.any((i) => i.description.contains('unparseable date')), isFalse);
    });
  });
}
