import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/reconciliation_match.dart';
import '../../models/invoice_record.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

import 'itax_invoice_checker_dialog.dart';

class InvoiceDetailDialog extends StatefulWidget {
  final ReconciliationMatch match;

  const InvoiceDetailDialog({super.key, required this.match});

  @override
  State<InvoiceDetailDialog> createState() => _InvoiceDetailDialogState();
}

class _InvoiceDetailDialogState extends State<InvoiceDetailDialog> {
  final _numberFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('dd MMM yyyy');
  late String _selectedTag;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _tagOptions = [
    'Cleared for VAT Return Filing',
    'Pending eTIMS from Supplier',
    'Systemic Timing Delay - Claim Next Month',
    'VAA Penalty Defense Logged',
    'Exclude from Input VAT Claim',
    'Disputed Amount with Supplier',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.match.resolutionTag ?? _tagOptions[0];
    _noteController.text = widget.match.userNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final statusColor = AppTheme.getStatusColor(match.status);

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Container(
        width: 850,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Icon(LucideIcons.fileText, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice ${match.invoiceNumber}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            'Supplier: ${match.supplierName} (${match.supplierPin})',
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

              // Status Alert Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          match.status.title.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getRiskColor(match.riskLevel),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'RISK: ${match.riskLevel.name.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.recommendation,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3-Way Comparative Grid
              Text('3-Way Source Comparison', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSourceCard(
                      title: 'Internal ERP Books',
                      source: SourceType.erp,
                      record: match.erpRecord,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceCard(
                      title: 'eTIMS System',
                      source: SourceType.etims,
                      record: match.etimsRecord,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceCard(
                      title: 'iTax Return Schedule',
                      source: SourceType.itax,
                      record: match.itaxRecord,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recommended Action Plan Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.checkCircle2, color: AppColors.mintAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Recommended Advisor Action Plan',
                          style: TextStyle(
                            color: AppColors.mintAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.actionPlan,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Interactive eTIMS Control Code & QR Verification Inspector Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.qrCode, color: AppColors.kraGold, size: 18),
                              SizedBox(width: 8),
                              Text('KRA eTIMS CONTROL CODE & QR VERIFICATION', style: TextStyle(color: AppColors.kraGold, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            match.etimsRecord?.etimsControlCode ?? match.erpRecord?.etimsControlCode ?? 'ETIMS-CONTROL-${match.invoiceNumber}',
                            style: const TextStyle(fontFamily: 'Monospace', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'KRA Verification URL: https://etims.kra.go.ke/verify/${match.supplierPin}/${match.invoiceNumber}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.kraGold,
                        side: const BorderSide(color: AppColors.kraGold),
                      ),
                      icon: const Icon(LucideIcons.shieldCheck, size: 14),
                      label: const Text('Verify on iTax Checker'),
                      onPressed: () {
                        final controlCode = match.etimsRecord?.etimsControlCode ??
                            match.erpRecord?.etimsControlCode ??
                            match.invoiceNumber;
                        showDialog(
                          context: context,
                          builder: (context) => ItaxInvoiceCheckerDialog(initialControlNumber: controlCode),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tagging & Resolution Notes Section
              Text('Auditor Resolution & Tagging', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTag,
                      dropdownColor: AppColors.darkCard,
                      decoration: const InputDecoration(
                        labelText: 'Resolution Status Tag',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: _tagOptions.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTag = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Advisor Audit Notes & Defense Rationale',
                  hintText: 'Enter specific notes for iTax submission or supplier follow-up...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    icon: const Icon(LucideIcons.save, size: 18),
                    label: const Text('Save Audit Tag', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      context.read<AppState>().updateResolution(
                            matchId: match.matchId,
                            tag: _selectedTag,
                            note: _noteController.text,
                          );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Resolution tag saved for Invoice ${match.invoiceNumber}'),
                          backgroundColor: AppColors.emeraldPrimary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required String title,
    required SourceType source,
    required InvoiceRecord? record,
  }) {
    final isPresent = record != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPresent ? AppColors.darkBg : AppColors.darkBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPresent ? AppColors.darkBorder : AppColors.crimsonRisk.withValues(alpha: 0.4),
          width: isPresent ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPresent ? AppColors.mintAccent.withValues(alpha: 0.2) : AppColors.crimsonRisk.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPresent ? 'PRESENT' : 'MISSING',
                  style: TextStyle(
                    color: isPresent ? AppColors.mintAccent : AppColors.crimsonRisk,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          if (isPresent) ...[
            _fieldRow('Inv Date', _dateFormat.format(record.invoiceDate)),
            _fieldRow('Total Amt', 'KES ${_numberFormat.format(record.totalAmount)}'),
            _fieldRow('Taxable', 'KES ${_numberFormat.format(record.taxableAmount)}'),
            _fieldRow('VAT (16%)', 'KES ${_numberFormat.format(record.vatAmount)}'),
            if (record.etimsControlCode != null)
              _fieldRow('eTIMS Code', '${record.etimsControlCode!.substring(0, 12)}...'),
            if (record.cuSerialNumber != null)
              _fieldRow('CU S/N', record.cuSerialNumber!),
          ] else ...[
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'No matching record\nfound in this source',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 30),
          ]
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
