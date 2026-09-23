import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/models/invoice_record.dart';
import 'package:reconix/models/reconciliation_match.dart';
import 'package:reconix/models/taxpayer_client.dart';
import 'package:reconix/services/itax_export_service.dart';

void main() {
  group('ITaxExportService & Section B CSV Tests', () {
    test('generateITaxSectionBCsv exports claimable input VAT records with KRA headers', () {
      final client = TaxpayerClient(
        id: 'CLI-001',
        businessName: 'Apex Logistics Kenya Ltd',
        kraPin: 'P051234567A',
        vatRegistrationNo: 'VAT-051234567A',
        contactEmail: 'tax@apex.co.ke',
        sector: 'Transport & Logistics',
        currentTaxPeriod: '2026-08',
        totalMonthlyPurchases: 5000000.0,
        inputVatClaimable: 800000.0,
        inputVatAtRisk: 120000.0,
        totalInvoicesCount: 14,
        matchedInvoicesCount: 10,
        riskStatus: 'READINESS_REVIEW',
      );

      final matches = [
        ReconciliationMatch(
          matchId: 'MCH-0001',
          invoiceKey: 'P051111111A_INV-101',
          status: MatchStatus.matched,
          riskLevel: RiskLevel.safe,
          erpRecord: InvoiceRecord(
            id: 'E1',
            invoiceNumber: 'INV-101',
            supplierPin: 'P051111111A',
            supplierName: 'Safaricom PLC',
            buyerPin: 'P051234567A',
            buyerName: 'Apex Logistics Kenya Ltd',
            invoiceDate: DateTime(2026, 8, 5),
            taxPeriod: '2026-08',
            taxableAmount: 10000.0,
            vatAmount: 1600.0,
            totalAmount: 11600.0,
            sourceType: SourceType.erp,
            etimsControlCode: 'ETM-2026-SAF-001',
          ),
          etimsRecord: null,
          itaxRecord: null,
          vatVariance: 0.0,
          totalVariance: 0.0,
          claimableVatAtRisk: 0.0,
          incomeTaxDisallowanceRisk: 0.0,
          recommendation: 'Perfect match',
          actionPlan: 'Claim',
        ),
      ];

      final csv = ITaxExportService.generateITaxSectionBCsv(
        client: client,
        taxPeriod: 'August 2026',
        matches: matches,
      );

      expect(csv, contains('Supplier KRA PIN'));
      expect(csv, contains('Supplier Business Name'));
      expect(csv, contains('P051111111A'));
      expect(csv, contains('Safaricom PLC'));
      expect(csv, contains('1600.00'));
      expect(csv, contains('ETM-2026-SAF-001'));
    });
  });
}
