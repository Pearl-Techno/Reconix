import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/invoice_record.dart';
import '../services/data_ingestion_service.dart';
import '../services/demo_data_generator.dart';
import '../theme/app_theme.dart';
import 'widgets/csv_ingestion_summary_dialog.dart';
import 'widgets/erp_integration_guide_dialog.dart';
import 'widgets/sample_templates_dialog.dart';

class IngestionView extends StatefulWidget {
  const IngestionView({super.key});

  @override
  State<IngestionView> createState() => _IngestionViewState();
}

class _IngestionViewState extends State<IngestionView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _numberFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  String _searchQuery = '';
  String _pinFilter = 'ALL'; // 'ALL', 'WITH_PIN', 'NO_PIN'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Multi-Source Data Ingestion Hub', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Ingest data from eTIMS exports, internal accounting books (ERP/POS), and iTax pre-filled VAT schedules.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kraGold,
                  side: const BorderSide(color: AppColors.kraGold),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                label: const Text('Sample CSV Templates', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => SampleTemplatesDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3 Source Upload Cards Row
          Row(
            children: [
              Expanded(
                child: _buildUploadCard(
                  context,
                  title: '1. eTIMS / TIMS ETR Export',
                  description: 'Upload CSV/Excel containing ETR CU S/N, eTIMS QR Control Code, Supplier PIN, and VAT amounts.',
                  icon: LucideIcons.qrCode,
                  sourceType: SourceType.etims,
                  count: state.etimsRecords.length,
                  color: AppColors.mintAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUploadCard(
                  context,
                  title: '2. ERP / Internal Books',
                  description: 'Upload Purchase Ledger CSV from QuickBooks, SAP, Sage, Tally, or custom POS.',
                  icon: LucideIcons.bookOpen,
                  sourceType: SourceType.erp,
                  count: state.erpRecords.length,
                  color: AppColors.infoBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUploadCard(
                  context,
                  title: '3. iTax Schedule CSV',
                  description: 'Upload auto-populated pre-filled Section B input VAT schedule downloaded from iTax.',
                  icon: LucideIcons.fileSpreadsheet,
                  sourceType: SourceType.itax,
                  count: state.itaxRecords.length,
                  color: AppColors.kraGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Interactive Ingested Source Data Tables Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.mintAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.table, color: AppColors.mintAccent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ingested Dataset Tables', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 2),
                              const Text(
                                'View line-by-line ingested records across eTIMS/TIMS, ERP, and iTax schedules',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Search box for ingested table
                      SizedBox(
                        width: 320,
                        height: 36,
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search by Invoice #, PIN or Vendor...',
                            prefixIcon: const Icon(LucideIcons.search, size: 16),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Source Tab Controller
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.mintAccent,
                    labelColor: AppColors.mintAccent,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: [
                      Tab(text: 'eTIMS / TIMS Records (${state.etimsRecords.length})'),
                      Tab(text: 'ERP Ledger (${state.erpRecords.length})'),
                      Tab(text: 'iTax Schedule (${state.itaxRecords.length})'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 340,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDataTableForSource(state.etimsRecords),
                        _buildDataTableForSource(state.erpRecords),
                        _buildDataTableForSource(state.itaxRecords),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Pre-Configured Demo Datasets Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.sparkles, color: AppColors.mintAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pre-Loaded Realistic Kenyan Datasets', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 2),
                          const Text(
                            'Instantly test the 3-way matching engine with real Kenyan VAT market scenarios',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildScenarioCard(
                          context,
                          title: 'Scenario 1: Apex Logistics Ltd',
                          badge: 'Mid-Month & eTIMS Latency',
                          badgeColor: AppColors.infoBlue,
                          description: '14 Invoices covering Safaricom, KPLC, Fuel (8%), Crown Paints timing delay & Bamburi Cement unclaimed VAT.',
                          onSelect: () {
                            state.loadDemoScenario(DemoDataGenerator.generateApexLogistics());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Loaded Apex Logistics Kenya Ltd dataset!'),
                                backgroundColor: AppColors.emeraldPrimary,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildScenarioCard(
                          context,
                          title: 'Scenario 2: Nairobi Retailers',
                          badge: 'High VAA Exposure Risk',
                          badgeColor: AppColors.crimsonRisk,
                          description: '32 Invoices with KES 624,500 disallowance risk, missing supplier PINs & 2026 expense deduction threats.',
                          onSelect: () {
                            state.selectClient(DemoDataGenerator.getAdvisorClients()[1]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Loaded Nairobi Commercial Retailers dataset!'),
                                backgroundColor: AppColors.warningOrange,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildScenarioCard(
                          context,
                          title: 'Scenario 3: Rift Valley Agri',
                          badge: 'Clean Matched Baseline',
                          badgeColor: AppColors.mintAccent,
                          description: '22 Invoices with 100% perfect 3-way match, zero-rated exports, and zero VAA penalty exposure.',
                          onSelect: () {
                            state.selectClient(DemoDataGenerator.getAdvisorClients()[2]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Loaded Rift Valley Agriculture Exporters dataset!'),
                                backgroundColor: AppColors.mintAccent,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTableForSource(List<InvoiceRecord> records) {
    final filtered = records.where((r) {
      if (_pinFilter == 'WITH_PIN' && !r.hasValidPin) return false;
      if (_pinFilter == 'NO_PIN' && !r.isNonVatNoPin) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.invoiceNumber.toLowerCase().contains(q) ||
          r.supplierPin.toLowerCase().contains(q) ||
          r.supplierName.toLowerCase().contains(q);
    }).toList();

    final withPinCount = records.where((r) => r.hasValidPin).length;
    final noPinCount = records.where((r) => r.isNonVatNoPin).length;

    if (records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, color: AppColors.textMuted, size: 36),
            SizedBox(height: 8),
            Text('No records ingested for this source yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sub-Filter Chips Row for PIN vs No-PIN
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('All (${records.length})'),
                    selected: _pinFilter == 'ALL',
                    onSelected: (sel) {
                      if (sel) setState(() => _pinFilter = 'ALL');
                    },
                    selectedColor: AppColors.mintAccent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _pinFilter == 'ALL' ? AppColors.mintAccent : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ChoiceChip(
                    label: Text('With KRA PIN ($withPinCount)'),
                    selected: _pinFilter == 'WITH_PIN',
                    onSelected: (sel) {
                      if (sel) setState(() => _pinFilter = 'WITH_PIN');
                    },
                    selectedColor: AppColors.emeraldPrimary.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: _pinFilter == 'WITH_PIN' ? AppColors.mintAccent : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ChoiceChip(
                    label: Text('No-PIN / Non-VAT ($noPinCount)'),
                    selected: _pinFilter == 'NO_PIN',
                    onSelected: (sel) {
                      if (sel) setState(() => _pinFilter = 'NO_PIN');
                    },
                    selectedColor: AppColors.warningOrange.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _pinFilter == 'NO_PIN' ? AppColors.warningOrange : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Showing ${filtered.length} of ${records.length} records',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1100,
                child: PaginatedDataTable(
                  rowsPerPage: filtered.length > 5 ? 5 : (filtered.isEmpty ? 1 : filtered.length),
                  availableRowsPerPage: const [5, 10, 25, 50, 100],
                  columnSpacing: 18,
                  headingRowColor: WidgetStateProperty.all(AppColors.darkBg),
                  columns: const [
                    DataColumn(label: Text('Row #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('PIN Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Invoice Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Supplier Name & PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Taxable (KES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('VAT (KES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Total (KES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('eTIMS Code / CU S/N', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  source: InvoiceDataTableSource(
                    records: filtered,
                    dateFormat: _dateFormat,
                    numberFormat: _numberFormat,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required SourceType sourceType,
    required int count,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count Records Ingested',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBg,
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(LucideIcons.uploadCloud, size: 18),
              label: Text('Upload ${sourceType.shortCode} File (CSV / Excel)'),
              onPressed: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['csv', 'txt', 'xlsx', 'xls', 'CSV', 'TXT', 'XLSX', 'XLS'],
                    withData: true,
                  );

                  if (result != null && result.files.isNotEmpty) {
                    final pickedFile = result.files.first;
                    final fileName = pickedFile.name;
                    List<int>? bytes = pickedFile.bytes;
                    if (bytes == null && pickedFile.path != null) {
                      bytes = await File(pickedFile.path!).readAsBytes();
                    }

                    if (!context.mounted) return;

                    if (bytes != null && bytes.isNotEmpty) {
                      final state = context.read<AppState>();
                      state.setIsIngesting(true);

                      final diagResult = await DataIngestionService.parseAnyFileAsync(
                        filePath: fileName,
                        bytes: bytes,
                        sourceType: sourceType,
                        defaultTaxPeriod: '2026-08',
                      );

                      state.setIsIngesting(false);

                      if (!context.mounted) return;

                      // Show CsvIngestionSummaryDialog with diagnostic errors & parsed preview data table
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => CsvIngestionSummaryDialog(
                          result: diagResult,
                          fileName: fileName,
                          onConfirm: () async {
                            final state = context.read<AppState>();
                            await state.addLiveInvoices(records: diagResult.records, sourceType: sourceType);
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Successfully ingested ${diagResult.records.length} ${sourceType.shortCode} records!'),
                                backgroundColor: AppColors.emeraldPrimary,
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to read selected CSV file. The file may be empty or unreadable.'),
                          backgroundColor: AppColors.crimsonRisk,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error selecting file: $e'),
                      backgroundColor: AppColors.crimsonRisk,
                    ),
                  );
                }
              },
            ),
            if (sourceType == SourceType.erp) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => ErpIntegrationGuideDialog.show(context),
                  icon: const Icon(LucideIcons.plug, size: 14, color: AppColors.infoBlue),
                  label: const Text(
                    'ERP Export Instructions & API Guide',
                    style: TextStyle(fontSize: 11, color: AppColors.infoBlue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context, {
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required VoidCallback onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 38),
            ),
            icon: const Icon(LucideIcons.play, size: 14),
            label: const Text('Load Scenario', style: TextStyle(fontSize: 12)),
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}

class InvoiceDataTableSource extends DataTableSource {
  final List<InvoiceRecord> records;
  final DateFormat dateFormat;
  final NumberFormat numberFormat;

  InvoiceDataTableSource({
    required this.records,
    required this.dateFormat,
    required this.numberFormat,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= records.length) return null;
    final r = records[index];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: r.hasValidPin ? AppColors.emeraldPrimary.withValues(alpha: 0.2) : AppColors.warningOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: r.hasValidPin ? AppColors.mintAccent.withValues(alpha: 0.4) : AppColors.warningOrange.withValues(alpha: 0.4)),
            ),
            child: Text(
              r.hasValidPin ? 'WITH PIN' : 'NO-PIN / NON-VAT',
              style: TextStyle(
                color: r.hasValidPin ? AppColors.mintAccent : AppColors.warningOrange,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(Text(r.invoiceNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(r.supplierName, style: const TextStyle(fontSize: 11)),
              Text(r.supplierPin, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontFamily: 'Monospace')),
            ],
          ),
        ),
        DataCell(Text(dateFormat.format(r.invoiceDate), style: const TextStyle(fontSize: 11))),
        DataCell(Text(numberFormat.format(r.taxableAmount), style: const TextStyle(fontSize: 11))),
        DataCell(Text(numberFormat.format(r.vatAmount), style: const TextStyle(fontSize: 11))),
        DataCell(Text(numberFormat.format(r.totalAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        DataCell(
          Text(
            r.etimsControlCode ?? r.cuSerialNumber ?? '—',
            style: const TextStyle(fontSize: 10, fontFamily: 'Monospace', color: AppColors.kraGold),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => records.length;

  @override
  int get selectedRowCount => 0;
}
