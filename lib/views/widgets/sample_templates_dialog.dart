import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/sample_template_service.dart';
import '../../theme/app_theme.dart';

class SampleTemplatesDialog extends StatefulWidget {
  const SampleTemplatesDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SampleTemplatesDialog(),
    );
  }

  @override
  State<SampleTemplatesDialog> createState() => _SampleTemplatesDialogState();
}

class _SampleTemplatesDialogState extends State<SampleTemplatesDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Container(
        width: 860,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.kraGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.kraGold, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sample Ingestion CSV Templates & Specifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Preview sample file formats and download pre-filled CSV templates for your data imports.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 8),

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.kraGold,
              labelColor: AppColors.kraGold,
              unselectedLabelColor: AppColors.textMuted,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(LucideIcons.qrCode, size: 15), text: '1. eTIMS Export'),
                Tab(icon: Icon(LucideIcons.bookOpen, size: 15), text: '2. ERP Purchase Ledger'),
                Tab(icon: Icon(LucideIcons.fileText, size: 15), text: '3. iTax Section B'),
                Tab(icon: Icon(LucideIcons.shieldCheck, size: 15), text: '4. WHVAT 2% Certificates'),
                Tab(icon: Icon(LucideIcons.ship, size: 15), text: '5. Customs C17 Imports'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTemplateView(
                    title: 'eTIMS / TIMS ETR Export CSV Template',
                    description: 'Used for ingesting electronic tax invoice transmissions downloaded from eTIMS web portal or ETR device dumps.',
                    csvContent: SampleTemplateService.etimsSampleCsv,
                    fileName: 'etims_sample_template.csv',
                    requiredColumns: ['Invoice Number', 'Supplier Name', 'Supplier PIN', 'Invoice Date', 'Taxable Amount', 'VAT Amount', 'eTIMS Control Code'],
                  ),
                  _buildTemplateView(
                    title: 'ERP Purchase Ledger CSV Template (QuickBooks / SAP / Tally / Sage)',
                    description: 'Used for importing internal accounting books. Invoices missing eTIMS control codes will be flagged as VAA disallowance risks.',
                    csvContent: SampleTemplateService.erpSampleCsv,
                    fileName: 'erp_purchase_ledger_sample.csv',
                    requiredColumns: ['Invoice Number', 'Supplier Name', 'Supplier PIN', 'Invoice Date', 'Taxable Amount', 'VAT Amount'],
                  ),
                  _buildTemplateView(
                    title: 'iTax Section B Pre-Filled Input VAT Schedule CSV Template',
                    description: 'Auto-populated input VAT return schedule downloaded directly from KRA iTax portal.',
                    csvContent: SampleTemplateService.itaxSampleCsv,
                    fileName: 'itax_section_b_sample.csv',
                    requiredColumns: ['Supplier PIN', 'Supplier Name', 'Invoice Number', 'Invoice Date', 'Taxable Value (KES)', 'Amount of VAT (KES)'],
                  ),
                  _buildTemplateView(
                    title: '2% Withholding VAT (WHVAT) Certificate Schedule CSV Template',
                    description: 'Schedule of 2% WHVAT certificates issued by appointed withholding agents to claim against sales VAT payable.',
                    csvContent: SampleTemplateService.whvatSampleCsv,
                    fileName: 'whvat_2percent_sample.csv',
                    requiredColumns: ['Certificate Number', 'Withholding Agent Name', 'Agent KRA PIN', 'Tax Period', 'WHVAT Deducted 2% (KES)'],
                  ),
                  _buildTemplateView(
                    title: 'Customs Import C17 Entry Ledger CSV Template (SIMBA / ICMS)',
                    description: 'Customs C17 import entries from Mombasa Port / JKIA Airport for Section C input VAT claims.',
                    csvContent: SampleTemplateService.customsSampleCsv,
                    fileName: 'customs_c17_import_sample.csv',
                    requiredColumns: ['Entry Number', 'Customs Office', 'Declarant PIN', 'Importer Name', 'CIF Value KES', 'Import VAT 16% KES'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateView({
    required String title,
    required String description,
    required String csvContent,
    required String fileName,
    required List<String> requiredColumns,
  }) {
    final lines = csvContent.trim().split('\n');
    final headers = lines[0].split(',');
    final dataRows = lines.sublist(1).map((l) => l.split(',')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => SampleTemplateService.exportSampleTemplate(context, csvContent, fileName),
              icon: const Icon(LucideIcons.download, size: 15),
              label: Text('Download $fileName'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Required Columns Badges
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            const Text('Mandatory Headers:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.kraGold)),
            ...requiredColumns.map((col) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(col, style: const TextStyle(fontSize: 10, color: AppColors.mintAccent)),
              );
            }),
          ],
        ),
        const SizedBox(height: 14),

        // Preview Table
        const Text('Sample Row Preview:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.darkCard),
                  columns: headers.map((h) {
                    return DataColumn(
                      label: Text(
                        h,
                        style: const TextStyle(color: AppColors.mintAccent, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    );
                  }).toList(),
                  rows: dataRows.map((row) {
                    return DataRow(
                      cells: row.map((cell) {
                        return DataCell(
                          Text(cell, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Monospace')),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Raw CSV Preview Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.darkBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Raw CSV Content:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  Text('UTF-8 Encoded CSV', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                csvContent,
                style: const TextStyle(fontFamily: 'Monospace', fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
