import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/reconciliation_match.dart';
import '../theme/app_theme.dart';
import 'widgets/invoice_detail_dialog.dart';

class ReconciliationView extends StatelessWidget {
  const ReconciliationView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final matches = state.filteredMatches;
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title & Quick Export
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3-Way VAT Reconciliation Ledger', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time comparative ledger comparing ERP purchase entries ↔ eTIMS & TIMS ETR invoices ↔ iTax pre-filled schedules',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kraGold,
                      side: const BorderSide(color: AppColors.kraGold),
                    ),
                    icon: const Icon(LucideIcons.download, size: 16),
                    label: const Text('Export iTax Section B CSV'),
                    onPressed: () => state.exportITaxSectionBCsv(),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mintAccent,
                      side: const BorderSide(color: AppColors.mintAccent),
                    ),
                    icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                    label: const Text('Export Audit Ledger Excel (.xlsx)'),
                    onPressed: () {
                      state.exportAuditLedgerExcel();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Multi-tab Excel (.xlsx) Audit Ledger exported!'),
                          backgroundColor: AppColors.emeraldPrimary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldPrimary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Re-Run Matching Engine'),
                    onPressed: () {
                      state.runReconciliation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('3-Way Reconciliation matching engine executed!'),
                          backgroundColor: AppColors.emeraldPrimary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bulk Action Bar Widget (visible when items are selected)
          if (state.selectedMatchIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.emeraldDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.mintAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.checkSquare, color: AppColors.mintAccent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${state.selectedMatchIds.length} Invoice(s) Selected for Practitioner Action',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mintAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(LucideIcons.checkCircle2, size: 14),
                        label: const Text('Tag VERIFIED FOR ITAX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          state.bulkApplyTag('VERIFIED_FOR_ITAX');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bulk resolution tag applied!')),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.crimsonRisk,
                          side: const BorderSide(color: AppColors.crimsonRisk),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(LucideIcons.alertCircle, size: 14),
                        label: const Text('Tag DEMAND ETIMS CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          state.bulkApplyTag('DEMAND_ETIMS_CODE');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Supplier follow-up tag applied!')),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => state.clearSelection(),
                        child: const Text('Clear Selection', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Search & Filter Toolbar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Search Box
                      Expanded(
                        child: TextField(
                          onChanged: (val) => state.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search by Invoice #, Supplier Name, or KRA PIN...',
                            prefixIcon: const Icon(LucideIcons.search, size: 18),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Reset Filters Button
                      OutlinedButton.icon(
                        icon: const Icon(LucideIcons.filterX, size: 16),
                        label: const Text('Clear Filters'),
                        onPressed: () => state.resetFilters(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Match Status Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Status Filter: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                        _filterChip(
                          context,
                          label: 'All (${state.reconciliationResults.length})',
                          isSelected: state.selectedStatusFilter == null,
                          onSelected: () => state.setStatusFilter(null),
                        ),
                        _filterChip(
                          context,
                          label: 'Matched',
                          isSelected: state.selectedStatusFilter == MatchStatus.matched,
                          color: AppColors.mintAccent,
                          onSelected: () => state.setStatusFilter(MatchStatus.matched),
                        ),
                        _filterChip(
                          context,
                          label: 'Timing Latency (${state.timingLatencyCount})',
                          isSelected: state.selectedStatusFilter == MatchStatus.timingLatency,
                          color: AppColors.infoBlue,
                          onSelected: () => state.setStatusFilter(MatchStatus.timingLatency),
                        ),
                        _filterChip(
                          context,
                          label: 'Unclaimed VAT (${state.unclaimedVatCount})',
                          isSelected: state.selectedStatusFilter == MatchStatus.unclaimedInputVat,
                          color: AppColors.warningOrange,
                          onSelected: () => state.setStatusFilter(MatchStatus.unclaimedInputVat),
                        ),
                        _filterChip(
                          context,
                          label: 'VAA Risk (${state.vaaRiskCount})',
                          isSelected: state.selectedStatusFilter == MatchStatus.vaaDisallowanceRisk,
                          color: AppColors.crimsonRisk,
                          onSelected: () => state.setStatusFilter(MatchStatus.vaaDisallowanceRisk),
                        ),
                        _filterChip(
                          context,
                          label: '2026 Exp Risk',
                          isSelected: state.selectedStatusFilter == MatchStatus.expenseValidationRisk2026,
                          color: AppColors.kraGold,
                          onSelected: () => state.setStatusFilter(MatchStatus.expenseValidationRisk2026),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Main 3-Way Comparative Grid Table
          Expanded(
            child: Card(
              child: matches.isEmpty
                  ? const Center(
                      child: Text('No invoice matches found matching active search filters.'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width > 1200 ? MediaQuery.of(context).size.width - 280 : 1200,
                          child: PaginatedDataTable(
                            rowsPerPage: matches.length > 50 ? 50 : (matches.isEmpty ? 1 : matches.length),
                            availableRowsPerPage: const [10, 25, 50, 100, 250],
                            columnSpacing: 20,
                            horizontalMargin: 16,
                            headingRowColor: WidgetStateProperty.all(AppColors.darkBg),
                            columns: const [
                              DataColumn(label: Text('ID & Risk', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Invoice # & Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Supplier Name & PIN', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('3-Way Source Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('ERP Total (KES)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('eTIMS/TIMS Total (KES)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('iTax Total (KES)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Claimable VAT', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Auditor Tag', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            source: ReconciliationDataTableSource(
                              matches: matches,
                              state: state,
                              dateFormat: dateFormat,
                              numberFormat: numberFormat,
                              context: context,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    Color color = AppColors.mintAccent,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : AppColors.textPrimary, fontWeight: FontWeight.bold)),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: AppColors.darkBg,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class ReconciliationDataTableSource extends DataTableSource {
  final List<ReconciliationMatch> matches;
  final AppState state;
  final DateFormat dateFormat;
  final NumberFormat numberFormat;
  final BuildContext context;

  ReconciliationDataTableSource({
    required this.matches,
    required this.state,
    required this.dateFormat,
    required this.numberFormat,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= matches.length) return null;
    final m = matches[index];
    final statusColor = AppTheme.getStatusColor(m.status);
    final riskColor = AppTheme.getRiskColor(m.riskLevel);
    final isSelected = state.selectedMatchIds.contains(m.matchId);

    return DataRow.byIndex(
      index: index,
      selected: isSelected,
      onSelectChanged: (_) => state.toggleSelectMatch(m.matchId),
      cells: [
        // Match ID & Risk Badge
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.matchId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(m.riskLevel.name.toUpperCase(), style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        // Invoice # & Date
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
              Text(dateFormat.format(m.invoiceDate), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
        // Supplier Name & PIN
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.supplierName, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              Text(m.supplierPin, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'Monospace')),
            ],
          ),
        ),
        // 3-Way Source Badges
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(m.status.shortTag, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _sourceDot('ERP', m.erpRecord != null),
                  const SizedBox(width: 4),
                  _sourceDot('eTIMS/TIMS', m.etimsRecord != null),
                  const SizedBox(width: 4),
                  _sourceDot('iTax', m.itaxRecord != null),
                ],
              ),
            ],
          ),
        ),
        // Amounts
        DataCell(Text(m.erpRecord != null ? numberFormat.format(m.erpRecord!.totalAmount) : '—', style: const TextStyle(fontSize: 12))),
        DataCell(Text(m.etimsRecord != null ? numberFormat.format(m.etimsRecord!.totalAmount) : '—', style: const TextStyle(fontSize: 12))),
        DataCell(Text(m.itaxRecord != null ? numberFormat.format(m.itaxRecord!.totalAmount) : '—', style: const TextStyle(fontSize: 12))),
        DataCell(
          Text(
            'KES ${numberFormat.format(m.primaryVat)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: m.status == MatchStatus.matched ? AppColors.mintAccent : AppColors.warningOrange,
            ),
          ),
        ),
        // Auditor Tag
        DataCell(
          m.resolutionTag != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.emeraldPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(m.resolutionTag!, style: const TextStyle(color: AppColors.mintAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              : const Text('Unassigned', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ),
        // Action Button
        DataCell(
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal, color: AppColors.mintAccent, size: 18),
            tooltip: 'Inspect & Resolve Discrepancy',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => InvoiceDetailDialog(match: m),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sourceDot(String label, bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isPresent ? AppColors.mintAccent.withValues(alpha: 0.2) : AppColors.darkBg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: isPresent ? AppColors.mintAccent : AppColors.textMuted, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: isPresent ? AppColors.mintAccent : AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => matches.length;

  @override
  int get selectedRowCount => state.selectedMatchIds.length;
}
