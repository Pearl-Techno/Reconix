import 'package:flutter/foundation.dart';
import '../models/invoice_record.dart';
import '../models/reconciliation_match.dart';
import '../models/reconciliation_rules.dart';
import '../models/whvat_record.dart';
import '../models/customs_entry_record.dart';
import '../models/customs_match_result.dart';

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

  /// Executes reconciliation between ERP, eTIMS, and iTax invoice records according to specified rules and mode
  static List<ReconciliationMatch> reconcile({
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> etimsRecords,
    required List<InvoiceRecord> itaxRecords,
    ReconciliationRules rules = const ReconciliationRules(),
  }) {
    // Resolve auto-detect mode if applicable
    ReconciliationMode mode = rules.mode;
    if (mode == ReconciliationMode.autoDetect) {
      if (erpRecords.isNotEmpty && etimsRecords.isNotEmpty && itaxRecords.isNotEmpty) {
        mode = ReconciliationMode.threeWay;
      } else if (erpRecords.isNotEmpty && itaxRecords.isNotEmpty && etimsRecords.isEmpty) {
        mode = ReconciliationMode.twoWayErpItax;
      } else if (etimsRecords.isNotEmpty && itaxRecords.isNotEmpty && erpRecords.isEmpty) {
        mode = ReconciliationMode.twoWayEtimsItax;
      } else if (erpRecords.isNotEmpty && etimsRecords.isNotEmpty && itaxRecords.isEmpty) {
        mode = ReconciliationMode.twoWayErpEtims;
      } else {
        mode = ReconciliationMode.threeWay;
      }
    }

    switch (mode) {
      case ReconciliationMode.twoWayErpItax:
        return _reconcileTwoWayErpItax(erpRecords: erpRecords, itaxRecords: itaxRecords, rules: rules);
      case ReconciliationMode.twoWayEtimsItax:
        return _reconcileTwoWayEtimsItax(etimsRecords: etimsRecords, itaxRecords: itaxRecords, rules: rules);
      case ReconciliationMode.twoWayErpEtims:
        return _reconcileTwoWayErpEtims(erpRecords: erpRecords, etimsRecords: etimsRecords, rules: rules);
      case ReconciliationMode.threeWay:
      case ReconciliationMode.autoDetect:
        return _reconcileThreeWay(erpRecords: erpRecords, etimsRecords: etimsRecords, itaxRecords: itaxRecords, rules: rules);
    }
  }

  static List<ReconciliationMatch> _reconcileThreeWay({
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> etimsRecords,
    required List<InvoiceRecord> itaxRecords,
    required ReconciliationRules rules,
  }) {
    final Map<String, InvoiceRecord> erpFullMap = {};
    final Map<String, InvoiceRecord> erpInvMap = {};
    for (var r in erpRecords) {
      erpFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      erpInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Map<String, InvoiceRecord> etimsFullMap = {};
    final Map<String, InvoiceRecord> etimsInvMap = {};
    for (var r in etimsRecords) {
      etimsFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      etimsInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Map<String, InvoiceRecord> itaxFullMap = {};
    final Map<String, InvoiceRecord> itaxInvMap = {};
    for (var r in itaxRecords) {
      itaxFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      itaxInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Set<String> processedErp = {};
    final Set<String> processedEtims = {};
    final Set<String> processedItax = {};
    final List<ReconciliationMatch> results = [];
    int matchIndex = 1;

    // 1. Primary pass over ERP records
    for (var erp in erpRecords) {
      final fullKey = _makeKey(erp.supplierPin, erp.invoiceNumber, rules);
      final invKey = _cleanInvoiceNumber(erp.invoiceNumber, rules);
      if (processedErp.contains(fullKey)) continue;

      processedErp.add(fullKey);

      InvoiceRecord? etims = etimsFullMap[fullKey] ?? etimsInvMap[invKey];
      if (etims != null && processedEtims.contains(_makeKey(etims.supplierPin, etims.invoiceNumber, rules))) {
        etims = null;
      }
      if (etims != null) {
        processedEtims.add(_makeKey(etims.supplierPin, etims.invoiceNumber, rules));
      }

      InvoiceRecord? itax = itaxFullMap[fullKey] ?? itaxInvMap[invKey];
      if (itax != null && processedItax.contains(_makeKey(itax.supplierPin, itax.invoiceNumber, rules))) {
        itax = null;
      }
      if (itax != null) {
        processedItax.add(_makeKey(itax.supplierPin, itax.invoiceNumber, rules));
      }

      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      if (etims != null && itax != null) {
        final totalDiff = (erp.totalAmount - etims.totalAmount).abs() + (erp.totalAmount - itax.totalAmount).abs();
        final vatDiff = (erp.vatAmount - etims.vatAmount).abs() + (erp.vatAmount - itax.vatAmount).abs();

        if (totalDiff <= (rules.amountToleranceKes * 2) && vatDiff <= (rules.amountToleranceKes * 2)) {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
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
            invoiceKey: fullKey,
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
      } else if (etims != null && itax == null) {
        final daysDiff = DateTime.now().difference(etims.invoiceDate).inDays;
        if (daysDiff <= 7) {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
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
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
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
      } else if (etims == null && itax != null) {
        final totalDiff = (erp.totalAmount - itax.totalAmount).abs();
        final vatDiff = (erp.vatAmount - itax.vatAmount).abs();

        if (totalDiff <= rules.amountToleranceKes && vatDiff <= rules.amountToleranceKes) {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.matched,
            riskLevel: RiskLevel.safe,
            erpRecord: erp,
            etimsRecord: null,
            itaxRecord: itax,
            vatVariance: 0.0,
            totalVariance: 0.0,
            claimableVatAtRisk: 0.0,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Matched: ERP purchase entry matches pre-filled iTax return schedule (KES ${erp.totalAmount.toStringAsFixed(2)}). Cleared for filing.',
            actionPlan: 'Include in monthly VAT 7 return schedule as verified input tax entry.',
          ));
        } else {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.amountRateVariance,
            riskLevel: RiskLevel.medium,
            erpRecord: erp,
            etimsRecord: null,
            itaxRecord: itax,
            vatVariance: vatDiff,
            totalVariance: totalDiff,
            claimableVatAtRisk: vatDiff,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Amount mismatch between ERP books (KES ${erp.totalAmount.toStringAsFixed(2)}) and iTax schedule (KES ${itax.totalAmount.toStringAsFixed(2)}).',
            actionPlan: 'Reconcile taxable base with supplier invoice.',
          ));
        }
      } else if (etims == null && itax == null) {
        final isVatClaimed = erp.vatAmount > 0;
        final status = isVatClaimed ? MatchStatus.vaaDisallowanceRisk : MatchStatus.expenseValidationRisk2026;
        final riskLevel = isVatClaimed ? RiskLevel.critical : RiskLevel.high;

        results.add(ReconciliationMatch(
          matchId: matchId,
          invoiceKey: fullKey,
          status: status,
          riskLevel: riskLevel,
          erpRecord: erp,
          etimsRecord: null,
          itaxRecord: null,
          vatVariance: erp.vatAmount,
          totalVariance: erp.totalAmount,
          claimableVatAtRisk: erp.vatAmount,
          incomeTaxDisallowanceRisk: erp.taxableAmount,
          recommendation: isVatClaimed
              ? 'CRITICAL VAA EXPOSURE: Input VAT of KES ${erp.vatAmount.toStringAsFixed(2)} claimed in books but missing in eTIMS & iTax!'
              : '2026 EXPENSE RISK: Purchase of KES ${erp.taxableAmount.toStringAsFixed(2)} booked without eTIMS QR/Control Code.',
          actionPlan: 'Contact supplier ${erp.supplierName} immediately to demand eTIMS credit/invoice transmission.',
        ));
      }
    }

    // 2. Process remaining eTIMS records unbooked in ERP
    for (var etims in etimsRecords) {
      final fullKey = _makeKey(etims.supplierPin, etims.invoiceNumber, rules);
      if (processedEtims.contains(fullKey)) continue;

      processedEtims.add(fullKey);
      final invKey = _cleanInvoiceNumber(etims.invoiceNumber, rules);
      InvoiceRecord? itax = itaxFullMap[fullKey] ?? itaxInvMap[invKey];
      if (itax != null && processedItax.contains(_makeKey(itax.supplierPin, itax.invoiceNumber, rules))) {
        itax = null;
      }
      if (itax != null) {
        processedItax.add(_makeKey(itax.supplierPin, itax.invoiceNumber, rules));
      }

      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      if (itax != null) {
        final totalDiff = (etims.totalAmount - itax.totalAmount).abs();
        final vatDiff = (etims.vatAmount - itax.vatAmount).abs();

        if (totalDiff <= rules.amountToleranceKes && vatDiff <= rules.amountToleranceKes) {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.matched,
            riskLevel: RiskLevel.safe,
            erpRecord: null,
            etimsRecord: etims,
            itaxRecord: itax,
            vatVariance: 0.0,
            totalVariance: 0.0,
            claimableVatAtRisk: 0.0,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Matched: eTIMS invoice matches iTax return schedule entry (KES ${etims.totalAmount.toStringAsFixed(2)}).',
            actionPlan: 'Record in internal ERP purchase ledger to claim input VAT.',
          ));
        } else {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.amountRateVariance,
            riskLevel: RiskLevel.medium,
            erpRecord: null,
            etimsRecord: etims,
            itaxRecord: itax,
            vatVariance: vatDiff,
            totalVariance: totalDiff,
            claimableVatAtRisk: vatDiff,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Amount variance between eTIMS (KES ${etims.totalAmount.toStringAsFixed(2)}) and iTax schedule (KES ${itax.totalAmount.toStringAsFixed(2)}).',
            actionPlan: 'Verify supplier transmission details.',
          ));
        }
      } else {
        results.add(ReconciliationMatch(
          matchId: matchId,
          invoiceKey: fullKey,
          status: MatchStatus.unmatchedEtimsOnly,
          riskLevel: RiskLevel.medium,
          erpRecord: null,
          etimsRecord: etims,
          itaxRecord: null,
          vatVariance: etims.vatAmount,
          totalVariance: etims.totalAmount,
          claimableVatAtRisk: 0.0,
          incomeTaxDisallowanceRisk: 0.0,
          recommendation: 'eTIMS invoice issued under company PIN ${etims.buyerPin} by supplier ${etims.supplierName} for KES ${etims.totalAmount.toStringAsFixed(2)}, but unbooked in ERP ledger.',
          actionPlan: 'Verify with procurement department if goods/services were received. If valid, record in purchase journal.',
        ));
      }
    }

    // 3. Process remaining iTax records unbooked in ERP and eTIMS
    for (var itax in itaxRecords) {
      final fullKey = _makeKey(itax.supplierPin, itax.invoiceNumber, rules);
      if (processedItax.contains(fullKey)) continue;

      processedItax.add(fullKey);
      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      results.add(ReconciliationMatch(
        matchId: matchId,
        invoiceKey: fullKey,
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
        actionPlan: 'Audit supplier relationship or contest line item on iTax portal.',
      ));
    }

    results.sort((a, b) => b.riskLevel.index.compareTo(a.riskLevel.index));
    return results;
  }

  /// Mode: 2-Way ERP vs iTax Auto-Population
  static List<ReconciliationMatch> _reconcileTwoWayErpItax({
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> itaxRecords,
    required ReconciliationRules rules,
  }) {
    final Map<String, InvoiceRecord> erpFullMap = {};
    final Map<String, InvoiceRecord> erpInvMap = {};
    for (var r in erpRecords) {
      erpFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      erpInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Map<String, InvoiceRecord> itaxFullMap = {};
    final Map<String, InvoiceRecord> itaxInvMap = {};
    for (var r in itaxRecords) {
      itaxFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      itaxInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Set<String> processedErpKeys = {};
    final Set<String> processedItaxKeys = {};
    final List<ReconciliationMatch> results = [];
    int matchIndex = 1;

    for (var erp in erpRecords) {
      final fullKey = _makeKey(erp.supplierPin, erp.invoiceNumber, rules);
      final invKey = _cleanInvoiceNumber(erp.invoiceNumber, rules);
      if (processedErpKeys.contains(fullKey)) continue;

      InvoiceRecord? matchedItax = itaxFullMap[fullKey] ?? itaxInvMap[invKey];
      if (matchedItax != null) {
        final itaxFullKey = _makeKey(matchedItax.supplierPin, matchedItax.invoiceNumber, rules);
        if (processedItaxKeys.contains(itaxFullKey)) {
          matchedItax = null;
        } else {
          processedItaxKeys.add(itaxFullKey);
        }
      }

      processedErpKeys.add(fullKey);
      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      if (matchedItax != null) {
        final totalDiff = (erp.totalAmount - matchedItax.totalAmount).abs();
        final vatDiff = (erp.vatAmount - matchedItax.vatAmount).abs();
        if (totalDiff <= rules.amountToleranceKes && vatDiff <= rules.amountToleranceKes) {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.matched,
            riskLevel: RiskLevel.safe,
            erpRecord: erp,
            itaxRecord: matchedItax,
            vatVariance: 0.0,
            totalVariance: 0.0,
            claimableVatAtRisk: 0.0,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Matched: Internal ERP entry matches iTax auto-population schedule. Cleared for filing.',
            actionPlan: 'Include in VAT return schedule as verified entry.',
          ));
        } else {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.amountRateVariance,
            riskLevel: RiskLevel.medium,
            erpRecord: erp,
            itaxRecord: matchedItax,
            vatVariance: vatDiff,
            totalVariance: totalDiff,
            claimableVatAtRisk: vatDiff,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Amount mismatch between ERP books (KES ${erp.totalAmount.toStringAsFixed(2)}) and iTax auto-population (KES ${matchedItax.totalAmount.toStringAsFixed(2)}).',
            actionPlan: 'Reconcile taxable base with supplier invoice.',
          ));
        }
      } else {
        results.add(ReconciliationMatch(
          matchId: matchId,
          invoiceKey: fullKey,
          status: MatchStatus.unclaimedInputVat,
          riskLevel: RiskLevel.high,
          erpRecord: erp,
          itaxRecord: null,
          vatVariance: erp.vatAmount,
          totalVariance: erp.totalAmount,
          claimableVatAtRisk: erp.vatAmount,
          incomeTaxDisallowanceRisk: 0.0,
          recommendation: 'Invoice in ERP books but missing in iTax auto-population schedule.',
          actionPlan: 'Manually insert row into iTax VAT 7 Section B schedule to claim input VAT credit.',
        ));
      }
    }

    for (var itax in itaxRecords) {
      final fullKey = _makeKey(itax.supplierPin, itax.invoiceNumber, rules);
      if (processedItaxKeys.contains(fullKey)) continue;

      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      results.add(ReconciliationMatch(
        matchId: matchId,
        invoiceKey: fullKey,
        status: MatchStatus.unmatchedItaxOnly,
        riskLevel: RiskLevel.high,
        erpRecord: null,
        itaxRecord: itax,
        vatVariance: itax.vatAmount,
        totalVariance: itax.totalAmount,
        claimableVatAtRisk: 0.0,
        incomeTaxDisallowanceRisk: 0.0,
        recommendation: 'Unrecognized invoice entry auto-populated on iTax schedule without corresponding ERP entry.',
        actionPlan: 'Verify purchase with procurement or dispute entry on KRA portal.',
      ));
    }

    results.sort((a, b) => b.riskLevel.index.compareTo(a.riskLevel.index));
    return results;
  }

  /// Mode: 2-Way eTIMS Device vs iTax Auto-Population
  static List<ReconciliationMatch> _reconcileTwoWayEtimsItax({
    required List<InvoiceRecord> etimsRecords,
    required List<InvoiceRecord> itaxRecords,
    required ReconciliationRules rules,
  }) {
    final Map<String, InvoiceRecord> etimsFullMap = {};
    final Map<String, InvoiceRecord> etimsInvMap = {};
    for (var r in etimsRecords) {
      etimsFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      etimsInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Map<String, InvoiceRecord> itaxFullMap = {};
    final Map<String, InvoiceRecord> itaxInvMap = {};
    for (var r in itaxRecords) {
      itaxFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      itaxInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Set<String> processedEtimsKeys = {};
    final Set<String> processedItaxKeys = {};
    final List<ReconciliationMatch> results = [];
    int matchIndex = 1;

    for (var etims in etimsRecords) {
      final fullKey = _makeKey(etims.supplierPin, etims.invoiceNumber, rules);
      final invKey = _cleanInvoiceNumber(etims.invoiceNumber, rules);
      if (processedEtimsKeys.contains(fullKey)) continue;

      InvoiceRecord? matchedItax = itaxFullMap[fullKey] ?? itaxInvMap[invKey];
      if (matchedItax != null) {
        final itaxFullKey = _makeKey(matchedItax.supplierPin, matchedItax.invoiceNumber, rules);
        if (processedItaxKeys.contains(itaxFullKey)) {
          matchedItax = null;
        } else {
          processedItaxKeys.add(itaxFullKey);
        }
      }

      processedEtimsKeys.add(fullKey);
      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      if (matchedItax != null) {
        final totalDiff = (etims.totalAmount - matchedItax.totalAmount).abs();
        final vatDiff = (etims.vatAmount - matchedItax.vatAmount).abs();
        if (totalDiff <= rules.amountToleranceKes && vatDiff <= rules.amountToleranceKes) {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.matched,
            riskLevel: RiskLevel.safe,
            etimsRecord: etims,
            itaxRecord: matchedItax,
            vatVariance: 0.0,
            totalVariance: 0.0,
            claimableVatAtRisk: 0.0,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Matched: eTIMS/TIMS device transmission matches iTax auto-population schedule.',
            actionPlan: 'Verified KRA transmission.',
          ));
        } else {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.amountRateVariance,
            riskLevel: RiskLevel.medium,
            etimsRecord: etims,
            itaxRecord: matchedItax,
            vatVariance: vatDiff,
            totalVariance: totalDiff,
            claimableVatAtRisk: vatDiff,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Amount mismatch between eTIMS device (KES ${etims.totalAmount.toStringAsFixed(2)}) and iTax schedule (KES ${matchedItax.totalAmount.toStringAsFixed(2)}).',
            actionPlan: 'Check KRA transmission payload for rate or rounding discrepancy.',
          ));
        }
      } else {
        final daysDiff = DateTime.now().difference(etims.invoiceDate).inDays;
        results.add(ReconciliationMatch(
          matchId: matchId,
          invoiceKey: fullKey,
          status: daysDiff <= 7 ? MatchStatus.timingLatency : MatchStatus.unclaimedInputVat,
          riskLevel: daysDiff <= 7 ? RiskLevel.low : RiskLevel.high,
          etimsRecord: etims,
          itaxRecord: null,
          vatVariance: etims.vatAmount,
          totalVariance: etims.totalAmount,
          claimableVatAtRisk: etims.vatAmount,
          incomeTaxDisallowanceRisk: 0.0,
          recommendation: daysDiff <= 7
              ? 'Transmitted on eTIMS device, pending iTax portal batch sync window.'
              : 'Transmitted on eTIMS device but missing in iTax pre-filled schedule.',
          actionPlan: 'Add row manually to iTax schedule using eTIMS Control Code ${etims.etimsControlCode ?? "N/A"}.',
        ));
      }
    }

    for (var itax in itaxRecords) {
      final fullKey = _makeKey(itax.supplierPin, itax.invoiceNumber, rules);
      if (processedItaxKeys.contains(fullKey)) continue;

      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      results.add(ReconciliationMatch(
        matchId: matchId,
        invoiceKey: fullKey,
        status: MatchStatus.unmatchedItaxOnly,
        riskLevel: RiskLevel.high,
        etimsRecord: null,
        itaxRecord: itax,
        vatVariance: itax.vatAmount,
        totalVariance: itax.totalAmount,
        claimableVatAtRisk: 0.0,
        incomeTaxDisallowanceRisk: 0.0,
        recommendation: 'Entry auto-populated on iTax schedule without eTIMS device transmission log.',
        actionPlan: 'Audit supplier PIN or contest line item.',
      ));
    }

    results.sort((a, b) => b.riskLevel.index.compareTo(a.riskLevel.index));
    return results;
  }

  /// Mode: 2-Way ERP vs eTIMS Device Data
  static List<ReconciliationMatch> _reconcileTwoWayErpEtims({
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> etimsRecords,
    required ReconciliationRules rules,
  }) {
    final Map<String, InvoiceRecord> erpFullMap = {};
    final Map<String, InvoiceRecord> erpInvMap = {};
    for (var r in erpRecords) {
      erpFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      erpInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Map<String, InvoiceRecord> etimsFullMap = {};
    final Map<String, InvoiceRecord> etimsInvMap = {};
    for (var r in etimsRecords) {
      etimsFullMap[_makeKey(r.supplierPin, r.invoiceNumber, rules)] = r;
      etimsInvMap[_cleanInvoiceNumber(r.invoiceNumber, rules)] = r;
    }

    final Set<String> processedErpKeys = {};
    final Set<String> processedEtimsKeys = {};
    final List<ReconciliationMatch> results = [];
    int matchIndex = 1;

    for (var erp in erpRecords) {
      final fullKey = _makeKey(erp.supplierPin, erp.invoiceNumber, rules);
      final invKey = _cleanInvoiceNumber(erp.invoiceNumber, rules);
      if (processedErpKeys.contains(fullKey)) continue;

      InvoiceRecord? matchedEtims = etimsFullMap[fullKey] ?? etimsInvMap[invKey];
      if (matchedEtims != null) {
        final etimsFullKey = _makeKey(matchedEtims.supplierPin, matchedEtims.invoiceNumber, rules);
        if (processedEtimsKeys.contains(etimsFullKey)) {
          matchedEtims = null;
        } else {
          processedEtimsKeys.add(etimsFullKey);
        }
      }

      processedErpKeys.add(fullKey);
      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      if (matchedEtims != null) {
        final totalDiff = (erp.totalAmount - matchedEtims.totalAmount).abs();
        final vatDiff = (erp.vatAmount - matchedEtims.vatAmount).abs();
        if (totalDiff <= rules.amountToleranceKes && vatDiff <= rules.amountToleranceKes) {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.matched,
            riskLevel: RiskLevel.safe,
            erpRecord: erp,
            etimsRecord: matchedEtims,
            vatVariance: 0.0,
            totalVariance: 0.0,
            claimableVatAtRisk: 0.0,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Matched: Internal ERP entry matches eTIMS/TIMS device transmission.',
            actionPlan: 'Verified eTIMS invoice.',
          ));
        } else {
          results.add(ReconciliationMatch(
            matchId: matchId,
            invoiceKey: fullKey,
            status: MatchStatus.amountRateVariance,
            riskLevel: RiskLevel.medium,
            erpRecord: erp,
            etimsRecord: matchedEtims,
            vatVariance: vatDiff,
            totalVariance: totalDiff,
            claimableVatAtRisk: vatDiff,
            incomeTaxDisallowanceRisk: 0.0,
            recommendation: 'Amount mismatch between ERP books (KES ${erp.totalAmount.toStringAsFixed(2)}) and eTIMS device transmission (KES ${matchedEtims.totalAmount.toStringAsFixed(2)}).',
            actionPlan: 'Check internal journal against supplier eTIMS invoice copy.',
          ));
        }
      } else {
        final isVatClaimed = erp.vatAmount > 0;
        results.add(ReconciliationMatch(
          matchId: matchId,
          invoiceKey: fullKey,
          status: isVatClaimed ? MatchStatus.vaaDisallowanceRisk : MatchStatus.expenseValidationRisk2026,
          riskLevel: isVatClaimed ? RiskLevel.critical : RiskLevel.high,
          erpRecord: erp,
          etimsRecord: null,
          vatVariance: erp.vatAmount,
          totalVariance: erp.totalAmount,
          claimableVatAtRisk: erp.vatAmount,
          incomeTaxDisallowanceRisk: erp.taxableAmount,
          recommendation: isVatClaimed
              ? 'CRITICAL VAA EXPOSURE: Input VAT of KES ${erp.vatAmount.toStringAsFixed(2)} booked in ERP without eTIMS transmission.'
              : '2026 EXPENSE RISK: Purchase of KES ${erp.taxableAmount.toStringAsFixed(2)} booked without eTIMS QR/Control Code.',
          actionPlan: 'Demand eTIMS invoice from supplier ${erp.supplierName}.',
        ));
      }
    }

    for (var etims in etimsRecords) {
      final fullKey = _makeKey(etims.supplierPin, etims.invoiceNumber, rules);
      if (processedEtimsKeys.contains(fullKey)) continue;

      final matchId = 'MCH-${matchIndex.toString().padLeft(4, '0')}';
      matchIndex++;

      results.add(ReconciliationMatch(
        matchId: matchId,
        invoiceKey: fullKey,
        status: MatchStatus.unmatchedEtimsOnly,
        riskLevel: RiskLevel.medium,
        erpRecord: null,
        etimsRecord: etims,
        vatVariance: etims.vatAmount,
        totalVariance: etims.totalAmount,
        claimableVatAtRisk: 0.0,
        incomeTaxDisallowanceRisk: 0.0,
        recommendation: 'eTIMS invoice issued under company PIN by ${etims.supplierName} but unbooked in ERP ledger.',
        actionPlan: 'Record in purchase journal if valid.',
      ));
    }

    results.sort((a, b) => b.riskLevel.index.compareTo(a.riskLevel.index));
    return results;
  }

  static String _cleanInvoiceNumber(String invoiceNo, ReconciliationRules rules) {
    String cleanInv = invoiceNo.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (rules.ignoreInvoicePrefixes) {
      if (cleanInv.startsWith('INV')) {
        cleanInv = cleanInv.substring(3);
      }
      cleanInv = cleanInv.replaceFirst(RegExp(r'^0+'), '');
    }
    return cleanInv.isEmpty ? invoiceNo.toUpperCase().trim() : cleanInv;
  }

  static String _makeKey(String pin, String invoiceNo, ReconciliationRules rules) {
    String cleanPin = pin.toUpperCase().trim();
    String cleanInv = _cleanInvoiceNumber(invoiceNo, rules);
    if (cleanPin.isEmpty || cleanPin == 'NON-VAT-SUPPLIER' || cleanPin == 'NO-PIN' || cleanPin == 'P000000000A' || cleanPin.contains('NON-VAT')) {
      return cleanInv;
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

  /// Reconciles Import Customs Entries (Section F) against ERP Import Purchase Ledgers
  static List<CustomsMatchResult> reconcileCustoms({
    required List<CustomsEntryRecord> customsEntries,
    required List<InvoiceRecord> erpRecords,
  }) {
    final Map<String, InvoiceRecord> erpImportMap = {};
    for (var r in erpRecords) {
      final cleanInv = r.invoiceNumber.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      erpImportMap[cleanInv] = r;
    }

    final List<CustomsMatchResult> results = [];
    for (var entry in customsEntries) {
      final cleanEntry = entry.entryNumber.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      
      // Match by entry number or invoice number snippet
      InvoiceRecord? matched = erpImportMap[cleanEntry];
      if (matched == null) {
        for (var erp in erpRecords) {
          final cleanErpNo = erp.invoiceNumber.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
          if (cleanErpNo.contains(cleanEntry) || cleanEntry.contains(cleanErpNo)) {
            matched = erp;
            break;
          }
        }
      }

      if (matched != null) {
        final vatDiff = (entry.importVatAmount - matched.vatAmount).abs();
        if (vatDiff <= 5.0) {
          results.add(CustomsMatchResult(
            customsRecord: entry,
            matchedErpRecord: matched,
            status: CustomsMatchStatus.matched,
            vatVariance: 0.0,
            notes: 'Matched: KRA Customs Entry ${entry.entryNumber} matches ERP entry ${matched.invoiceNumber}. Safe for Section F filing.',
          ));
        } else {
          results.add(CustomsMatchResult(
            customsRecord: entry,
            matchedErpRecord: matched,
            status: CustomsMatchStatus.valuationVariance,
            vatVariance: vatDiff,
            notes: 'Valuation Variance: Import VAT on KRA Customs Entry (KES ${entry.importVatAmount.toStringAsFixed(2)}) differs from ERP booked VAT (KES ${matched.vatAmount.toStringAsFixed(2)}).',
          ));
        }
      } else {
        results.add(CustomsMatchResult(
          customsRecord: entry,
          matchedErpRecord: null,
          status: CustomsMatchStatus.unclaimedImportVat,
          vatVariance: entry.importVatAmount,
          notes: 'Unclaimed Import VAT: Valid KRA Customs Entry ${entry.entryNumber} present at ${entry.customsStation} for KES ${entry.importVatAmount.toStringAsFixed(2)} but omitted from ERP ledger.',
        ));
      }
    }
    return results;
  }
}
