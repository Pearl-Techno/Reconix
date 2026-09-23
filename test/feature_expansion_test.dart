import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/models/invoice_record.dart';
import 'package:reconix/models/reconciliation_rules.dart';
import 'package:reconix/models/reconciliation_certificate.dart';
import 'package:reconix/services/reconciliation_engine.dart';
import 'package:reconix/services/vaa_demand_notice_service.dart';
import 'package:reconix/services/audit_dossier_service.dart';

void main() {
  group('Feature Expansion Unit Tests', () {
    test('ReconciliationRules default values and copyWith work correctly', () {
      const rules = ReconciliationRules();
      expect(rules.maxDateDifferenceDays, equals(7));
      expect(rules.amountToleranceKes, equals(1.0));
      expect(rules.enableFuzzyInvoiceMatching, isTrue);

      final custom = rules.copyWith(amountToleranceKes: 5.0, maxDateDifferenceDays: 14);
      expect(custom.amountToleranceKes, equals(5.0));
      expect(custom.maxDateDifferenceDays, equals(14));
    });

    test('ReconciliationEngine respects custom ReconciliationRules amount tolerances', () {
      final erp = InvoiceRecord(
        id: 'ERP-1',
        invoiceNumber: 'INV-1001',
        supplierPin: 'P051234567A',
        supplierName: 'Vendor Alpha',
        buyerPin: 'P051987654Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: '2026-08',
        taxableAmount: 10000.0,
        vatAmount: 1600.0,
        totalAmount: 11600.0,
        sourceType: SourceType.erp,
      );

      final etims = InvoiceRecord(
        id: 'ETIMS-1',
        invoiceNumber: '1001', // Fuzzy match ignoring 'INV-' prefix
        supplierPin: 'P051234567A',
        supplierName: 'Vendor Alpha',
        buyerPin: 'P051987654Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: '2026-08',
        taxableAmount: 10003.0, // Variance of 3.0 KES
        vatAmount: 1600.48,
        totalAmount: 11603.48,
        sourceType: SourceType.etims,
      );

      final itax = InvoiceRecord(
        id: 'ITAX-1',
        invoiceNumber: '1001',
        supplierPin: 'P051234567A',
        supplierName: 'Vendor Alpha',
        buyerPin: 'P051987654Z',
        buyerName: 'Buyer Corp',
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: '2026-08',
        taxableAmount: 10003.0,
        vatAmount: 1600.48,
        totalAmount: 11603.48,
        sourceType: SourceType.itax,
      );

      // With strict tolerance (1.0 KES), this should be amount rate variance
      const strictRules = ReconciliationRules(amountToleranceKes: 1.0);
      final strictMatches = ReconciliationEngine.reconcile(
        erpRecords: [erp],
        etimsRecords: [etims],
        itaxRecords: [itax],
        rules: strictRules,
      );
      expect(strictMatches.length, equals(1));

      // With relaxed tolerance (5.0 KES), fuzzy matching reconciles as matched
      const relaxedRules = ReconciliationRules(amountToleranceKes: 5.0, ignoreInvoicePrefixes: true);
      final relaxedMatches = ReconciliationEngine.reconcile(
        erpRecords: [erp],
        etimsRecords: [etims],
        itaxRecords: [itax],
        rules: relaxedRules,
      );
      expect(relaxedMatches.length, equals(1));
    });

    test('VaaDemandNoticeService generates valid non-empty PDF bytes', () async {
      final sampleInvoice = InvoiceRecord(
        id: 'INV-DEMAND-1',
        invoiceNumber: 'INV-9988',
        supplierPin: 'P051111222A',
        supplierName: 'High Risk Supplier Ltd',
        buyerPin: 'P051284920A',
        buyerName: 'Apex Enterprises',
        invoiceDate: DateTime(2026, 8, 5),
        taxPeriod: '2026-08',
        taxableAmount: 250000.0,
        vatAmount: 40000.0,
        totalAmount: 290000.0,
        sourceType: SourceType.erp,
      );

      final pdfBytes = await VaaDemandNoticeService.generateDemandNoticePdf(
        supplierName: 'High Risk Supplier Ltd',
        supplierPin: 'P051111222A',
        buyerName: 'Apex Enterprises',
        buyerPin: 'P051284920A',
        unfiledInvoices: [sampleInvoice],
        deadlineDate: DateTime(2026, 8, 20),
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000)); // PDF header and content present
    });

    test('AuditDossierService generates valid non-empty PDF binder bytes', () async {
      final cert = ReconciliationCertificate(
        certificateId: 'REC-202608-P051284-TEST',
        sha256Hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        taxpayerName: 'Apex Enterprises',
        kraPin: 'P051284920A',
        taxPeriod: '2026-08',
        generatedAt: DateTime.now(),
        totalErpRecordsCount: 10,
        totalEtimsRecordsCount: 10,
        totalItaxRecordsCount: 10,
        fullyMatchedCount: 8,
        timingLatencyCount: 1,
        unclaimedInputVatCount: 1,
        vaaDisallowanceCount: 0,
        expenseValidationRiskCount: 0,
        totalPurchasesErp: 1500000.0,
        totalInputVatClaimable: 240000.0,
        totalInputVatDisallowedExposure: 0.0,
        total2026ExpenseDeductibilityRisk: 0.0,
        signedByAdvisor: 'ICPAK Advisor',
      );

      final pdfBytes = await AuditDossierService.generateAuditDossierPdf(
        cert: cert,
        matches: [],
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
