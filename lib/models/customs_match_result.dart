import 'customs_entry_record.dart';
import 'invoice_record.dart';

enum CustomsMatchStatus {
  matched,
  unclaimedImportVat,
  valuationVariance,
  missingInBooks,
}

extension CustomsMatchStatusExtension on CustomsMatchStatus {
  String get displayName {
    switch (this) {
      case CustomsMatchStatus.matched:
        return 'MATCHED (SIMBA / ERP)';
      case CustomsMatchStatus.unclaimedImportVat:
        return 'UNCLAIMED IMPORT VAT';
      case CustomsMatchStatus.valuationVariance:
        return 'VALUATION / VAT VARIANCE';
      case CustomsMatchStatus.missingInBooks:
        return 'MISSING IN ERP BOOKS';
    }
  }
}

class CustomsMatchResult {
  final CustomsEntryRecord customsRecord;
  final InvoiceRecord? matchedErpRecord;
  final CustomsMatchStatus status;
  final double vatVariance;
  final String notes;

  const CustomsMatchResult({
    required this.customsRecord,
    this.matchedErpRecord,
    required this.status,
    this.vatVariance = 0.0,
    required this.notes,
  });

  bool get isMatched => status == CustomsMatchStatus.matched;
}
