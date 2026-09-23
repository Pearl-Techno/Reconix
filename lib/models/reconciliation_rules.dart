class ReconciliationRules {
  final int maxDateDifferenceDays;
  final double amountToleranceKes;
  final bool enableFuzzyInvoiceMatching;
  final bool ignoreInvoicePrefixes;
  final bool requireExactPinMatch;

  const ReconciliationRules({
    this.maxDateDifferenceDays = 7,
    this.amountToleranceKes = 1.0,
    this.enableFuzzyInvoiceMatching = true,
    this.ignoreInvoicePrefixes = true,
    this.requireExactPinMatch = true,
  });

  ReconciliationRules copyWith({
    int? maxDateDifferenceDays,
    double? amountToleranceKes,
    bool? enableFuzzyInvoiceMatching,
    bool? ignoreInvoicePrefixes,
    bool? requireExactPinMatch,
  }) {
    return ReconciliationRules(
      maxDateDifferenceDays: maxDateDifferenceDays ?? this.maxDateDifferenceDays,
      amountToleranceKes: amountToleranceKes ?? this.amountToleranceKes,
      enableFuzzyInvoiceMatching: enableFuzzyInvoiceMatching ?? this.enableFuzzyInvoiceMatching,
      ignoreInvoicePrefixes: ignoreInvoicePrefixes ?? this.ignoreInvoicePrefixes,
      requireExactPinMatch: requireExactPinMatch ?? this.requireExactPinMatch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDateDifferenceDays': maxDateDifferenceDays,
      'amountToleranceKes': amountToleranceKes,
      'enableFuzzyInvoiceMatching': enableFuzzyInvoiceMatching,
      'ignoreInvoicePrefixes': ignoreInvoicePrefixes,
      'requireExactPinMatch': requireExactPinMatch,
    };
  }

  factory ReconciliationRules.fromJson(Map<String, dynamic> json) {
    return ReconciliationRules(
      maxDateDifferenceDays: json['maxDateDifferenceDays'] as int? ?? 7,
      amountToleranceKes: (json['amountToleranceKes'] as num?)?.toDouble() ?? 1.0,
      enableFuzzyInvoiceMatching: json['enableFuzzyInvoiceMatching'] as bool? ?? true,
      ignoreInvoicePrefixes: json['ignoreInvoicePrefixes'] as bool? ?? true,
      requireExactPinMatch: json['requireExactPinMatch'] as bool? ?? true,
    );
  }
}
