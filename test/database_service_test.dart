import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reconix/models/invoice_record.dart';
import 'package:reconix/models/taxpayer_client.dart';
import 'package:reconix/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService SQLite Operations Tests', () {
    test('insertClient and getClients operate correctly', () async {
      final client = TaxpayerClient(
        id: 'TEST-CLI-001',
        businessName: 'Test Corporation Kenya Ltd',
        kraPin: 'P050000000X',
        vatRegistrationNo: 'VAT-050000000X',
        contactEmail: 'tax@testcorp.co.ke',
        sector: 'Technology',
        currentTaxPeriod: '2026-08',
        totalMonthlyPurchases: 1000000.0,
        inputVatClaimable: 160000.0,
        inputVatAtRisk: 0.0,
        totalInvoicesCount: 5,
        matchedInvoicesCount: 5,
        riskStatus: 'READY_TO_FILE',
      );

      await DatabaseService.insertClient(client, isDemo: false);
      final clients = await DatabaseService.getClients(isDemo: false);

      expect(clients.any((c) => c.id == 'TEST-CLI-001'), isTrue);
      final inserted = clients.firstWhere((c) => c.id == 'TEST-CLI-001');
      expect(inserted.businessName, equals('Test Corporation Kenya Ltd'));
    });

    test('insertInvoices and getInvoices handle live records correctly', () async {
      final record = InvoiceRecord(
        id: 'LIVE-INV-001',
        invoiceNumber: 'INV-9999',
        supplierPin: 'P051111111A',
        supplierName: 'Safaricom Telecommunications',
        buyerPin: 'P050000000X',
        buyerName: 'Test Corporation Kenya Ltd',
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: '2026-08',
        taxableAmount: 50000.0,
        vatAmount: 8000.0,
        totalAmount: 58000.0,
        sourceType: SourceType.erp,
        etimsControlCode: 'ETM-2026-SAF-9999',
      );

      await DatabaseService.insertInvoices([record], clientId: 'TEST-CLI-001', isDemo: false);
      final invoices = await DatabaseService.getInvoices(clientId: 'TEST-CLI-001', sourceType: SourceType.erp, isDemo: false);

      expect(invoices, isNotEmpty);
      expect(invoices.any((i) => i.invoiceNumber == 'INV-9999'), isTrue);
    });
  });
}
