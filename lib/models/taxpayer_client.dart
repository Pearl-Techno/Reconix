class TaxpayerClient {
  final String id;
  final String businessName;
  final String kraPin;
  final String vatRegistrationNo;
  final String sector;
  final String contactEmail;
  final bool isAdvisorClient;
  final String riskStatus; // 'READY_TO_FILE', 'ACTION_REQUIRED', 'HIGH_RISK'
  final String currentTaxPeriod;
  final double totalMonthlyPurchases;
  final double inputVatClaimable;
  final double inputVatAtRisk;
  final int totalInvoicesCount;
  final int matchedInvoicesCount;

  const TaxpayerClient({
    required this.id,
    required this.businessName,
    required this.kraPin,
    required this.vatRegistrationNo,
    required this.sector,
    required this.contactEmail,
    this.isAdvisorClient = true,
    required this.riskStatus,
    required this.currentTaxPeriod,
    required this.totalMonthlyPurchases,
    required this.inputVatClaimable,
    required this.inputVatAtRisk,
    required this.totalInvoicesCount,
    required this.matchedInvoicesCount,
  });

  double get matchPercentage {
    if (totalInvoicesCount == 0) return 0.0;
    return (matchedInvoicesCount / totalInvoicesCount) * 100;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaxpayerClient && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
