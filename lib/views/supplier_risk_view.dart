import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/invoice_record.dart';
import '../models/reconciliation_match.dart';
import '../models/taxpayer_client.dart';
import '../services/vaa_demand_notice_service.dart';
import '../services/supplier_chaser_service.dart';
import '../theme/app_theme.dart';

class SupplierRiskProfile {
  final String supplierPin;
  final String supplierName;
  final int totalInvoices;
  final int unfiledInvoicesCount;
  final double unfiledTaxableAmount;
  final double unfiledVatAmount;
  final List<InvoiceRecord> unfiledRecords;

  SupplierRiskProfile({
    required this.supplierPin,
    required this.supplierName,
    required this.totalInvoices,
    required this.unfiledInvoicesCount,
    required this.unfiledTaxableAmount,
    required this.unfiledVatAmount,
    required this.unfiledRecords,
  });

  double get complianceRate => totalInvoices > 0 ? ((totalInvoices - unfiledInvoicesCount) / totalInvoices) * 100 : 100.0;

  RiskLevel get riskLevel {
    if (unfiledVatAmount > 50000) return RiskLevel.critical;
    if (unfiledVatAmount > 0) return RiskLevel.high;
    if (unfiledInvoicesCount > 0) return RiskLevel.medium;
    return RiskLevel.safe;
  }
}

class SupplierRiskView extends StatefulWidget {
  final List<ReconciliationMatch> matches;
  final String currentTaxPeriod;

  const SupplierRiskView({
    super.key,
    required this.matches,
    this.currentTaxPeriod = '2026-08',
  });

  @override
  State<SupplierRiskView> createState() => _SupplierRiskViewState();
}

class _SupplierRiskViewState extends State<SupplierRiskView> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  List<SupplierRiskProfile> get _supplierProfiles {
    final Map<String, List<InvoiceRecord>> unfiledBySupplier = {};
    final Map<String, int> totalBySupplier = {};
    final Map<String, String> nameByPin = {};

    for (var m in widget.matches) {
      final erp = m.erpRecord;
      final etims = m.etimsRecord;
      final pin = erp?.supplierPin ?? etims?.supplierPin ?? 'UNKNOWN-PIN';
      final name = erp?.supplierName ?? etims?.supplierName ?? 'Unknown Supplier';

      nameByPin[pin] = name;
      totalBySupplier[pin] = (totalBySupplier[pin] ?? 0) + 1;

      // Unfiled/disallowed invoice condition
      if (m.status == MatchStatus.vaaDisallowanceRisk ||
          m.status == MatchStatus.expenseValidationRisk2026 ||
          m.status == MatchStatus.unclaimedInputVat) {
        if (erp != null) {
          unfiledBySupplier.putIfAbsent(pin, () => []).add(erp);
        }
      }
    }

    final List<SupplierRiskProfile> profiles = [];
    for (var entry in totalBySupplier.entries) {
      final pin = entry.key;
      final name = nameByPin[pin] ?? pin;
      final unfiled = unfiledBySupplier[pin] ?? [];

      final double taxableSum = unfiled.fold(0.0, (s, r) => s + r.taxableAmount);
      final double vatSum = unfiled.fold(0.0, (s, r) => s + r.vatAmount);

      profiles.add(SupplierRiskProfile(
        supplierPin: pin,
        supplierName: name,
        totalInvoices: entry.value,
        unfiledInvoicesCount: unfiled.length,
        unfiledTaxableAmount: taxableSum,
        unfiledVatAmount: vatSum,
        unfiledRecords: unfiled,
      ));
    }

    profiles.sort((a, b) => b.unfiledVatAmount.compareTo(a.unfiledVatAmount));
    return profiles;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final profiles = _supplierProfiles;

