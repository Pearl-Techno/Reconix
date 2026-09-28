enum SourceType {
  etims,
  erp,
  itax,
}

enum TaxClassification {
  standard16,
  eightPercent,
  zeroRated,
  exempt,
}

extension TaxClassificationExtension on TaxClassification {
  String get displayName {
    switch (this) {
      case TaxClassification.standard16:
        return 'Standard (16%) [Cat A]';
      case TaxClassification.eightPercent:
        return 'Fuel (8%) [Cat D]';
      case TaxClassification.zeroRated:
        return 'Zero-Rated (0%) [Cat B]';
      case TaxClassification.exempt:
        return 'Exempt [Cat C]';
    }
  }

  String get kraCategoryCode {
    switch (this) {
      case TaxClassification.standard16:
        return 'A';
      case TaxClassification.zeroRated:
        return 'B';
      case TaxClassification.exempt:
        return 'C';
      case TaxClassification.eightPercent:
        return 'D';
    }
  }

  String get statutoryExplanation {
    switch (this) {
      case TaxClassification.standard16:
        return 'Taxable supply at standard 16% VAT rate (Category A). Full input VAT claimable subject to valid eTIMS invoice/QR verification.';
      case TaxClassification.eightPercent:
        return 'Taxable supply at 8% VAT rate (Category D - Fuel/Petroleum products). Input VAT claimable up to 8% rate.';
      case TaxClassification.zeroRated:
        return 'Zero-rated supply at 0% VAT rate (Category B - Second Schedule). Exports, EPZ sales, diplomatic goods. Input VAT on related purchases CAN be claimed.';
      case TaxClassification.exempt:
        return 'Exempt supply (Category C - First Schedule). Financial services, medical items, education, land. Input VAT CANNOT be claimed on related expenses.';
    }
  }
}

extension SourceTypeExtension on SourceType {
  String get displayName {
    switch (this) {
      case SourceType.etims:
        return 'eTIMS / TIMS ETR System';
      case SourceType.erp:
        return 'Internal Books / ERP';
      case SourceType.itax:
        return 'iTax Pre-Filled Schedule';
    }
  }

  String get shortCode {
    switch (this) {
      case SourceType.etims:
        return 'eTIMS/TIMS';
      case SourceType.erp:
        return 'ERP';
      case SourceType.itax:
        return 'iTax';
    }
  }
}

enum InvoiceType {
  standard,
  creditNote,
  debitNote,
}

enum SectionType {
  sectionASales,
  sectionBPurchases,
  sectionCImports,
  sectionDWhvat,
}

extension SectionTypeExtension on SectionType {
  String get displayName {
    switch (this) {
      case SectionType.sectionASales:
        return 'Section A (Output VAT Sales)';
      case SectionType.sectionBPurchases:
        return 'Section B (Input VAT Purchases)';
      case SectionType.sectionCImports:
        return 'Section C (Customs Import VAT)';
      case SectionType.sectionDWhvat:
        return 'Section D (2% Withholding VAT)';
    }
  }
}

class InvoiceRecord {
  final String id;
  final String invoiceNumber;
  final String? etimsControlCode;
  final String? cuSerialNumber;
  final String supplierPin;
  final String supplierName;
  final String buyerPin;
  final String buyerName;
  final DateTime invoiceDate;
  final String taxPeriod; // e.g. '2026-08'
  final double taxableAmount;
  final double vatAmount;
  final double totalAmount;
  final double vatRate; // 0.16, 0.08, 0.0
  final SourceType sourceType;
  final InvoiceType invoiceType;
  final SectionType sectionType;
  final TaxClassification? taxClassification;
  final String? itemDescription;
  final String? costCenter;
  final String? traderSystemInvoiceNumber;
  final DateTime? transmissionDate;
  final String? supplierContactEmail;

  const InvoiceRecord({
    required this.id,
    required this.invoiceNumber,
    this.etimsControlCode,
    this.cuSerialNumber,
    required this.supplierPin,
    required this.supplierName,
    required this.buyerPin,
    required this.buyerName,
    required this.invoiceDate,
    required this.taxPeriod,
    required this.taxableAmount,
    required this.vatAmount,
    required this.totalAmount,
    this.vatRate = 0.16,
    required this.sourceType,
    this.invoiceType = InvoiceType.standard,
    this.sectionType = SectionType.sectionASales,
    this.taxClassification,
    this.itemDescription,
    this.costCenter,
    this.traderSystemInvoiceNumber,
    this.transmissionDate,
    this.supplierContactEmail,
  });

