import '../models/invoice_record.dart';
import '../models/whvat_record.dart';
import '../models/customs_entry_record.dart';
import '../models/taxpayer_client.dart';

class ITaxFilingBundle {
  final String sectionACsv;
  final String sectionBCsv;
  final String sectionCCsv;
  final String sectionDCsv;
  final String taxPeriod;
  final String taxpayerPin;

  const ITaxFilingBundle({
    required this.sectionACsv,
    required this.sectionBCsv,
    required this.sectionCCsv,
    required this.sectionDCsv,
    required this.taxPeriod,
    required this.taxpayerPin,
  });
}

class ITaxFilingBundleService {
  /// Generates sanitized 4-in-1 CSV upload bundle formatted for KRA iTax Form VAT 7
  static ITaxFilingBundle generateFilingBundle({
    required TaxpayerClient client,
    required String taxPeriod,
    required List<InvoiceRecord> salesRecords,
    required List<InvoiceRecord> purchaseRecords,
    required List<CustomsEntryRecord> customsEntries,
    required List<WhvatRecord> whvatRecords,
  }) {
    // 1. Section A (Sales)
    final sectionA = StringBuffer();
    sectionA.writeln('Customer KRA PIN,Customer Name,Invoice Number,Invoice Date,Taxable Value (KES),VAT Amount (KES),Total Invoice Amount (KES),eTIMS Control Code');
    for (var s in salesRecords) {
      final dateStr = '${s.invoiceDate.day.toString().padLeft(2, '0')}/${s.invoiceDate.month.toString().padLeft(2, '0')}/${s.invoiceDate.year}';
      sectionA.writeln('${s.buyerPin},"${s.buyerName}",${s.invoiceNumber},$dateStr,${s.taxableAmount.toStringAsFixed(2)},${s.vatAmount.toStringAsFixed(2)},${s.totalAmount.toStringAsFixed(2)},${s.etimsControlCode ?? ""}');
    }

    // 2. Section B (Purchases)
    final sectionB = StringBuffer();
    sectionB.writeln('Supplier KRA PIN,Supplier Name,Invoice Number,Invoice Date,Description,Taxable Value (KES),VAT Amount (KES),Total Invoice Amount (KES),eTIMS Control Code');
    for (var p in purchaseRecords) {
      final dateStr = '${p.invoiceDate.day.toString().padLeft(2, '0')}/${p.invoiceDate.month.toString().padLeft(2, '0')}/${p.invoiceDate.year}';
      final suppPin = p.hasValidPin ? p.supplierPin : '';
      sectionB.writeln('$suppPin,"${p.supplierName}",${p.invoiceNumber},$dateStr,"${p.itemDescription ?? "General Goods"}",${p.taxableAmount.toStringAsFixed(2)},${p.vatAmount.toStringAsFixed(2)},${p.totalAmount.toStringAsFixed(2)},${p.etimsControlCode ?? ""}');
    }

    // 3. Section C (Imports)
    final sectionC = StringBuffer();
    sectionC.writeln('Customs C17 Entry Number,Customs Station,Importer PIN,Importer Name,Declaration Date,Taxable Value (KES),Import VAT Paid (KES),HS Code');
    for (var c in customsEntries) {
      final dateStr = '${c.declarationDate.day.toString().padLeft(2, '0')}/${c.declarationDate.month.toString().padLeft(2, '0')}/${c.declarationDate.year}';
      sectionC.writeln('${c.entryNumber},"${c.customsStation}",${c.importerPin},"${c.importerName}",$dateStr,${c.taxableValue.toStringAsFixed(2)},${c.importVatAmount.toStringAsFixed(2)},${c.hsCode ?? ""}');
    }

    // 4. Section D (WHVAT 2%)
    final sectionD = StringBuffer();
    sectionD.writeln('WHVAT Certificate Number,Withholding Agent PIN,Agent Name,Certificate Date,Gross Amount (KES),2% WHVAT Credit (KES),Invoice Number');
    for (var w in whvatRecords) {
      final dateStr = '${w.certificateDate.day.toString().padLeft(2, '0')}/${w.certificateDate.month.toString().padLeft(2, '0')}/${w.certificateDate.year}';
      sectionD.writeln('${w.certificateNumber},${w.buyerPin},"${w.buyerName}",$dateStr,${w.grossInvoiceAmount.toStringAsFixed(2)},${w.whvatAmount.toStringAsFixed(2)},${w.invoiceNumber}');
    }

    return ITaxFilingBundle(
      sectionACsv: sectionA.toString(),
      sectionBCsv: sectionB.toString(),
      sectionCCsv: sectionC.toString(),
      sectionDCsv: sectionD.toString(),
      taxPeriod: taxPeriod,
      taxpayerPin: client.kraPin,
    );
  }
}
