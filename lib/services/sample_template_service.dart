import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SampleTemplateService {
  static const String etimsSampleCsv = '''Invoice Number,Supplier Name,Supplier PIN,Invoice Date,Taxable Amount,VAT Amount,Total Amount,eTIMS Control Code,CU Serial Number
ET-2026-9812,Safaricom PLC,P051111222A,15/08/2026,50000.00,8000.00,58000.00,KRA202608150019283,KRA0100998822
ET-2026-9815,Kenya Power & Lighting Co,P051222333B,18/08/2026,120000.00,19200.00,139200.00,KRA202608180048172,KRA0100998823
ET-2026-9820,TotalEnergies Marketing Kenya,P051444555D,20/08/2026,200000.00,16000.00,216000.00,KRA202608200099182,KRA0100998824''';

  static const String erpSampleCsv = '''Invoice Number,Supplier Name,Supplier PIN,Invoice Date,Taxable Amount,VAT Amount,Total Amount,eTIMS Control Code
PUR-2026-0042,Crown Paints Kenya PLC,P051123456Z,15/08/2026,100000.00,16000.00,116000.00,KRA-ETIMS-2026-99120
PUR-2026-0043,Bamburi Cement PLC,P051333444C,16/08/2026,300000.00,48000.00,348000.00,KRA-ETIMS-2026-99121
PUR-2026-0044,Car & General Trading,P051555666E,20/08/2026,75000.00,12000.00,87000.00,''';

  static const String itaxSampleCsv = '''Supplier PIN,Supplier Name,Invoice Number,Invoice Date,Taxable Value (KES),Amount of VAT (KES),eTIMS CU Serial No
P051111222A,Safaricom PLC,ET-2026-9812,15/08/2026,50000.00,8000.00,KRA0100998822
P051222333B,Kenya Power & Lighting Co,ET-2026-9815,18/08/2026,120000.00,19200.00,KRA0100998823
P051444555D,TotalEnergies Marketing Kenya,ET-2026-9820,20/08/2026,200000.00,16000.00,KRA0100998824''';

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
