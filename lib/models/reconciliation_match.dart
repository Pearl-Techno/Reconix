import 'invoice_record.dart';

enum MatchStatus {
  matched,
  timingLatency,
  unclaimedInputVat,
  vaaDisallowanceRisk,
  expenseValidationRisk2026,
  amountRateVariance,
  unmatchedEtimsOnly,
  unmatchedItaxOnly,
}

extension MatchStatusExtension on MatchStatus {
  String get title {
    switch (this) {
      case MatchStatus.matched:
        return 'Fully Matched (3-Way Verified)';
      case MatchStatus.timingLatency:
        return 'Systemic Timing Latency';
      case MatchStatus.unclaimedInputVat:
        return 'Unclaimed Input VAT Risk';
      case MatchStatus.vaaDisallowanceRisk:
        return 'VAA Disallowance Exposure';
      case MatchStatus.expenseValidationRisk2026:
        return '2026 Expense Deductibility Risk';
      case MatchStatus.amountRateVariance:
        return 'Amount / Tax Rate Variance';
      case MatchStatus.unmatchedEtimsOnly:
        return 'eTIMS Record Missing in ERP';
      case MatchStatus.unmatchedItaxOnly:
        return 'Unrecognized iTax Schedule Entry';
    }
  }

  String get shortTag {
    switch (this) {
      case MatchStatus.matched:
        return 'MATCHED';
      case MatchStatus.timingLatency:
        return 'TIMING DELAY';
      case MatchStatus.unclaimedInputVat:
        return 'UNCLAIMED VAT';
      case MatchStatus.vaaDisallowanceRisk:
        return 'VAA RISK';
      case MatchStatus.expenseValidationRisk2026:
        return '2026 EXPENSE RISK';
      case MatchStatus.amountRateVariance:
        return 'VARIANCE';
      case MatchStatus.unmatchedEtimsOnly:
        return 'eTIMS ONLY';
      case MatchStatus.unmatchedItaxOnly:
        return 'iTAX ONLY';
    }
  }

  String get description {
    switch (this) {
      case MatchStatus.matched:
        return 'Invoice numbers, PINs, taxable amounts, and VAT amounts match perfectly across eTIMS, ERP, and iTax.';
      case MatchStatus.timingLatency:
        return 'Valid eTIMS invoice present in internal ERP, but auto-population on iTax is delayed due to KRA batch processing queue.';
      case MatchStatus.unclaimedInputVat:
        return 'Legitimate eTIMS invoice exists in ERP but is omitted from the pre-filled iTax return. Taxpayer risks losing claimable input VAT.';
      case MatchStatus.vaaDisallowanceRisk:
        return 'Input VAT claimed in internal books but missing or invalidated on eTIMS. Triggers automated KRA VAA disallowance notices.';
      case MatchStatus.expenseValidationRisk2026:
        return 'Supplier invoice booked in ERP without an eTIMS QR/Control Code. Under Section 16(1) 2026 rules, income tax deduction will be rejected.';
      case MatchStatus.amountRateVariance:
        return 'Mismatch detected in invoice total, taxable base, or applied VAT rate (16% vs 8% vs Exempt).';
      case MatchStatus.unmatchedEtimsOnly:
        return 'Invoice transmitted via eTIMS under taxpayer PIN but omitted from internal ERP purchase ledger.';
      case MatchStatus.unmatchedItaxOnly:
        return 'Entry auto-populated on iTax schedule that has no corresponding purchase record in internal ERP.';
    }
  }
}

enum RiskLevel {
  safe,
  low,
  medium,
  high,
  critical,
}

class ReconciliationMatch {
  final String matchId;
  final String invoiceKey; // Normalized Invoice Number or PIN+No
  final MatchStatus status;
  final RiskLevel riskLevel;
  final InvoiceRecord? erpRecord;
  final InvoiceRecord? etimsRecord;
  final InvoiceRecord? itaxRecord;
  
  final double vatVariance;
  final double totalVariance;
  final double claimableVatAtRisk;
  final double incomeTaxDisallowanceRisk;

  final String recommendation;
  final String actionPlan;
  
  // User resolution state
  final String? userNote;
  final String? resolutionTag; // e.g. 'Pending Supplier eTIMS', 'Approved for Manual Claim', 'Timing Verified'
  final bool isResolved;
  final DateTime? resolvedAt;

  const ReconciliationMatch({
    required this.matchId,
    required this.invoiceKey,
    required this.status,
    required this.riskLevel,
    this.erpRecord,
    this.etimsRecord,
    this.itaxRecord,
    required this.vatVariance,
    required this.totalVariance,
    required this.claimableVatAtRisk,
    required this.incomeTaxDisallowanceRisk,
    required this.recommendation,
    required this.actionPlan,
    this.userNote,
    this.resolutionTag,
    this.isResolved = false,
    this.resolvedAt,
  });

  /// Helper getter for displaying primary invoice number
  String get invoiceNumber {
    return erpRecord?.invoiceNumber ??
        etimsRecord?.invoiceNumber ??
        itaxRecord?.invoiceNumber ??
        'N/A';
  }

  /// Helper getter for primary supplier name
  String get supplierName {
    return erpRecord?.supplierName ??
        etimsRecord?.supplierName ??
        itaxRecord?.supplierName ??
        'Unknown Supplier';
  }

  /// Helper getter for primary supplier PIN
  String get supplierPin {
    return erpRecord?.supplierPin ??
        etimsRecord?.supplierPin ??
        itaxRecord?.supplierPin ??
        'N/A';
  }

  /// Helper getter for primary invoice date
  DateTime get invoiceDate {
    return erpRecord?.invoiceDate ??
        etimsRecord?.invoiceDate ??
        itaxRecord?.invoiceDate ??
        DateTime.now();
  }

  /// Helper getter for primary total amount
  double get primaryTotal {
    return erpRecord?.totalAmount ??
        etimsRecord?.totalAmount ??
        itaxRecord?.totalAmount ??
        0.0;
  }

  /// Helper getter for primary VAT amount
  double get primaryVat {
    return erpRecord?.vatAmount ??
        etimsRecord?.vatAmount ??
        itaxRecord?.vatAmount ??
        0.0;
  }

  ReconciliationMatch copyWith({
    String? userNote,
    String? resolutionTag,
    bool? isResolved,
    DateTime? resolvedAt,
  }) {
    return ReconciliationMatch(
      matchId: matchId,
      invoiceKey: invoiceKey,
      status: status,
      riskLevel: riskLevel,
      erpRecord: erpRecord,
      etimsRecord: etimsRecord,
      itaxRecord: itaxRecord,
      vatVariance: vatVariance,
      totalVariance: totalVariance,
      claimableVatAtRisk: claimableVatAtRisk,
      incomeTaxDisallowanceRisk: incomeTaxDisallowanceRisk,
      recommendation: recommendation,
      actionPlan: actionPlan,
      userNote: userNote ?? this.userNote,
      resolutionTag: resolutionTag ?? this.resolutionTag,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
