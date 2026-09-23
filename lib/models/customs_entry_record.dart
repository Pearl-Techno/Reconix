class CustomsEntryRecord {
  final String id;
  final String entryNumber; // C17 / Entry No. e.g. '2026MSA1094820'
  final String customsStation; // e.g. 'Mombasa Port / ICD Nairobi'
  final String importerPin;
  final String importerName;
  final DateTime declarationDate;
  final String taxPeriod;
  final double taxableValue;
  final double importVatAmount;
  final String? hsCode;
  final bool isMatchedWithErp;

  const CustomsEntryRecord({
    required this.id,
    required this.entryNumber,
    required this.customsStation,
    required this.importerPin,
    required this.importerName,
    required this.declarationDate,
    required this.taxPeriod,
    required this.taxableValue,
    required this.importVatAmount,
    this.hsCode,
    this.isMatchedWithErp = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_number': entryNumber,
      'customs_station': customsStation,
      'importer_pin': importerPin,
      'importer_name': importerName,
      'declaration_date': declarationDate.toIso8601String(),
      'tax_period': taxPeriod,
      'taxable_value': taxableValue,
      'import_vat_amount': importVatAmount,
      'hs_code': hsCode,
      'is_matched_with_erp': isMatchedWithErp ? 1 : 0,
    };
  }

  factory CustomsEntryRecord.fromMap(Map<String, dynamic> map) {
    return CustomsEntryRecord(
      id: map['id'] as String,
      entryNumber: map['entry_number'] as String,
      customsStation: map['customs_station'] as String,
      importerPin: map['importer_pin'] as String,
      importerName: map['importer_name'] as String,
      declarationDate: DateTime.parse(map['declaration_date'] as String),
      taxPeriod: map['tax_period'] as String,
      taxableValue: (map['taxable_value'] as num).toDouble(),
      importVatAmount: (map['import_vat_amount'] as num).toDouble(),
      hsCode: map['hs_code'] as String?,
      isMatchedWithErp: (map['is_matched_with_erp'] as int? ?? 0) == 1,
    );
  }
}