  /// Formatted invoice number cleaned for comparison
  String get normalizedInvoiceNumber {
    return invoiceNumber.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Cleaned PIN for comparison
  String get normalizedSupplierPin {
    return supplierPin.toUpperCase().trim();
  }

  /// Whether the purchase has a valid VAT-registered KRA PIN
  bool get hasValidPin {
    final cleanPin = normalizedSupplierPin;
    return cleanPin.isNotEmpty &&
        cleanPin != 'NON-VAT-SUPPLIER' &&
        cleanPin != 'NO-PIN' &&
        cleanPin != 'P000000000A' &&
        !cleanPin.contains('NON-VAT');
  }

  /// Whether the purchase is a non-VAT / no-PIN merchant purchase
  bool get isNonVatNoPin => !hasValidPin;

  /// Whether the invoice possesses a transmitted eTIMS control code
  bool get hasEtimsVerification {
    return etimsControlCode != null && etimsControlCode!.trim().isNotEmpty;
  }

  /// Signed taxable amount (negative for credit notes)
  double get signedTaxableAmount => invoiceType == InvoiceType.creditNote ? -taxableAmount.abs() : taxableAmount.abs();

  /// Signed VAT amount (negative for credit notes)
  double get signedVatAmount => invoiceType == InvoiceType.creditNote ? -vatAmount.abs() : vatAmount.abs();

  /// Signed total amount (negative for credit notes)
  double get signedTotalAmount => invoiceType == InvoiceType.creditNote ? -totalAmount.abs() : totalAmount.abs();

  /// Statutory KRA tax classification (Standard 16%, Fuel 8%, Zero-Rated 0%, Exempt)
  TaxClassification get effectiveTaxClassification {
    if (taxClassification != null) return taxClassification!;

    final desc = (itemDescription ?? '').toUpperCase();
    if (desc.contains('EXEMPT') || desc.contains('CAT C') || desc.contains('CATEGORY C') || desc.contains('FIRST SCHEDULE')) {
      return TaxClassification.exempt;
    }
    if (desc.contains('ZERO') || desc.contains('0%') || desc.contains('EXPORT') || desc.contains('EPZ') || desc.contains('CAT B') || desc.contains('CATEGORY B') || desc.contains('SECOND SCHEDULE')) {
      return TaxClassification.zeroRated;
    }

    if ((vatRate - 0.08).abs() < 0.01) {
      return TaxClassification.eightPercent;
    }
    if ((vatRate - 0.16).abs() < 0.01 || vatAmount > 0) {
      return TaxClassification.standard16;
    }

    if (vatAmount == 0 && taxableAmount > 0) {
      return TaxClassification.zeroRated;
    }

    return TaxClassification.exempt;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'etimsControlCode': etimsControlCode,
      'cuSerialNumber': cuSerialNumber,
      'supplierPin': supplierPin,
      'supplierName': supplierName,
      'buyerPin': buyerPin,
      'buyerName': buyerName,
      'invoiceDate': invoiceDate.toIso8601String(),
      'taxPeriod': taxPeriod,
      'taxableAmount': taxableAmount,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'vatRate': vatRate,
      'sourceType': sourceType.name,
      'invoiceType': invoiceType.name,
      'sectionType': sectionType.name,
      'taxClassification': taxClassification?.name,
      'itemDescription': itemDescription,
      'costCenter': costCenter,
      'traderSystemInvoiceNumber': traderSystemInvoiceNumber,
      'transmissionDate': transmissionDate?.toIso8601String(),
      'supplierContactEmail': supplierContactEmail,
    };
  }

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    return InvoiceRecord(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'],
      etimsControlCode: json['etimsControlCode'],
      cuSerialNumber: json['cuSerialNumber'],
      supplierPin: json['supplierPin'],
      supplierName: json['supplierName'],
      buyerPin: json['buyerPin'],
      buyerName: json['buyerName'],
      invoiceDate: DateTime.parse(json['invoiceDate']),
      taxPeriod: json['taxPeriod'],
      taxableAmount: (json['taxableAmount'] as num).toDouble(),
      vatAmount: (json['vatAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0.16,
      sourceType: SourceType.values.firstWhere((e) => e.name == json['sourceType']),
      invoiceType: InvoiceType.values.firstWhere((e) => e.name == json['invoiceType']),
      sectionType: SectionType.values.firstWhere(
        (e) => e.name == json['sectionType'],
        orElse: () => SectionType.sectionASales,
      ),
      taxClassification: json['taxClassification'] != null
          ? TaxClassification.values.firstWhere((e) => e.name == json['taxClassification'])
          : null,
      itemDescription: json['itemDescription'],
      costCenter: json['costCenter'],
      traderSystemInvoiceNumber: json['traderSystemInvoiceNumber'],
      transmissionDate: json['transmissionDate'] != null ? DateTime.parse(json['transmissionDate']) : null,
      supplierContactEmail: json['supplierContactEmail'],
    );
  }
}
