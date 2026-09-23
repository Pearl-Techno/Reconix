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
      expect(rec3.taxableAmount, equals(12299.13));
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
      expect(records.first.taxableAmount, equals(513.79));
    });
  });
}
