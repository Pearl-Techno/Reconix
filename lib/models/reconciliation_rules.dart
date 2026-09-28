enum ReconciliationMode {
  threeWay,
  twoWayErpItax,
  twoWayEtimsItax,
  twoWayErpEtims,
  autoDetect,
}

extension ReconciliationModeExtension on ReconciliationMode {
  String get displayName {
    switch (this) {
      case ReconciliationMode.threeWay:
        return 'ERP ↔ eTIMS/TIMS ↔ iTax Auto-Population (3-Way)';
      case ReconciliationMode.twoWayErpItax:
        return 'ERP ↔ iTax Auto-Population (2-Way)';
      case ReconciliationMode.twoWayEtimsItax:
        return 'eTIMS/TIMS Device ↔ iTax Auto-Population (2-Way)';
      case ReconciliationMode.twoWayErpEtims:
        return 'ERP ↔ eTIMS/TIMS Device Data (2-Way)';
      case ReconciliationMode.autoDetect:
        return 'Auto-Detect (Based on Uploaded Datasets)';
    }
  }

  String get shortName {
    switch (this) {
      case ReconciliationMode.threeWay:
        return '3-Way (ERP/eTIMS/iTax)';
      case ReconciliationMode.twoWayErpItax:
        return '2-Way (ERP vs iTax)';
      case ReconciliationMode.twoWayEtimsItax:
        return '2-Way (eTIMS vs iTax)';
      case ReconciliationMode.twoWayErpEtims:
        return '2-Way (ERP vs eTIMS)';
      case ReconciliationMode.autoDetect:
        return 'Auto-Detect';
    }
  }
}

class ReconciliationRules {
  final int maxDateDifferenceDays;
  final double amountToleranceKes;
  final bool enableFuzzyInvoiceMatching;
  final bool ignoreInvoicePrefixes;
  final bool requireExactPinMatch;
  final bool showTaxCategoryColumn;
  final bool showClaimableVatColumn;
  final bool autoCalculate16PercentVat;
  final ReconciliationMode mode;

  const ReconciliationRules({
    this.maxDateDifferenceDays = 7,
    this.amountToleranceKes = 1.0,
    this.enableFuzzyInvoiceMatching = true,
    this.ignoreInvoicePrefixes = true,
    this.requireExactPinMatch = true,
    this.showTaxCategoryColumn = false,
    this.showClaimableVatColumn = false,
    this.autoCalculate16PercentVat = false,
    this.mode = ReconciliationMode.threeWay,
  });

  ReconciliationRules copyWith({
    int? maxDateDifferenceDays,
    double? amountToleranceKes,
    bool? enableFuzzyInvoiceMatching,
    bool? ignoreInvoicePrefixes,
    bool? requireExactPinMatch,
    bool? showTaxCategoryColumn,
    bool? showClaimableVatColumn,
    bool? autoCalculate16PercentVat,
    ReconciliationMode? mode,
  }) {
    return ReconciliationRules(
      maxDateDifferenceDays: maxDateDifferenceDays ?? this.maxDateDifferenceDays,
      amountToleranceKes: amountToleranceKes ?? this.amountToleranceKes,
      enableFuzzyInvoiceMatching: enableFuzzyInvoiceMatching ?? this.enableFuzzyInvoiceMatching,
      ignoreInvoicePrefixes: ignoreInvoicePrefixes ?? this.ignoreInvoicePrefixes,
      requireExactPinMatch: requireExactPinMatch ?? this.requireExactPinMatch,
      showTaxCategoryColumn: showTaxCategoryColumn ?? this.showTaxCategoryColumn,
      showClaimableVatColumn: showClaimableVatColumn ?? this.showClaimableVatColumn,
      autoCalculate16PercentVat: autoCalculate16PercentVat ?? this.autoCalculate16PercentVat,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDateDifferenceDays': maxDateDifferenceDays,
      'amountToleranceKes': amountToleranceKes,
      'enableFuzzyInvoiceMatching': enableFuzzyInvoiceMatching,
      'ignoreInvoicePrefixes': ignoreInvoicePrefixes,
      'requireExactPinMatch': requireExactPinMatch,
      'showTaxCategoryColumn': showTaxCategoryColumn,
      'showClaimableVatColumn': showClaimableVatColumn,
      'autoCalculate16PercentVat': autoCalculate16PercentVat,
      'mode': mode.name,
    };
  }

  factory ReconciliationRules.fromJson(Map<String, dynamic> json) {
    return ReconciliationRules(
      maxDateDifferenceDays: json['maxDateDifferenceDays'] as int? ?? 7,
      amountToleranceKes: (json['amountToleranceKes'] as num?)?.toDouble() ?? 1.0,
      enableFuzzyInvoiceMatching: json['enableFuzzyInvoiceMatching'] as bool? ?? true,
      ignoreInvoicePrefixes: json['ignoreInvoicePrefixes'] as bool? ?? true,
      requireExactPinMatch: json['requireExactPinMatch'] as bool? ?? true,
      showTaxCategoryColumn: json['showTaxCategoryColumn'] as bool? ?? false,
      showClaimableVatColumn: json['showClaimableVatColumn'] as bool? ?? false,
      autoCalculate16PercentVat: json['autoCalculate16PercentVat'] as bool? ?? false,
      mode: json['mode'] != null
          ? ReconciliationMode.values.firstWhere(
              (e) => e.name == json['mode'],
              orElse: () => ReconciliationMode.threeWay,
            )
          : ReconciliationMode.threeWay,
    );
  }
}
