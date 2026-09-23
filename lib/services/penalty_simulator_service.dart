class PenaltySimulationResult {
  final double netTaxPayable;
  final double vaaDisallowanceRiskPool;
  final int daysOverdue;
  final double lateFilingPenalty;
  final double latePaymentInterest;
  final double vaaDisallowancePenalty;
  final double totalStatutoryExposure;
  final List<String> breakdownNotes;

  PenaltySimulationResult({
    required this.netTaxPayable,
    required this.vaaDisallowanceRiskPool,
    required this.daysOverdue,
    required this.lateFilingPenalty,
    required this.latePaymentInterest,
    required this.vaaDisallowancePenalty,
    required this.totalStatutoryExposure,
    required this.breakdownNotes,
  });
}

class PenaltySimulatorService {
  /// Calculates statutory KRA penalties and interest exposure under the Tax Procedures Act (TPA)
  static PenaltySimulationResult calculatePenaltyExposure({
    required double netTaxPayable,
    required double vaaDisallowanceRiskPool,
    required DateTime returnDeadline,
    required DateTime filingDate,
  }) {
    final difference = filingDate.difference(returnDeadline).inDays;
    final daysOverdue = difference > 0 ? difference : 0;
    final monthsOverdue = (daysOverdue / 30.0).ceil();

    double lateFilingPenalty = 0.0;
    double latePaymentInterest = 0.0;
    double vaaDisallowancePenalty = 0.0;
    final List<String> notes = [];

    // 1. Late Filing Penalty (Sec 83 TPA): 5% of tax payable or KES 10,000 minimum if tax is due
    if (daysOverdue > 0) {
      if (netTaxPayable > 0) {
        final calcPenalty = netTaxPayable * 0.05;
        lateFilingPenalty = calcPenalty > 10000.0 ? calcPenalty : 10000.0;
        notes.add('TPA Sec 83: Late filing penalty of 5% on KES ${netTaxPayable.toStringAsFixed(2)} (Min KES 10,000) = KES ${lateFilingPenalty.toStringAsFixed(2)}');
      } else {
        lateFilingPenalty = 10000.0;
        notes.add('TPA Sec 83: Minimum KES 10,000 late filing penalty applied for filing after 20th deadline.');
      }

      // 2. Late Payment Interest (Sec 38 TPA): 1% simple interest per month on net tax payable
      if (netTaxPayable > 0 && monthsOverdue > 0) {
        latePaymentInterest = netTaxPayable * (0.01 * monthsOverdue);
        notes.add('TPA Sec 38: Late payment interest of 1% per month ($monthsOverdue month(s)) = KES ${latePaymentInterest.toStringAsFixed(2)}');
      }
    } else {
      notes.add('Return filed within statutory deadline (20th of the month). Zero late filing penalties apply.');
    }

    // 3. VAA Disallowance Penalty (Sec 84 TPA): 20% penalty on disallowed input VAT claimed without eTIMS control code
    if (vaaDisallowanceRiskPool > 0) {
      vaaDisallowancePenalty = vaaDisallowanceRiskPool * 0.20;
      notes.add('TPA Sec 84: 20% statutory penalty threat on KES ${vaaDisallowanceRiskPool.toStringAsFixed(2)} VAA disallowance risk pool = KES ${vaaDisallowancePenalty.toStringAsFixed(2)}');
    } else {
      notes.add('Zero VAA disallowance threat detected. All claimed input VAT is 100% eTIMS verified.');
    }

    final totalExposure = netTaxPayable + vaaDisallowanceRiskPool + lateFilingPenalty + latePaymentInterest + vaaDisallowancePenalty;

    return PenaltySimulationResult(
      netTaxPayable: netTaxPayable,
      vaaDisallowanceRiskPool: vaaDisallowanceRiskPool,
      daysOverdue: daysOverdue,
      lateFilingPenalty: lateFilingPenalty,
      latePaymentInterest: latePaymentInterest,
      vaaDisallowancePenalty: vaaDisallowancePenalty,
      totalStatutoryExposure: totalExposure,
      breakdownNotes: notes,
    );
  }
}
