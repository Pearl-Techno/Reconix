import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/models/invoice_record.dart';

void main() {
  group('KRA iTax Invoice Checker Model & Schema Tests', () {
    test('InvoiceRecord serializes and deserializes traderSystemInvoiceNumber and transmissionDate correctly', () {
      final transmission = DateTime(2023, 1, 30, 11, 17, 23);
      final record = InvoiceRecord(
        id: 'TEST-INV-001',
        invoiceNumber: '00101938000000000112',
        etimsControlCode: '00101938000000000112',
        cuSerialNumber: 'CU-SN-9982',
        supplierPin: 'P051234567A',
        supplierName: 'Jamii Distributors (e.a) Limited',
        buyerPin: 'P051284920A',
        buyerName: 'Apex Logistics Kenya Ltd',
        invoiceDate: DateTime(2022, 12, 2),
        taxPeriod: '2022-12',
        taxableAmount: 2413.79,
        vatAmount: 386.21,
        totalAmount: 2800.00,
        sourceType: SourceType.etims,
        traderSystemInvoiceNumber: '2254606',
        transmissionDate: transmission,
      );

      final jsonMap = record.toJson();
      expect(jsonMap['traderSystemInvoiceNumber'], equals('2254606'));
      expect(jsonMap['transmissionDate'], equals(transmission.toIso8601String()));

      final reconstructed = InvoiceRecord.fromJson(jsonMap);
      expect(reconstructed.traderSystemInvoiceNumber, equals('2254606'));
      expect(reconstructed.transmissionDate, equals(transmission));
      expect(reconstructed.totalAmount, equals(2800.00));
      expect(reconstructed.vatAmount, equals(386.21));
    });

    test('InvoiceRecord normalization strips formatting for matching Control Unit Numbers', () {
      final record = InvoiceRecord(
        id: 'TEST-INV-002',
        invoiceNumber: 'INV/2026/001001',
        etimsControlCode: '0010-1938-0000-00000112',
        supplierPin: 'p-051234567a',
        supplierName: 'Test Supplier',
        buyerPin: 'P051284920A',
        buyerName: 'Test Buyer',
        invoiceDate: DateTime.now(),
        taxPeriod: '2026-08',
        taxableAmount: 1000.0,
        vatAmount: 160.0,
        totalAmount: 1160.0,
        sourceType: SourceType.erp,
      );

      expect(record.normalizedSupplierPin, equals('P-051234567A'));
      expect(record.normalizedInvoiceNumber, equals('INV2026001001'));
    });
  });
}
