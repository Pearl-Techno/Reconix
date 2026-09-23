import 'package:flutter_test/flutter_test.dart';
import 'package:reconix/models/invoice_record.dart';
import 'package:reconix/models/whvat_record.dart';
import 'package:reconix/models/audit_log_entry.dart';
import 'package:reconix/services/penalty_simulator_service.dart';
import 'package:reconix/services/audit_defense_pack_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Final Operational Features Unit Tests', () {
    test('PenaltySimulatorService calculates statutory late filing & disallowance penalties correctly', () {
      final deadline = DateTime(2026, 8, 20);
      final filingDate = DateTime(2026, 9, 5); // 16 days overdue

      final result = PenaltySimulatorService.calculatePenaltyExposure(
        netTaxPayable: 200000.0,
        vaaDisallowanceRiskPool: 50000.0,
        returnDeadline: deadline,
        filingDate: filingDate,
      );

      // Late Filing: 5% of 200,000 = 10,000
      expect(result.lateFilingPenalty, equals(10000.0));
      // Late Payment Interest: 1% * 1 month * 200,000 = 2,000
      expect(result.latePaymentInterest, equals(2000.0));
      // VAA Disallowance Penalty: 20% of 50,000 = 10,000
      expect(result.vaaDisallowancePenalty, equals(10000.0));

      expect(result.totalStatutoryExposure, equals(200000.0 + 50000.0 + 10000.0 + 2000.0 + 10000.0));
      expect(result.breakdownNotes.length, greaterThanOrEqualTo(3));
    });

    test('AuditDefensePackService generates valid PDF byte data', () async {
      final pdfBytes = await AuditDefensePackService.generateAuditDefensePdf(
        businessName: 'Test Entity Ltd',
        kraPin: 'P051111222A',
        taxPeriod: '2026-08',
        erpRecords: [
          InvoiceRecord(
            id: 'INV-1',
            invoiceNumber: 'INV-001',
            supplierPin: 'P051222333B',
            supplierName: 'Vendor A',
            buyerPin: 'P051111222A',
            buyerName: 'Test Entity Ltd',
            invoiceDate: DateTime(2026, 8, 15),
            taxPeriod: '2026-08',
            taxableAmount: 100000.0,
            vatAmount: 16000.0,
            totalAmount: 116000.0,
            sourceType: SourceType.erp,
          ),
        ],
        etimsRecords: [],
        whvatRecords: [
          WhvatRecord(
            id: 'WHT-1',
            certificateNumber: 'WHT-001',
            supplierPin: 'P051222333B',
            supplierName: 'Vendor A',
            buyerPin: 'P051111222A',
            buyerName: 'Test Entity Ltd',
            certificateDate: DateTime(2026, 8, 18),
            taxPeriod: '2026-08',
            grossInvoiceAmount: 100000.0,
            whvatAmount: 2000.0,
            invoiceNumber: 'INV-001',
          ),
        ],
        auditLogs: [
          AuditLogEntry(
            id: 'LOG-1',
            userId: 'USR-1',
            userName: 'Tax Manager',
            userRole: UserRole.admin,
            action: 'TAX_PERIOD_LOCKED',
            targetInvoiceKey: 'P051111222A_2026-08',
            timestamp: DateTime.now(),
            details: 'Tax Period Locked',
          ),
        ],
        userRole: 'admin',
        isLocked: true,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('AuditDefensePackService generates valid Multi-Tab Excel byte data', () async {
      final excelBytes = await AuditDefensePackService.generateAuditDefenseExcel(
        businessName: 'Test Entity Ltd',
        kraPin: 'P051111222A',
        taxPeriod: '2026-08',
        erpRecords: [],
        etimsRecords: [],
        whvatRecords: [],
        auditLogs: [],
      );

      expect(excelBytes, isNotEmpty);
      expect(excelBytes.length, greaterThan(500));
    });
  });
}
