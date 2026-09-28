import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/models/customs_entry_record.dart';
import 'package:reconix/models/customs_match_result.dart';
import 'package:reconix/models/invoice_record.dart';
import 'package:reconix/services/reconciliation_engine.dart';
import 'package:reconix/services/vat_apportionment_service.dart';

void main() {
  group('Import Customs Entry & Section 17 Apportionment Unit Tests', () {
    test('ReconciliationEngine.reconcileCustoms matches SIMBA Customs Entry to ERP record', () {
      final customsEntry = CustomsEntryRecord(
        id: 'CUST-001',
        entryNumber: '2026MSA1094820',
        customsStation: 'Mombasa Port ICD',
        importerPin: 'P051284920A',
        importerName: 'Apex Logistics Kenya Ltd',
        declarationDate: DateTime(2026, 8, 10),
        taxPeriod: 'August 2026',
        taxableValue: 5000000.0,
        importVatAmount: 800000.0,
      );

      final erpImportInvoice = InvoiceRecord(
        id: 'ERP-IMP-001',
        invoiceNumber: '2026MSA1094820',
        supplierPin: 'P051999888Z',
        supplierName: 'Mombasa Port Forwarders',
        buyerPin: 'P051284920A',
        buyerName: 'Apex Logistics Kenya Ltd',
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: 'August 2026',
        taxableAmount: 5000000.0,
        vatAmount: 800000.0,
        totalAmount: 5800000.0,
        sourceType: SourceType.erp,
      );

      final results = ReconciliationEngine.reconcileCustoms(
        customsEntries: [customsEntry],
        erpRecords: [erpImportInvoice],
      );

      expect(results.length, equals(1));
      expect(results.first.status, equals(CustomsMatchStatus.matched));
      expect(results.first.isMatched, isTrue);
      expect(results.first.vatVariance, equals(0.0));
    });

    test('VatApportionmentService.calculate evaluates >90% De Minimis as 100% claimable', () {
      final result = VatApportionmentService.calculate(
        taxableSales16Percent: 9500000.0,
        zeroRatedSales: 0.0,
        exemptSales: 500000.0,
        totalInputVatPaid: 1000000.0,
      );

      expect(result.apportionmentRatio, equals(100.0));
      expect(result.is100PercentClaimable, isTrue);
      expect(result.claimableInputVat, equals(1000000.0));
      expect(result.nonDeductibleInputVat, equals(0.0));
    });

    test('VatApportionmentService.calculate evaluates <10% restriction as 0% claimable', () {
      final result = VatApportionmentService.calculate(
        taxableSales16Percent: 500000.0,
        zeroRatedSales: 0.0,
        exemptSales: 9500000.0,
        totalInputVatPaid: 1000000.0,
      );

      expect(result.apportionmentRatio, equals(0.0));
      expect(result.is0PercentClaimable, isTrue);
      expect(result.claimableInputVat, equals(0.0));
      expect(result.nonDeductibleInputVat, equals(1000000.0));
    });

    test('VatApportionmentService.calculate evaluates pro-rata ratio correctly between 10% and 90%', () {
      final result = VatApportionmentService.calculate(
        taxableSales16Percent: 6000000.0,
        zeroRatedSales: 2000000.0, // Total Taxable = 8M (80%)
        exemptSales: 2000000.0, // Total Sales = 10M
        totalInputVatPaid: 1000000.0,
      );

      expect(result.apportionmentRatio, equals(80.0));
      expect(result.claimableInputVat, equals(800000.0));
      expect(result.nonDeductibleInputVat, equals(200000.0));
    });
  });
}
