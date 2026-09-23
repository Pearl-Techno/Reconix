import 'package:flutter/foundation.dart';
import '../models/invoice_record.dart';
import '../models/reconciliation_match.dart';
import '../models/reconciliation_rules.dart';
import '../models/whvat_record.dart';

class WhvatMatchResult {
  final WhvatRecord whvatRecord;
  final InvoiceRecord? matchedInvoice;
  final bool isMatched;
  final double variance;
  final String statusDescription;

  const WhvatMatchResult({
    required this.whvatRecord,
    this.matchedInvoice,
    required this.isMatched,
    required this.variance,
    required this.statusDescription,
  });
}

List<ReconciliationMatch> _reconcileIsolateEntryPoint(Map<String, dynamic> args) {
  final erpRecords = (args['erpRecords'] as List).cast<InvoiceRecord>();
  final etimsRecords = (args['etimsRecords'] as List).cast<InvoiceRecord>();
  final itaxRecords = (args['itaxRecords'] as List).cast<InvoiceRecord>();
  final rules = args['rules'] as ReconciliationRules;

  return ReconciliationEngine.reconcile(
    erpRecords: erpRecords,
    etimsRecords: etimsRecords,
    itaxRecords: itaxRecords,
    rules: rules,
  );
}

class ReconciliationEngine {
  /// Offloads 3-way reconciliation calculation to a background isolate thread
  static Future<List<ReconciliationMatch>> reconcileAsync({
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> etimsRecords,
    required List<InvoiceRecord> itaxRecords,
    ReconciliationRules rules = const ReconciliationRules(),
  }) async {
    return compute(_reconcileIsolateEntryPoint, {
      'erpRecords': erpRecords,
      'etimsRecords': etimsRecords,
      'itaxRecords': itaxRecords,
      'rules': rules,
    });
  }

