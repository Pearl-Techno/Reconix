import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/invoice_record.dart';
import '../../services/data_ingestion_service.dart';
import '../../theme/app_theme.dart';

enum PinFilterMode { all, withPin, noPin }

class CsvIngestionSummaryDialog extends StatefulWidget {
  final CsvIngestionResult result;
  final String fileName;
  final VoidCallback onConfirm;

  const CsvIngestionSummaryDialog({
    super.key,
    required this.result,
    required this.fileName,
    required this.onConfirm,
  });

  @override
  State<CsvIngestionSummaryDialog> createState() => _CsvIngestionSummaryDialogState();
}

class _CsvIngestionSummaryDialogState extends State<CsvIngestionSummaryDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _numberFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  String _searchQuery = '';
  PinFilterMode _pinFilter = PinFilterMode.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Container(
        width: 960,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Source Badge & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.mintAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSV Ingestion Diagnostics & Preview',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'File: ${widget.fileName} (${res.sourceType.displayName})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top Metric Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: _statMetricCard(
                    title: 'Total Lines Read',
                    value: '${res.totalLinesRead}',
                    subtext: '${res.successCount} Parsed',
                    icon: LucideIcons.layers,
                    color: AppColors.infoBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statMetricCard(
                    title: 'With KRA PIN',
                    value: '${res.recordsWithPinCount} Invoices',
                    subtext: 'Claimable Input VAT',
                    icon: LucideIcons.shieldCheck,
                    color: AppColors.mintAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statMetricCard(
                    title: 'No-PIN / Non-VAT',
                    value: '${res.recordsNoPinCount} Purchases',
                    subtext: 'Non-VAT Merchant',
                    icon: LucideIcons.alertTriangle,
                    color: AppColors.warningOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statMetricCard(
                    title: 'Errors / Skipped',
                    value: '${res.errorCount} Rows',
                    subtext: '${res.warningCount} Warnings',
                    icon: LucideIcons.alertCircle,
                    color: res.errorCount > 0 ? AppColors.crimsonRisk : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Bar Switcher (Diagnostic Error Log vs Data Preview Table)
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.mintAccent,
                labelColor: AppColors.mintAccent,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.stethoscope, size: 16),
                        const SizedBox(width: 8),
                        Text('Line Diagnostic Log (${res.issues.length} Issues)'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.table, size: 16),
                        const SizedBox(width: 8),
                        Text('Parsed Ingested Data (${res.records.length} Invoices)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Diagnostic Error & Warning Log
                  _buildDiagnosticLogTab(context, res),

                  // Tab 2: Parsed Ingested Records Preview Data Table
                  _buildDataPreviewTab(context, res),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bottom Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  res.errorCount == 0
                      ? '✓ CSV format valid. Ready to commit to 3-Way Reconciliation Engine.'
                      : '⚠️ ${res.errorCount} row(s) contained errors and were skipped.',
                  style: TextStyle(
                    color: res.errorCount == 0 ? AppColors.mintAccent : AppColors.warningOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel Upload'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.check, size: 18),
                      label: Text(
                        'Confirm & Import ${res.records.length} Records',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        widget.onConfirm();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statMetricCard({
    required String title,
    required String value,
    String? subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtext != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtext,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticLogTab(BuildContext context, CsvIngestionResult res) {
    if (res.issues.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.checkCircle2, color: AppColors.mintAccent, size: 48),
            SizedBox(height: 12),
            Text(
              'Zero CSV Diagnostic Errors or Warnings!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'All lines were parsed cleanly according to KRA/ERP schema specifications.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: res.issues.length,
      itemBuilder: (context, idx) {
        final issue = res.issues[idx];
        Color badgeColor;
        IconData badgeIcon;

        switch (issue.severity) {
          case CsvIssueSeverity.error:
            badgeColor = AppColors.crimsonRisk;
            badgeIcon = LucideIcons.alertCircle;
            break;
          case CsvIssueSeverity.warning:
            badgeColor = AppColors.warningOrange;
            badgeIcon = LucideIcons.alertTriangle;
            break;
          case CsvIssueSeverity.info:
            badgeColor = AppColors.infoBlue;
            badgeIcon = LucideIcons.info;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'LINE ${issue.lineNumber}',
                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.description,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (issue.rawLineSnippet.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Raw Snippet: "${issue.rawLineSnippet}"',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Monospace'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataPreviewTab(BuildContext context, CsvIngestionResult res) {
    final filtered = res.records.where((r) {
      if (_pinFilter == PinFilterMode.withPin && !r.hasValidPin) return false;
      if (_pinFilter == PinFilterMode.noPin && !r.isNonVatNoPin) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.invoiceNumber.toLowerCase().contains(q) ||
          r.supplierPin.toLowerCase().contains(q) ||
          r.supplierName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // PIN Filter Choice Chips
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('All Records (${res.records.length})'),
                    selected: _pinFilter == PinFilterMode.all,
                    onSelected: (sel) {
                      if (sel) setState(() => _pinFilter = PinFilterMode.all);
                    },
                    selectedColor: AppColors.mintAccent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _pinFilter == PinFilterMode.all ? AppColors.mintAccent : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ChoiceChip(
                    label: Text('With KRA PIN (${res.recordsWithPinCount})'),
                    selected: _pinFilter == PinFilterMode.withPin,
                    onSelected: (sel) {
                      if (sel) setState(() => _pinFilter = PinFilterMode.withPin);
                    },
                    selectedColor: AppColors.emeraldPrimary.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: _pinFilter == PinFilterMode.withPin ? AppColors.mintAccent : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ChoiceChip(
                    label: Text('No-PIN / Non-VAT (${res.recordsNoPinCount})'),
                    selected: _pinFilter == PinFilterMode.noPin,
                    onSelected: (sel) {
                      if (sel) setState(() => _pinFilter = PinFilterMode.noPin);
                    },
                    selectedColor: AppColors.warningOrange.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _pinFilter == PinFilterMode.noPin ? AppColors.warningOrange : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Search Box
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by Invoice #, Supplier Name or PIN...',
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowColor: WidgetStateProperty.all(AppColors.darkBg),
                columns: const [
                  DataColumn(label: Text('Row #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('PIN Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Invoice Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Supplier PIN & Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Taxable (KES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('VAT (KES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Total (KES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('eTIMS Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: filtered.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final r = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('$idx', style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
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
                      DataCell(Text(_dateFormat.format(r.invoiceDate), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_numberFormat.format(r.taxableAmount), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_numberFormat.format(r.vatAmount), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_numberFormat.format(r.totalAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataCell(
                        Text(
                          r.etimsControlCode ?? '—',
                          style: const TextStyle(fontSize: 10, fontFamily: 'Monospace', color: AppColors.kraGold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
