import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class Vat7FilingChecklistDialog extends StatefulWidget {
  final String taxPeriod;
  final String clientName;
  final String kraPin;

  const Vat7FilingChecklistDialog({
    super.key,
    required this.taxPeriod,
    required this.clientName,
    required this.kraPin,
  });

  @override
  State<Vat7FilingChecklistDialog> createState() => _Vat7FilingChecklistDialogState();
}

class _Vat7FilingChecklistDialogState extends State<Vat7FilingChecklistDialog> {
  final Map<int, bool> _checks = {
    1: true,
    2: true,
    3: true,
    4: true,
    5: false,
    6: true,
    7: true,
    8: true,
    9: false,
    10: false,
  };

  final List<String> _checklistItems = [
    'Verify Supplier KRA PIN validity & active VAT registration status',
    'Execute 3-Way Match between ERP purchase ledger, eTIMS/TIMS server, and iTax schedule',
    'Reconcile Credit Notes (CN) and Debit Notes (DN) return adjustments',
    'Audit 2% Withholding VAT (WHVAT) certificates issued by withholding agents',
    'Resolve VAA Disallowance Risk items & dispatch supplier Demand Notices',
    'Verify Section 16(1) Corporate Income Tax 2026 expense deductibility rules',
    'Export KRA iTax Section B Input VAT CSV File',
    'Export Multi-Tab Excel (.xlsx) Audit Ledger Workbook for internal audit sign-off',
    'Lock tax period with SHA-256 Immutable Reconciliation Certificate',
    'Upload Section B CSV to KRA iTax portal & generate Payment Registration Number (PRN)',
  ];

  int get _daysRemaining {
    final now = DateTime.now();
    DateTime deadline = DateTime(now.year, now.month, 20);
    if (now.day > 20) {
      deadline = DateTime(now.year, now.month + 1, 20);
    }
    return deadline.difference(now).inDays;
  }

  int get _completedCount => _checks.values.where((v) => v).length;
  double get _readinessPercent => (_completedCount / _checklistItems.length) * 100;

  @override
  Widget build(BuildContext context) {
    final days = _daysRemaining;

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Countdown Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.emeraldPrimary.withValues(alpha: 0.3),
                    AppColors.darkBg,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.calendarCheck, color: AppColors.kraGold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Monthly VAT 7 Return Filing Deadline',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Taxpayer: ${widget.clientName} (${widget.kraPin}) • Period: ${widget.taxPeriod}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),

                  // Days Remaining Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: days <= 3 ? AppColors.crimsonRisk : AppColors.emeraldPrimary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (days <= 3 ? AppColors.crimsonRisk : AppColors.emeraldPrimary).withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$days DAYS',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const Text(
                          'REMAINING',
                          style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Readiness Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filing Readiness: ${_readinessPercent.toStringAsFixed(0)}% ($_completedCount of ${_checklistItems.length} completed)',
                  style: const TextStyle(color: AppColors.mintAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  _completedCount == 10 ? 'READY FOR KRA ITAX FILING' : 'PRE-FILING IN PROGRESS',
                  style: TextStyle(
                    color: _completedCount == 10 ? AppColors.mintAccent : AppColors.warningOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _completedCount / _checklistItems.length,
              backgroundColor: AppColors.darkBg,
              color: _completedCount == 10 ? AppColors.mintAccent : AppColors.kraGold,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 20),

            // 10-Point Checklist Items List
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _checklistItems.length,
                itemBuilder: (context, idx) {
                  final itemNo = idx + 1;
                  final isChecked = _checks[itemNo] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isChecked ? AppColors.emeraldPrimary.withValues(alpha: 0.5) : AppColors.darkBorder),
                    ),
                    child: CheckboxListTile(
                      activeColor: AppColors.emeraldPrimary,
                      checkColor: Colors.white,
                      title: Text(
                        '$itemNo. ${_checklistItems[idx]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isChecked ? Colors.white : AppColors.textSecondary,
                          fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          _checks[itemNo] = val ?? false;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.darkBorder),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(LucideIcons.checkCheck, size: 16),
                  label: const Text('Save Readiness Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('VAT 7 pre-filing checklist readiness status saved!'),
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
    );
  }
}