  /// Executes 3-way reconciliation between ERP, eTIMS, and iTax invoice records with rules
  static List<ReconciliationMatch> reconcile({
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> etimsRecords,
    required List<InvoiceRecord> itaxRecords,
    ReconciliationRules rules = const ReconciliationRules(),
  }) {
    final Map<String, InvoiceRecord> erpMap = {};
    final Map<String, InvoiceRecord> etimsMap = {};
    final Map<String, InvoiceRecord> itaxMap = {};
    final Set<String> allKeys = {};

    // 1. Index ERP records
    for (var r in erpRecords) {
      final key = _makeKey(r.supplierPin, r.invoiceNumber, rules);
      erpMap[key] = r;
      allKeys.add(key);
    }

    // 2. Index eTIMS records
    for (var r in etimsRecords) {
      final key = _makeKey(r.supplierPin, r.invoiceNumber, rules);
      etimsMap[key] = r;
      allKeys.add(key);
    }

    // 3. Index iTax records
    for (var r in itaxRecords) {
      final key = _makeKey(r.supplierPin, r.invoiceNumber, rules);
      itaxMap[key] = r;
      allKeys.add(key);
    }

    final List<ReconciliationMatch> results = [];
    int matchIndex = 1;

    for (var key in allKeys) {
      final erp = erpMap[key];
      final etims = etimsMap[key];
      final itax = itaxMap[key];

      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      // Evaluate match scenario
      if (erp != null && etims != null && itax != null) {
        // 3-Way present
        final totalDiff = (erp.totalAmount - etims.totalAmount).abs() +
            (erp.totalAmount - itax.totalAmount).abs();
        final vatDiff = (erp.vatAmount - etims.vatAmount).abs() +
            (erp.vatAmount - itax.vatAmount).abs();

        if (totalDiff <= (rules.amountToleranceKes * 2) && vatDiff <= (rules.amountToleranceKes * 2)) {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: key,
            status: MatchStatus.matched,
            riskLevel: RiskLevel.safe,
            erpRecord: erp,
            etimsRecord: etims,
            itaxRecord: itax,
            vatVariance: 0.0,
            totalVariance: 0.0,
            claimableVatAtRisk: 0.0,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Perfect 3-way match across eTIMS, ERP, and iTax. Cleared for VAT return filing.',
            actionPlan: 'Include in monthly VAT 7 return filing schedule as verified input tax.',
          ));
        } else {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: key,
            status: MatchStatus.amountRateVariance,
            riskLevel: RiskLevel.medium,
            erpRecord: erp,
            etimsRecord: etims,
            itaxRecord: itax,
            vatVariance: (erp.vatAmount - etims.vatAmount).abs(),
            totalVariance: (erp.totalAmount - etims.totalAmount).abs(),
            claimableVatAtRisk: (erp.vatAmount - etims.vatAmount).abs(),
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Amount mismatch detected between internal books (KES ${erp.totalAmount.toStringAsFixed(2)}) and eTIMS (KES ${etims.totalAmount.toStringAsFixed(2)}).',
            actionPlan: 'Verify credit notes or rounding differences with supplier ${erp.supplierName}. Adjust internal entry before filing.',
          ));
        }
      } else if (erp != null && etims != null && itax == null) {
        // In ERP & eTIMS, missing in iTax pre-filled schedule
        final daysDiff = DateTime.now().difference(etims.invoiceDate).inDays;
        
        if (daysDiff <= 7) {
          // Recent invoice - timing latency
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: key,
            status: MatchStatus.timingLatency,
            riskLevel: RiskLevel.low,
            erpRecord: erp,
            etimsRecord: etims,
            itaxRecord: null,
            vatVariance: 0.0,
            totalVariance: 0.0,
            claimableVatAtRisk: 0.0,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Valid eTIMS invoice transmitted, but auto-population on iTax is queued in KRA batch latency window.',
            actionPlan: 'Wait for KRA nightly batch refresh or manually add row in iTax schedule using eTIMS Control Code ${etims.etimsControlCode ?? "N/A"}.',
          ));
        } else {
          // Unclaimed input VAT risk
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: key,
            status: MatchStatus.unclaimedInputVat,
            riskLevel: RiskLevel.high,
            erpRecord: erp,
            etimsRecord: etims,
            itaxRecord: null,
            vatVariance: erp.vatAmount,
            totalVariance: erp.totalAmount,
            claimableVatAtRisk: erp.vatAmount,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Valid eTIMS invoice exists in ERP & eTIMS but omitted from pre-filled iTax return. KES ${erp.vatAmount.toStringAsFixed(2)} input VAT at risk of non-claim!',
            actionPlan: 'Manually insert eTIMS invoice entry into iTax VAT 7 Section B schedule prior to 20th deadline to secure input VAT credit.',
          ));
        }
      } else if (erp != null && etims == null) {
        // In ERP books, but missing eTIMS record
        final isVatClaimed = erp.vatAmount > 0;
        final status = isVatClaimed
            ? MatchStatus.vaaDisallowanceRisk
            : MatchStatus.expenseValidationRisk2026;
        final riskLevel = isVatClaimed ? RiskLevel.critical : RiskLevel.high;

        results.add(ReconciliationMatch(
          matchId: matchId,
          invoiceKey: key,
          status: status,
          riskLevel: riskLevel,
          erpRecord: erp,
          etimsRecord: null,
          itaxRecord: itax,
          vatVariance: erp.vatAmount,
          totalVariance: erp.totalAmount,
          claimableVatAtRisk: erp.vatAmount,
          incomeTaxDisallowanceRisk: erp.taxableAmount,
          recommendation: isVatClaimed
              ? 'CRITICAL VAA EXPOSURE: Input VAT of KES ${erp.vatAmount.toStringAsFixed(2)} claimed in books but supplier PIN ${erp.supplierPin} did not generate eTIMS invoice! KRA automated audit will issue VAA disallowance notice.'
              : '2026 EXPENSE RISK: Purchase of KES ${erp.taxableAmount.toStringAsFixed(2)} booked without eTIMS QR/Control Code. Section 16(1) will reject corporate tax expense deduction.',
          actionPlan: 'Contact supplier ${erp.supplierName} immediately to demand eTIMS credit/invoice transmission. If unresponsive, exclude input VAT claim to avoid 100% VAA penalty.',
        ));
      } else if (etims != null && erp == null) {
        // eTIMS transmitted, missing in ERP purchase ledger
        results.add(ReconciliationMatch(
          matchId: matchId,
          invoiceKey: key,
          status: MatchStatus.unmatchedEtimsOnly,
          riskLevel: RiskLevel.medium,
          erpRecord: null,
          etimsRecord: etims,
          itaxRecord: itax,
          vatVariance: etims.vatAmount,
          totalVariance: etims.totalAmount,
          claimableVatAtRisk: 0.0,
          incomeTaxDisallowanceRisk: 0.0,
          recommendation: 'eTIMS invoice issued under company PIN ${etims.buyerPin} by supplier ${etims.supplierName} for KES ${etims.totalAmount.toStringAsFixed(2)}, but unbooked in ERP ledger.',
          actionPlan: 'Verify with procurement department if goods/services were received. If valid, record in purchase journal to claim KES ${etims.vatAmount.toStringAsFixed(2)} input VAT.',
        ));
      } else if (itax != null && erp == null && etims == null) {
        // iTax entry present without ERP or eTIMS
        results.add(ReconciliationMatch(
          matchId: matchId,
          invoiceKey: key,
          status: MatchStatus.unmatchedItaxOnly,
          riskLevel: RiskLevel.high,
          erpRecord: null,
          etimsRecord: null,
          itaxRecord: itax,
          vatVariance: itax.vatAmount,
          totalVariance: itax.totalAmount,
          claimableVatAtRisk: 0.0,
          incomeTaxDisallowanceRisk: 0.0,
          recommendation: 'Unrecognized invoice entry auto-populated on iTax schedule for KES ${itax.totalAmount.toStringAsFixed(2)} from PIN ${itax.supplierPin}.',
          actionPlan: 'Audit supplier relationship or contest line item on iTax portal if unauthorized or fraudulent PIN usage.',
        ));
      }
    }

    // Sort: Critical & High risk items first
    results.sort((a, b) => b.riskLevel.index.compareTo(a.riskLevel.index));

    return results;
  }

  static String _makeKey(String pin, String invoiceNo, ReconciliationRules rules) {
    String cleanPin = pin.toUpperCase().trim();
    String cleanInv = invoiceNo.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (rules.ignoreInvoicePrefixes) {
      if (cleanInv.startsWith('INV')) {
        cleanInv = cleanInv.substring(3);
      }
      cleanInv = cleanInv.replaceFirst(RegExp(r'^0+'), ''); // Strip leading zeros
    }
    return '${cleanPin}_$cleanInv';
  }

  /// Reconciles 2% Withholding VAT (WHVAT) certificates against sales/purchase invoices
  static List<WhvatMatchResult> reconcileWhvat({
    required List<WhvatRecord> whvatRecords,
    required List<InvoiceRecord> invoiceRecords,
  }) {
    final Map<String, InvoiceRecord> invoiceMap = {};
    for (var inv in invoiceRecords) {
      final cleanInv = inv.invoiceNumber.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      invoiceMap[cleanInv] = inv;
    }

    final List<WhvatMatchResult> results = [];
    for (var whv in whvatRecords) {
      final cleanInv = whv.invoiceNumber.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final matched = invoiceMap[cleanInv];

      if (matched != null) {
        final expectedWhvat = matched.taxableAmount * 0.02;
        final diff = (whv.whvatAmount - expectedWhvat).abs();
        if (diff <= 2.0) {
          results.add(WhvatMatchResult(
            whvatRecord: whv,
            matchedInvoice: matched,
            isMatched: true,
            variance: 0.0,
            statusDescription: 'MATCHED: 2% WHVAT Credit of KES ${whv.whvatAmount.toStringAsFixed(2)} verified against Invoice ${matched.invoiceNumber}.',
          ));
        } else {
          results.add(WhvatMatchResult(
            whvatRecord: whv,
            matchedInvoice: matched,
            isMatched: false,
            variance: diff,
            statusDescription: 'VARIANCE: WHVAT amount KES ${whv.whvatAmount.toStringAsFixed(2)} differs from expected 2% tax rate (KES ${expectedWhvat.toStringAsFixed(2)}).',
          ));
        }
      } else {
        results.add(WhvatMatchResult(
          whvatRecord: whv,
          matchedInvoice: null,
          isMatched: false,
          variance: whv.whvatAmount,
          statusDescription: 'UNMATCHED: WHVAT certificate ${whv.certificateNumber} has no corresponding invoice in ledger.',
        ));
      }
    }
    return results;
  }
}
