import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/models/invoice_record.dart';
import 'package:reconix/models/reconciliation_match.dart';
import 'package:reconix/services/reconciliation_engine.dart';

void main() {
  group('ReconciliationEngine 3-Way Matching Tests', () {
    test('Perfect 3-Way Match returns MatchStatus.matched with RiskLevel.safe', () {
      final erp = InvoiceRecord(
        id: 'ERP-1',
        invoiceNumber: 'INV-1001',
        supplierPin: 'P051234567A',
        supplierName: 'Supplier A',
        buyerPin: 'P059999999Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: '2026-08',
        taxableAmount: 1000.0,
        vatAmount: 160.0,
        totalAmount: 1160.0,
        sourceType: SourceType.erp,
      );

      final etims = InvoiceRecord(
        id: 'ETM-1',
        invoiceNumber: 'INV-1001',
        supplierPin: 'P051234567A',
        supplierName: 'Supplier A',
        buyerPin: 'P059999999Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: '2026-08',
        taxableAmount: 1000.0,
        vatAmount: 160.0,
        totalAmount: 1160.0,
        sourceType: SourceType.etims,
      );

      final itax = InvoiceRecord(
        id: 'ITX-1',
        invoiceNumber: 'INV-1001',
        supplierPin: 'P051234567A',
        supplierName: 'Supplier A',
        buyerPin: 'P059999999Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: '2026-08',
        taxableAmount: 1000.0,
        vatAmount: 160.0,
        totalAmount: 1160.0,
        sourceType: SourceType.itax,
      );

      final results = ReconciliationEngine.reconcile(
        erpRecords: [erp],
        etimsRecords: [etims],
        itaxRecords: [itax],
      );

      expect(results.length, equals(1));
      expect(results.first.status, equals(MatchStatus.matched));
      expect(results.first.riskLevel, equals(RiskLevel.safe));
      expect(results.first.claimableVatAtRisk, equals(0.0));
    });

    test('ERP & eTIMS present, missing iTax (old date) triggers unclaimedInputVat', () {
      final erp = InvoiceRecord(
        id: 'ERP-2',
        invoiceNumber: 'INV-2002',
        supplierPin: 'P051234567A',
        supplierName: 'Supplier A',
        buyerPin: 'P059999999Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 1),
        taxPeriod: '2026-08',
        taxableAmount: 5000.0,
        vatAmount: 800.0,
        totalAmount: 5800.0,
        sourceType: SourceType.erp,
      );

      final etims = InvoiceRecord(
        id: 'ETM-2',
        invoiceNumber: 'INV-2002',
        supplierPin: 'P051234567A',
        supplierName: 'Supplier A',
        buyerPin: 'P059999999Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 1),
        taxPeriod: '2026-08',
        taxableAmount: 5000.0,
        vatAmount: 800.0,
        totalAmount: 5800.0,
        sourceType: SourceType.etims,
      );

      final results = ReconciliationEngine.reconcile(
        erpRecords: [erp],
        etimsRecords: [etims],
        itaxRecords: [],
      );

      expect(results.length, equals(1));
      expect(results.first.status, equals(MatchStatus.unclaimedInputVat));
      expect(results.first.claimableVatAtRisk, equals(800.0));
    });

    test('ERP present without eTIMS triggers vaaDisallowanceRisk for VAT claimed', () {
      final erp = InvoiceRecord(
        id: 'ERP-3',
        invoiceNumber: 'INV-3003',
        supplierPin: 'P059876543B',
        supplierName: 'Non-eTIMS Supplier',
        buyerPin: 'P059999999Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 15),
        taxPeriod: '2026-08',
        taxableAmount: 10000.0,
        vatAmount: 1600.0,
        totalAmount: 11600.0,
        sourceType: SourceType.erp,
      );

      final results = ReconciliationEngine.reconcile(
        erpRecords: [erp],
        etimsRecords: [],
        itaxRecords: [],
      );

      expect(results.length, equals(1));
      expect(results.first.status, equals(MatchStatus.vaaDisallowanceRisk));
      expect(results.first.riskLevel, equals(RiskLevel.critical));
      expect(results.first.claimableVatAtRisk, equals(1600.0));
      expect(results.first.incomeTaxDisallowanceRisk, equals(10000.0));
    });
  });
}
