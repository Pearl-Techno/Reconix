import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SampleTemplateService {
  static const String etimsSampleCsv = '''Invoice Number,Supplier Name,Supplier PIN,Invoice Date,Taxable Amount,VAT Amount,Total Amount,eTIMS Control Code,CU Serial Number
ET-2026-9812,Safaricom PLC,P051111222A,15/08/2026,50000.00,8000.00,58000.00,KRA202608150019283,KRA0100998822
ET-2026-9815,Kenya Power & Lighting Co,P051222333B,18/08/2026,120000.00,19200.00,139200.00,KRA202608180048172,KRA0100998823
ET-2026-9820,TotalEnergies Marketing Kenya,P051444555D,20/08/2026,200000.00,16000.00,216000.00,KRA202608200099182,KRA0100998824''';

  static const String erpPurchaseWithPinCsv = '''Invoice Number,Supplier Name,Supplier PIN,Invoice Date,Taxable Amount,VAT Amount,Total Amount,eTIMS Control Code
PUR-2026-0042,Crown Paints Kenya PLC,P051123456Z,15/08/2026,100000.00,16000.00,116000.00,KRA-ETIMS-2026-99120
PUR-2026-0043,Bamburi Cement PLC,P051333444C,16/08/2026,300000.00,48000.00,348000.00,KRA-ETIMS-2026-99121
PUR-2026-0044,Car & General Trading,P051555666E,20/08/2026,75000.00,12000.00,87000.00,''';

  static const String erpPurchaseNoPinCsv = '''Invoice Number,Supplier Name,Supplier PIN,Invoice Date,Taxable Amount,VAT Amount,Total Amount,eTIMS Control Code
PUR-2026-0045,General Merchant Market,NON-VAT-SUPPLIER,21/08/2026,15000.00,0.00,15000.00,
PUR-2026-0046,Local Cash Petty Expense,NO-PIN,22/08/2026,8500.00,0.00,8500.00,''';

  static const String erpSalesWithPinCsv = '''Invoice Number,Customer Name,Customer PIN,Invoice Date,Taxable Amount,VAT Amount,Total Amount,eTIMS Control Code
SALES-2026-0101,Bamburi Cement PLC,P051333444C,15/08/2026,150000.00,24000.00,174000.00,KRA-ETIMS-2026-0019283
SALES-2026-0102,KCB Bank Kenya Ltd,P051199888Z,18/08/2026,500000.00,80000.00,580000.00,KRA-ETIMS-2026-0019284''';

  static const String erpSalesNoPinCsv = '''Invoice Number,Customer Name,Customer PIN,Invoice Date,Taxable Amount,VAT Amount,Total Amount,eTIMS Control Code
SALES-2026-0103,Walk-in Cash Customer,NO-PIN,20/08/2026,25000.00,4000.00,29000.00,KRA-ETIMS-2026-0019285
SALES-2026-0104,General Counter Sale,B2C-CONSUMER,22/08/2026,10000.00,1600.00,11600.00,KRA-ETIMS-2026-0019286''';

  static const String itaxSampleCsv = '''P051208794R,Eastleigh Pharmaceutical Company Limited,KRACU0200119725,21/02/2026,|KRACU0200119725/274,ETIMS/TIMS sales,72000.00
P052365461I,W & S PHARMACEUTICAL LIMITED,KRACU0200119725,23/02/2026,|KRACU0200119725/276,ETIMS/TIMS sales,15300.00
P051137812R,Nila Pharmaceuticals Limited,KRACU0200119725,23/02/2026,|KRACU0200119725/277,ETIMS/TIMS sales,60000.00
P051690651G,NORTHERN PHARMACY LIMITED,KRACU0200119725,24/02/2026,|KRACU0200119725/278,ETIMS/TIMS sales,15000.00
P051143300C,SAICARE ENTERPRISES LIMITED,KRACU0200119725,24/02/2026,|KRACU0200119725/280,ETIMS/TIMS sales,900000.00
,,KRACU0200119725,24/02/2026,|KRACU0200119725/282,ETIMS/TIMS sales,3200.00
P051133059T,RANGECHEM PHARMACEUTICALS LIMITED,KRACU0200119725,02/03/2026,|KRACU0200119725/287,ETIMS/TIMS sales,75000.00
P051692927L,LIFEMED PHARMACY LTD,KRACU0200119725,07/03/2026,|KRACU0200119725/292,ETIMS/TIMS sales,13975.00''';

  static const String whvatSampleCsv = '''Certificate Number,Withholding Agent Name,Agent KRA PIN,Certificate Date,Tax Period,Gross Amount (KES),WHVAT Deducted 2% (KES),Invoice Number
WHT-2026-09128,KCB Bank Kenya Ltd,P051199888Z,18/08/2026,2026-08,500000.00,10000.00,INV-2026-8801
WHT-2026-09129,Equity Bank Kenya PLC,P051199889Y,22/08/2026,2026-08,750000.00,15000.00,INV-2026-8802''';

  static const String customsSampleCsv = '''Entry Number,Customs Office,Declarant PIN,Importer Name,Entry Date,CIF Value KES,Customs Duty KES,Import VAT 16% KES,C17 Release Date
2026MBA091284,Mombasa Port,P051888777X,Apex Logistics Ltd,12/08/2026,2500000.00,625000.00,500000.00,14/08/2026
2026NBO041928,JKIA Airport,P051888777X,Apex Logistics Ltd,19/08/2026,1200000.00,300000.00,240000.00,20/08/2026''';

  /// Saves the template string to disk via file picker or default folder
  static Future<void> exportSampleTemplate(BuildContext context, String csvContent, String defaultFileName) async {
    try {
      final String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Sample CSV Template',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (selectedPath != null) {
        final file = File(selectedPath);
        await file.writeAsString(csvContent);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved sample CSV template to: $selectedPath'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting template: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
