class WhvatRecord {
  final String id;
  final String certificateNumber;
  final String supplierPin;
  final String supplierName;
  final String buyerPin;
  final String buyerName;
  final DateTime certificateDate;
  final String taxPeriod;
  final double grossInvoiceAmount;
  final double whvatAmount; // 2% of taxable/gross amount
  final String invoiceNumber;
  final bool isClaimedOnItax;

  const WhvatRecord({
    required this.id,
    required this.certificateNumber,
    required this.supplierPin,
    required this.supplierName,
    required this.buyerPin,
    required this.buyerName,
    required this.certificateDate,
    required this.taxPeriod,
    required this.grossInvoiceAmount,
    required this.whvatAmount,
    required this.invoiceNumber,
    this.isClaimedOnItax = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'certificate_number': certificateNumber,
      'supplier_pin': supplierPin,
      'supplier_name': supplierName,
      'buyer_pin': buyerPin,
      'buyer_name': buyerName,
      'certificate_date': certificateDate.toIso8601String(),
      'tax_period': taxPeriod,
      'gross_invoice_amount': grossInvoiceAmount,
      'whvat_amount': whvatAmount,
      'invoice_number': invoiceNumber,
      'is_claimed_on_itax': isClaimedOnItax ? 1 : 0,
    };
  }

  factory WhvatRecord.fromMap(Map<String, dynamic> map) {
    return WhvatRecord(
      id: map['id'] as String,
      certificateNumber: map['certificate_number'] as String,
      supplierPin: map['supplier_pin'] as String,
      supplierName: map['supplier_name'] as String,
      buyerPin: map['buyer_pin'] as String,
      buyerName: map['buyer_name'] as String,
      certificateDate: DateTime.parse(map['certificate_date'] as String),
      taxPeriod: map['tax_period'] as String,
      grossInvoiceAmount: (map['gross_invoice_amount'] as num).toDouble(),
      whvatAmount: (map['whvat_amount'] as num).toDouble(),
      invoiceNumber: map['invoice_number'] as String,
      isClaimedOnItax: (map['is_claimed_on_itax'] as int) == 1,
    );
  }
}
