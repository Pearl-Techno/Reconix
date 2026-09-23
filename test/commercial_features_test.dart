import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/models/invoice_record.dart';
import 'package:reconix/models/whvat_record.dart';
import 'package:reconix/models/customs_entry_record.dart';
import 'package:reconix/models/audit_log_entry.dart';
import 'package:reconix/models/reconciliation_match.dart';
import 'package:reconix/models/taxpayer_client.dart';
import 'package:reconix/services/supplier_chaser_service.dart';
import 'package:reconix/services/data_ingestion_service.dart';
import 'package:reconix/services/reconciliation_engine.dart';
import 'package:reconix/services/historical_trend_service.dart';
import 'package:reconix/services/pre_filing_validation_engine.dart';
import 'package:reconix/services/itax_filing_bundle_service.dart';
import 'package:reconix/services/erp_connector_service.dart';
import 'package:reconix/services/license_service.dart';

void main() {
  group('Commercial Feature Expansion Tests', () {
    final client = TaxpayerClient(
      id: 'CLI-TEST-001',
      businessName: 'Apex Enterprise Test Ltd',
      kraPin: 'P051284920A',
      vatRegistrationNo: 'VAT-051284920A',
      contactEmail: 'tax@apex.co.ke',
      sector: 'Logistics',
      currentTaxPeriod: '2026-08',
      totalMonthlyPurchases: 500000.0,
      inputVatClaimable: 80000.0,
      inputVatAtRisk: 0.0,
      totalInvoicesCount: 10,
      matchedInvoicesCount: 10,
      riskStatus: 'READY_TO_FILE',
    );

    final erpRecord = InvoiceRecord(
      id: 'REC-ERP-1',
      invoiceNumber: 'INV-1001',
      supplierPin: 'P051987654Z',
      supplierName: 'Safaricom PLC',
      buyerPin: 'P051284920A',
      buyerName: 'Apex Enterprise Test Ltd',
      invoiceDate: DateTime(2026, 8, 10),
      taxPeriod: '2026-08',
      taxableAmount: 100000.0,
      vatAmount: 16000.0,
      totalAmount: 116000.0,
      sourceType: SourceType.erp,
    );

    final etimsRecord = InvoiceRecord(
      id: 'REC-ETIMS-1',
      invoiceNumber: 'INV-1001',
      etimsControlCode: '00101938000000000112',
      supplierPin: 'P051987654Z',
      supplierName: 'Safaricom PLC',
      buyerPin: 'P051284920A',
      buyerName: 'Apex Enterprise Test Ltd',
      invoiceDate: DateTime(2026, 8, 10),
      taxPeriod: '2026-08',
      taxableAmount: 100000.0,
      vatAmount: 16000.0,
      totalAmount: 116000.0,
      sourceType: SourceType.etims,
    );

    final match = ReconciliationMatch(
      matchId: 'MCH-0001',
      invoiceKey: 'P051987654Z_INV1001',
      status: MatchStatus.matched,
      riskLevel: RiskLevel.safe,
      erpRecord: erpRecord,
      etimsRecord: etimsRecord,
      itaxRecord: etimsRecord,
      vatVariance: 0.0,
      totalVariance: 0.0,
      claimableVatAtRisk: 0.0,
      incomeTaxDisallowanceRisk: 0.0,
      recommendation: 'Matched',
      actionPlan: 'Include in filing',
    );

    test('InvoiceRecord signed amounts calculate negative values for Credit Notes', () {
      final cnRecord = InvoiceRecord(
        id: 'REC-CN-1',
        invoiceNumber: 'CN-2001',
        supplierPin: 'P051987654Z',
        supplierName: 'Safaricom PLC',
        buyerPin: 'P051284920A',
        buyerName: 'Apex Enterprise Test Ltd',
        invoiceDate: DateTime(2026, 8, 12),
        taxPeriod: '2026-08',
        taxableAmount: 20000.0,
        vatAmount: 3200.0,
        totalAmount: 23200.0,
        sourceType: SourceType.erp,
        invoiceType: InvoiceType.creditNote,
      );

      expect(cnRecord.signedTaxableAmount, -20000.0);
      expect(cnRecord.signedVatAmount, -3200.0);
      expect(cnRecord.signedTotalAmount, -23200.0);
    });

    test('WhvatRecord serializes and deserializes correctly', () {
      final whvat = WhvatRecord(
        id: 'WHV-001',
        certificateNumber: 'WHV-2026-08-001',
        supplierPin: 'P051987654Z',
        supplierName: 'Safaricom PLC',
        buyerPin: 'P051284920A',
        buyerName: 'Apex Enterprise Test Ltd',
        certificateDate: DateTime(2026, 8, 15),
        taxPeriod: '2026-08',
        grossInvoiceAmount: 100000.0,
        whvatAmount: 2000.0,
        invoiceNumber: 'INV-1001',
      );

      final map = whvat.toMap();
      final reconstituted = WhvatRecord.fromMap(map);

      expect(reconstituted.certificateNumber, 'WHV-2026-08-001');
      expect(reconstituted.whvatAmount, 2000.0);
      expect(reconstituted.isClaimedOnItax, true);
    });

    test('CustomsEntryRecord serializes and deserializes correctly', () {
      final entry = CustomsEntryRecord(
        id: 'CUST-001',
        entryNumber: '2026MSA1094820',
        customsStation: 'Mombasa Port',
        importerPin: 'P051284920A',
        importerName: 'Apex Enterprise Test Ltd',
        declarationDate: DateTime(2026, 8, 5),
        taxPeriod: '2026-08',
        taxableValue: 500000.0,
        importVatAmount: 80000.0,
        hsCode: '8471.30.00',
      );

      final map = entry.toMap();
      final reconstituted = CustomsEntryRecord.fromMap(map);

      expect(reconstituted.entryNumber, '2026MSA1094820');
      expect(reconstituted.importVatAmount, 80000.0);
      expect(reconstituted.customsStation, 'Mombasa Port');
    });

    test('SupplierChaserService generates formal email and WhatsApp dispute notices', () {
      final notice = SupplierChaserService.generateNotice(
        client: client,
        supplierDiscrepancies: [match],
      );

      expect(notice.supplierName, 'Safaricom PLC');
      expect(notice.supplierPin, 'P051987654Z');
      expect(notice.emailSubject, contains('Missing eTIMS Tax Invoice Confirmation'));
      expect(notice.emailBody, contains('INV-1001'));
      expect(notice.emailBody, contains('KRA VAA Penalties'));
      expect(notice.whatsappMessage, contains('URGENT TAX NOTICE'));
    });

    test('DataIngestionService parses WHVAT 2% CSV correctly', () {
      const csv = 'CertificateNo,SupplierPin,SupplierName,BuyerPin,BuyerName,Date,GrossAmount,WhvatAmount,InvoiceNo\n'
          'WHV-100,P051987654Z,Safaricom PLC,P051284920A,Apex Ltd,2026-08-10,100000,2000,INV-1001';

      final records = DataIngestionService.parseWhvatCsv(csvContent: csv, defaultTaxPeriod: '2026-08');

      expect(records.length, 1);
      expect(records.first.certificateNumber, 'WHV-100');
      expect(records.first.whvatAmount, 2000.0);
      expect(records.first.invoiceNumber, 'INV-1001');
    });

    test('ReconciliationEngine.reconcileWhvat matches 2% WHVAT certificate to invoice', () {
      final whvat = WhvatRecord(
        id: 'WHV-1',
        certificateNumber: 'WHV-100',
        supplierPin: 'P051987654Z',
        supplierName: 'Safaricom PLC',
        buyerPin: 'P051284920A',
        buyerName: 'Apex Ltd',
        certificateDate: DateTime(2026, 8, 10),
        taxPeriod: '2026-08',
        grossInvoiceAmount: 100000.0,
        whvatAmount: 2000.0,
        invoiceNumber: 'INV-1001',
      );

      final results = ReconciliationEngine.reconcileWhvat(
        whvatRecords: [whvat],
        invoiceRecords: [erpRecord],
      );

      expect(results.length, 1);
      expect(results.first.isMatched, true);
      expect(results.first.matchedInvoice?.invoiceNumber, 'INV-1001');
    });

    test('AuditLogEntry serializes and deserializes correctly', () {
      final log = AuditLogEntry(
        id: 'LOG-001',
        userId: 'USR-001',
        userName: 'Jane Tax Auditor',
        userRole: UserRole.seniorTaxManager,
        action: 'VERIFIED_FOR_ITAX',
        targetInvoiceKey: 'P051987654Z_INV1001',
        timestamp: DateTime(2026, 8, 20),
        details: 'Approved line item after supplier confirmation',
      );

      final map = log.toMap();
      final reconstituted = AuditLogEntry.fromMap(map);

      expect(reconstituted.action, 'VERIFIED_FOR_ITAX');
      expect(reconstituted.userRole, UserRole.seniorTaxManager);
      expect(reconstituted.userName, 'Jane Tax Auditor');
    });

    test('HistoricalTrendService calculates multi-period VAT analytics and supplier risk profiles', () {
      final summaries = HistoricalTrendService.generateMultiPeriodAnalytics(
        allErpRecords: [erpRecord],
        allEtimsRecords: [etimsRecord],
        allItaxRecords: [etimsRecord],
      );

      expect(summaries.isNotEmpty, true);
      expect(summaries.first.taxPeriod, '2026-08');

      final profiles = HistoricalTrendService.calculateSupplierRiskProfiles(
        erpRecords: [erpRecord],
        etimsRecords: [etimsRecord],
      );

      expect(profiles.length, 1);
      expect(profiles.first.supplierPin, 'P051987654Z');
    });

    test('PreFilingValidationEngine evaluates pre-flight audit rules', () {
      final report = PreFilingValidationEngine.validateReturn(
        salesRecords: [],
        purchaseRecords: [erpRecord],
        customsEntries: [],
        whvatRecords: [],
      );

      expect(report.totalRecordsAudited, 1);
      expect(report.isReadyForFiling, false); // Due to missing eTIMS control code on raw erpRecord
      expect(report.errorCount, 1);
    });

    test('ITaxFilingBundleService generates sanitized 4-in-1 CSV upload bundle', () {
      final bundle = ITaxFilingBundleService.generateFilingBundle(
        client: client,
        taxPeriod: '2026-08',
        salesRecords: [],
        purchaseRecords: [erpRecord],
        customsEntries: [],
        whvatRecords: [],
      );

      expect(bundle.sectionBCsv, contains('P051987654Z'));
      expect(bundle.sectionBCsv, contains('Safaricom PLC'));
      expect(bundle.sectionACsv, contains('Customer KRA PIN'));
    });

    test('ErpConnectorService parses Tally Prime XML and QuickBooks CSV correctly', () {
      const tallyXml = '<VOUCHER><VOUCHERNUMBER>INV-999</VOUCHERNUMBER><PARTYLEDGERNAME>Apex Supplier</PARTYLEDGERNAME><AMOUNT>116000.0</AMOUNT></VOUCHER>';
      final tallyRecords = ErpConnectorService.parseTallyXml(xmlContent: tallyXml, defaultTaxPeriod: '2026-08');

      expect(tallyRecords.length, 1);
      expect(tallyRecords.first.invoiceNumber, 'INV-999');

      const qbCsv = 'InvoiceNo,Vendor,PIN,Total\nQB-101,QuickVendor,P051999000Z,58000';
      final qbRecords = ErpConnectorService.parseQuickBooksCsv(csvContent: qbCsv, defaultTaxPeriod: '2026-08');

      expect(qbRecords.length, 1);
      expect(qbRecords.first.invoiceNumber, 'QB-101');
    });

    test('LicenseService verifies obfuscated master activation key and invalid keys correctly', () {
      expect(LicenseService.verifyLicenseKey('120196'), true);
      expect(LicenseService.verifyLicenseKey(' 120196 '), true);
      expect(LicenseService.verifyLicenseKey('QUANTYX001'), true);
      expect(LicenseService.verifyLicenseKey('INVALID_KEY_999'), false);
    });
  });
}
