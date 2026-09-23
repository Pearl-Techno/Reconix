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

  group('Multi-Company SQLite Data Isolation Tests', () {
    test('invoices inserted for Company A are strictly isolated from Company B', () async {
      const companyA = TaxpayerClient(
        id: 'CLI-COMP-A',
        businessName: 'Alpha Logistics Kenya Ltd',
        kraPin: 'P051111111A',
        vatRegistrationNo: 'VAT-051111111A',
        contactEmail: 'alpha@logistics.co.ke',
        sector: 'Transport',
        currentTaxPeriod: '2026-08',
        totalMonthlyPurchases: 2000000.0,
        inputVatClaimable: 320000.0,
        inputVatAtRisk: 0.0,
        totalInvoicesCount: 2,
        matchedInvoicesCount: 2,
        riskStatus: 'READY_TO_FILE',
      );

      const companyB = TaxpayerClient(
        id: 'CLI-COMP-B',
        businessName: 'Beta Retailers Kenya Ltd',
        kraPin: 'P052222222B',
        vatRegistrationNo: 'VAT-052222222B',
        contactEmail: 'beta@retailers.co.ke',
        sector: 'Retail',
        currentTaxPeriod: '2026-08',
        totalMonthlyPurchases: 500000.0,
        inputVatClaimable: 80000.0,
        inputVatAtRisk: 0.0,
        totalInvoicesCount: 1,
        matchedInvoicesCount: 1,
        riskStatus: 'READY_TO_FILE',
      );

      await DatabaseService.insertClient(companyA, isDemo: false);
      await DatabaseService.insertClient(companyB, isDemo: false);

      final invA = InvoiceRecord(
        id: 'INV-ALPHA-01',
        invoiceNumber: 'INV-A-101',
        supplierPin: 'P059999999Z',
        supplierName: 'KPLC PLC',
        buyerPin: 'P051111111A',
        buyerName: 'Alpha Logistics Kenya Ltd',
        invoiceDate: DateTime(2026, 8, 1),
        taxPeriod: '2026-08',
        taxableAmount: 100000.0,
        vatAmount: 16000.0,
        totalAmount: 116000.0,
        sourceType: SourceType.erp,
      );

      final invB = InvoiceRecord(
        id: 'INV-BETA-01',
        invoiceNumber: 'INV-B-202',
        supplierPin: 'P058888888Y',
        supplierName: 'Safaricom PLC',
        buyerPin: 'P052222222B',
        buyerName: 'Beta Retailers Kenya Ltd',
        invoiceDate: DateTime(2026, 8, 2),
        taxPeriod: '2026-08',
        taxableAmount: 50000.0,
        vatAmount: 8000.0,
        totalAmount: 58000.0,
        sourceType: SourceType.erp,
      );

      await DatabaseService.insertInvoices([invA], clientId: companyA.id, isDemo: false);
      await DatabaseService.insertInvoices([invB], clientId: companyB.id, isDemo: false);

      final alphaInvoices = await DatabaseService.getInvoices(clientId: companyA.id, sourceType: SourceType.erp, isDemo: false);
      final betaInvoices = await DatabaseService.getInvoices(clientId: companyB.id, sourceType: SourceType.erp, isDemo: false);

      expect(alphaInvoices.length, equals(1));
      expect(alphaInvoices.first.invoiceNumber, equals('INV-A-101'));

      expect(betaInvoices.length, equals(1));
      expect(betaInvoices.first.invoiceNumber, equals('INV-B-202'));
    });
  });
}
