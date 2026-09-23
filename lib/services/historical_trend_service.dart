import '../models/invoice_record.dart';

class PeriodVatSummary {
  final String taxPeriod;
  final double erpInputVat;
  final double etimsInputVat;
  final double itaxInputVat;
  final double claimableInputVat;
  final double vaaRiskVat;
  final double whvatCredits;
  final int matchedInvoicesCount;
  final int totalInvoicesCount;

  const PeriodVatSummary({
    required this.taxPeriod,
    required this.erpInputVat,
    required this.etimsInputVat,
    required this.itaxInputVat,
    required this.claimableInputVat,
    required this.vaaRiskVat,
    required this.whvatCredits,
    required this.matchedInvoicesCount,
    required this.totalInvoicesCount,
  });

  double get compliancePercentage =>
      totalInvoicesCount > 0 ? (matchedInvoicesCount / totalInvoicesCount) * 100 : 100.0;
}

class SupplierBehaviorProfile {
  final String supplierPin;
  final String supplierName;
  final int totalOrdersCount;
  final int delayedEtimsCount;
  final int missingEtimsCount;
  final double totalVatAtRisk;
  final double riskScore; // 0 (Safe) to 100 (Critical)

  const SupplierBehaviorProfile({
    required this.supplierPin,
    required this.supplierName,
    required this.totalOrdersCount,
    required this.delayedEtimsCount,
    required this.missingEtimsCount,
    required this.totalVatAtRisk,
    required this.riskScore,
  });

  String get riskTier {
    if (riskScore >= 75) return 'CRITICAL DEFAULTER';
    if (riskScore >= 50) return 'HIGH LATENCY RISK';
    if (riskScore >= 25) return 'MODERATE DELAY';
    return 'COMPLIANT VENDOR';
  }
}

class HistoricalTrendService {
  /// Generates multi-period comparative VAT trend analytics
  static List<PeriodVatSummary> generateMultiPeriodAnalytics({
    required List<InvoiceRecord> allErpRecords,
    required List<InvoiceRecord> allEtimsRecords,
    required List<InvoiceRecord> allItaxRecords,
  }) {
    final Set<String> periods = {};
    for (var r in [...allErpRecords, ...allEtimsRecords, ...allItaxRecords]) {
      if (r.taxPeriod.isNotEmpty) {
        periods.add(r.taxPeriod);
      }
    }

    final sortedPeriods = periods.toList()..sort();
    if (sortedPeriods.isEmpty) {
      sortedPeriods.addAll(['2026-03', '2026-04', '2026-05', '2026-06', '2026-07', '2026-08']);
    }

    final List<PeriodVatSummary> summaries = [];
    for (var period in sortedPeriods) {
      final erpInPeriod = allErpRecords.where((r) => r.taxPeriod == period).toList();
      final etimsInPeriod = allEtimsRecords.where((r) => r.taxPeriod == period).toList();
      final itaxInPeriod = allItaxRecords.where((r) => r.taxPeriod == period).toList();

      final erpSum = erpInPeriod.fold(0.0, (s, r) => s + r.vatAmount);
      final etimsSum = etimsInPeriod.fold(0.0, (s, r) => s + r.vatAmount);
      final itaxSum = itaxInPeriod.fold(0.0, (s, r) => s + r.vatAmount);

      final matchedCount = erpInPeriod.where((r) => etimsInPeriod.any((e) => e.normalizedInvoiceNumber == r.normalizedInvoiceNumber)).length;
      final vaaCount = erpInPeriod.where((r) => !etimsInPeriod.any((e) => e.normalizedInvoiceNumber == r.normalizedInvoiceNumber)).length;

      summaries.add(PeriodVatSummary(
        taxPeriod: period,
        erpInputVat: erpSum,
        etimsInputVat: etimsSum,
        itaxInputVat: itaxSum,
        claimableInputVat: etimsSum < erpSum ? etimsSum : erpSum,
        vaaRiskVat: vaaCount * 16000.0,
        whvatCredits: erpSum * 0.02,
        matchedInvoicesCount: matchedCount,
        totalInvoicesCount: erpInPeriod.isNotEmpty ? erpInPeriod.length : 1,
      ));
    }
    return summaries;
  }

  /// Calculates supplier behavioral risk scores based on transmission delay history
  static List<SupplierBehaviorProfile> calculateSupplierRiskProfiles({
    required List<InvoiceRecord> erpRecords,
    required List<InvoiceRecord> etimsRecords,
  }) {
    final Map<String, List<InvoiceRecord>> erpBySupplier = {};
    final Map<String, String> namesByPin = {};

    for (var r in erpRecords) {
      erpBySupplier.putIfAbsent(r.supplierPin, () => []).add(r);
      namesByPin[r.supplierPin] = r.supplierName;
    }

    final List<SupplierBehaviorProfile> profiles = [];
    for (var entry in erpBySupplier.entries) {
      final pin = entry.key;
      final name = namesByPin[pin] ?? pin;
      final orders = entry.value;

      int missingCount = 0;
      int delayedCount = 0;
      double vatRisk = 0.0;

      for (var erp in orders) {
        final matchingEtims = etimsRecords.where((e) => e.normalizedSupplierPin == erp.normalizedSupplierPin && e.normalizedInvoiceNumber == erp.normalizedInvoiceNumber).firstOrNull;

        if (matchingEtims == null) {
          missingCount++;
          vatRisk += erp.vatAmount;
        } else {
          final delayDays = matchingEtims.invoiceDate.difference(erp.invoiceDate).inDays.abs();
          if (delayDays > 3) {
            delayedCount++;
          }
        }
      }

      final score = ((missingCount * 35.0) + (delayedCount * 15.0)).clamp(0.0, 100.0);
      profiles.add(SupplierBehaviorProfile(
        supplierPin: pin,
        supplierName: name,
        totalOrdersCount: orders.length,
        delayedEtimsCount: delayedCount,
        missingEtimsCount: missingCount,
        totalVatAtRisk: vatRisk,
        riskScore: score,
      ));
    }

    profiles.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return profiles;
  }
}
