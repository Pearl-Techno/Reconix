class ReconciliationCertificate {
  final String certificateId;
  final String sha256Hash;
  final String taxpayerName;
  final String kraPin;
  final String taxPeriod;
  final DateTime generatedAt;
  final int totalErpRecordsCount;
  final int totalEtimsRecordsCount;
  final int totalItaxRecordsCount;
  
  final int fullyMatchedCount;
  final int timingLatencyCount;
  final int unclaimedInputVatCount;
  final int vaaDisallowanceCount;
  final int expenseValidationRiskCount;

  final double totalPurchasesErp;
  final double totalInputVatClaimable;
  final double totalInputVatDisallowedExposure;
  final double total2026ExpenseDeductibilityRisk;
  
  final String signedByAdvisor;

  const ReconciliationCertificate({
    required this.certificateId,
    required this.sha256Hash,
    required this.taxpayerName,
    required this.kraPin,
    required this.taxPeriod,
    required this.generatedAt,
    required this.totalErpRecordsCount,
    required this.totalEtimsRecordsCount,
    required this.totalItaxRecordsCount,
    required this.fullyMatchedCount,
    required this.timingLatencyCount,
    required this.unclaimedInputVatCount,
    required this.vaaDisallowanceCount,
    required this.expenseValidationRiskCount,
    required this.totalPurchasesErp,
    required this.totalInputVatClaimable,
    required this.totalInputVatDisallowedExposure,
    required this.total2026ExpenseDeductibilityRisk,
    required this.signedByAdvisor,
  });
}