    final filtered = profiles.where((p) {
      final matchesSearch = p.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.supplierPin.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilter == 'High Risk') {
        return p.riskLevel == RiskLevel.critical || p.riskLevel == RiskLevel.high;
      } else if (_selectedFilter == 'Compliant') {
        return p.riskLevel == RiskLevel.safe;
      }
      return true;
    }).toList();

    final totalHighRisk = profiles.where((p) => p.riskLevel == RiskLevel.critical || p.riskLevel == RiskLevel.high).length;
    final totalVatExposure = profiles.fold(0.0, (sum, p) => sum + p.unfiledVatAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supplier eTIMS & TIMS Compliance Scorecard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor vendor compliance, identify VAA exposure, and issue automated Demand Notices.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.emeraldDark.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(LucideIcons.shieldCheck, color: AppColors.emeraldDark, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'KRA Tax Act Sec 16 Active',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.emeraldDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Metrics Header Cards
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    width: (constraints.maxWidth - 48) / 4,
                    title: 'Total Vendors Audited',
                    value: profiles.length.toString(),
                    icon: LucideIcons.users,
                    iconColor: Colors.blue,
                  ),
                  _buildMetricCard(
                    width: (constraints.maxWidth - 48) / 4,
                    title: 'High Risk Vendors',
                    value: totalHighRisk.toString(),
                    icon: LucideIcons.alertTriangle,
                    iconColor: Colors.red,
                  ),
                  _buildMetricCard(
                    width: (constraints.maxWidth - 48) / 4,
                    title: 'Total Input VAT Exposure',
                    value: 'KES ${currencyFormat.format(totalVatExposure)}',
                    icon: LucideIcons.dollarSign,
                    iconColor: Colors.orange,
                  ),
                  _buildMetricCard(
                    width: (constraints.maxWidth - 48) / 4,
                    title: 'Compliance Rate',
                    value: profiles.isNotEmpty
                        ? '${((profiles.length - totalHighRisk) / profiles.length * 100).toStringAsFixed(1)}%'
                        : '100%',
                    icon: LucideIcons.checkCircle2,
                    iconColor: Colors.green,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Search and Filters Bar
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by supplier name or KRA PIN...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'All', label: Text('All Vendors')),
                      ButtonSegment(value: 'High Risk', label: Text('High VAA Risk')),
                      ButtonSegment(value: 'Compliant', label: Text('Compliant')),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (val) {
                      setState(() => _selectedFilter = val.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Suppliers Scorecard Data Table
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: PaginatedDataTable(
                  rowsPerPage: filtered.length > 25 ? 25 : (filtered.isEmpty ? 1 : filtered.length),
                  availableRowsPerPage: const [10, 25, 50, 100],
                  columnSpacing: 20,
                  headingRowHeight: 44,
                  dataRowMaxHeight: 56,
                  columns: const [
                    DataColumn(label: Text('Supplier Name / PIN', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Compliance Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Unfiled eTIMS/TIMS Invoices', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Lost VAT Exposure', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Risk Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
  source: SupplierRiskDataTableSource(
    context: context,
    profiles: filtered,
    currencyFormat: currencyFormat,
    riskBadgeBuilder: _buildRiskBadge,
  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: width < 220 ? 220 : width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(RiskLevel level) {
    Color bg;
    Color fg;
    String text;

    switch (level) {
      case RiskLevel.critical:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        text = 'CRITICAL VAA';
        break;
      case RiskLevel.high:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        text = 'HIGH RISK';
        break;
      case RiskLevel.medium:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        text = 'WARNING';
        break;
      case RiskLevel.low:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        text = 'LOW RISK';
        break;
      case RiskLevel.safe:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        text = 'COMPLIANT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class SupplierRiskDataTableSource extends DataTableSource {
  final BuildContext context;
  final List<SupplierRiskProfile> profiles;
  final NumberFormat currencyFormat;
  final Widget Function(RiskLevel) riskBadgeBuilder;

  SupplierRiskDataTableSource({
    required this.context,
    required this.profiles,
    required this.currencyFormat,
    required this.riskBadgeBuilder,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= profiles.length) return null;
    final p = profiles[index];
    final isHighRisk = p.riskLevel == RiskLevel.critical || p.riskLevel == RiskLevel.high;

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(p.supplierPin, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        DataCell(
          Row(
            children: [
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  value: p.complianceRate / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: p.complianceRate >= 80 ? Colors.green : (p.complianceRate >= 50 ? Colors.orange : Colors.red),
                ),
              ),
              const SizedBox(width: 8),
              Text('${p.complianceRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        DataCell(Text('${p.unfiledInvoicesCount} of ${p.totalInvoices}')),
        DataCell(
          Text(
            'KES ${currencyFormat.format(p.unfiledVatAmount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: p.unfiledVatAmount > 0 ? Colors.red.shade700 : AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(riskBadgeBuilder(p.riskLevel)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: isHighRisk && p.unfiledRecords.isNotEmpty
                    ? () async {
                        await VaaDemandNoticeService.printDemandNotice(
                          supplierName: p.supplierName,
                          supplierPin: p.supplierPin,
                          buyerName: 'Apex Enterprises',
                          buyerPin: 'P051284920A',
                          unfiledInvoices: p.unfiledRecords,
                          deadlineDate: DateTime.now().add(const Duration(days: 7)),
                        );
                      }
                    : null,
                icon: const Icon(LucideIcons.fileText, size: 14),
                label: const Text('Demand Notice PDF', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHighRisk ? AppColors.kraGold : Colors.grey.shade300,
                  foregroundColor: isHighRisk ? Colors.white : Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () {
                  final notice = SupplierChaserService.generateNotice(
                    client: TaxpayerClient(
                      id: 'CLI-001',
                      businessName: 'Apex Enterprises',
                      kraPin: 'P051284920A',
                      vatRegistrationNo: 'VAT-051284920A',
                      sector: 'Commercial',
                      contactEmail: 'tax@apex.co.ke',
                      currentTaxPeriod: '2026-08',
                      totalMonthlyPurchases: 0.0,
                      inputVatClaimable: 0.0,
                      inputVatAtRisk: 0.0,
                      totalInvoicesCount: 0,
                      matchedInvoicesCount: 0,
                      riskStatus: 'READY_TO_FILE',
                    ),
                    supplierDiscrepancies: [
                      ReconciliationMatch(
                        matchId: 'MCH-CHASER',
                        invoiceKey: '${p.supplierPin}_CHASER',
                        status: MatchStatus.vaaDisallowanceRisk,
                        riskLevel: RiskLevel.critical,
                        erpRecord: p.unfiledRecords.isNotEmpty ? p.unfiledRecords.first : null,
                        vatVariance: 0.0,
                        totalVariance: 0.0,
                        claimableVatAtRisk: p.unfiledVatAmount,
                        incomeTaxDisallowanceRisk: p.unfiledTaxableAmount,
                        recommendation: 'Missing eTIMS Control Code',
                        actionPlan: 'Demand supplier transmission',
                      ),
                    ],
                  );

                  // Show Chaser Notice Dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.darkCard,
                      title: Row(
                        children: [
                          const Icon(LucideIcons.messageSquare, color: AppColors.mintAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('Supplier Chaser Notice - ${notice.supplierName}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Recipient: ${notice.supplierEmail}', style: const TextStyle(color: AppColors.kraGold, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 10),
                            const Text('EMAIL SUBJECT:', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                            SelectableText(notice.emailSubject, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            const Text('EMAIL BODY:', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(8)),
                              child: SelectableText(notice.emailBody, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(LucideIcons.mail, size: 14),
                label: const Text('Chaser Notice', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.mintAccent,
                  side: const BorderSide(color: AppColors.mintAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => profiles.length;

  @override
  int get selectedRowCount => 0;
}
