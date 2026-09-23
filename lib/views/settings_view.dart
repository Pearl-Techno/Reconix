import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/reconciliation_rules.dart';
import '../theme/app_theme.dart';

class SettingsView extends StatefulWidget {
  final ReconciliationRules currentRules;
  final ValueChanged<ReconciliationRules> onRulesSaved;

  const SettingsView({
    super.key,
    required this.currentRules,
    required this.onRulesSaved,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late int _maxDateDays;
  late double _amountTolerance;
  late bool _enableFuzzy;
  late bool _ignorePrefixes;
  late bool _requirePinMatch;

  @override
  void initState() {
    super.initState();
    _maxDateDays = widget.currentRules.maxDateDifferenceDays;
    _amountTolerance = widget.currentRules.amountToleranceKes;
    _enableFuzzy = widget.currentRules.enableFuzzyInvoiceMatching;
    _ignorePrefixes = widget.currentRules.ignoreInvoicePrefixes;
    _requirePinMatch = widget.currentRules.requireExactPinMatch;
  }

  void _saveSettings() {
    final updated = ReconciliationRules(
      maxDateDifferenceDays: _maxDateDays,
      amountToleranceKes: _amountTolerance,
      enableFuzzyInvoiceMatching: _enableFuzzy,
      ignoreInvoicePrefixes: _ignorePrefixes,
      requireExactPinMatch: _requirePinMatch,
    );
    widget.onRulesSaved(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reconciliation tolerance rules updated successfully!'),
        backgroundColor: AppColors.emeraldDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reconciliation Rules & Matching Settings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure date windows, currency rounding tolerances, and fuzzy invoice matching algorithms.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(LucideIcons.save, size: 16),
                label: const Text('Save Rules'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cards Grid
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Matching Tolerances',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Date Threshold
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Maximum Invoice Date Variance Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Allowable gap in days between ERP date and eTIMS transmission timestamp', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      Text('±$_maxDateDays Days', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark)),
                    ],
                  ),
                  Slider(
                    value: _maxDateDays.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    activeColor: AppColors.emeraldDark,
                    onChanged: (val) => setState(() => _maxDateDays = val.round()),
                  ),
                  const SizedBox(height: 20),

                  // Amount Rounding Tolerance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Currency Rounding Amount Tolerance (KES)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Maximum allowable total/VAT difference due to cent rounding', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      Text('±KES ${_amountTolerance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.kraGold)),
                    ],
                  ),
                  Slider(
                    value: _amountTolerance,
                    min: 0.0,
                    max: 10.0,
                    divisions: 20,
                    activeColor: AppColors.kraGold,
                    onChanged: (val) => setState(() => _amountTolerance = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Matching Switches Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fuzzy Invoice & PIN Algorithms',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Enable Fuzzy Invoice Number Normalization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Strip punctuation, spaces, slashes (/), and hyphens (-) during comparison'),
                    value: _enableFuzzy,
                    activeTrackColor: AppColors.emeraldDark,
                    onChanged: (val) => setState(() => _enableFuzzy = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Ignore Invoice Prefixes & Leading Zeros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Ignores "INV-", "INV", and leading zeros (e.g., INV-00452 matches 452)'),
                    value: _ignorePrefixes,
                    activeTrackColor: AppColors.emeraldDark,
                    onChanged: (val) => setState(() => _ignorePrefixes = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Require Strict KRA PIN Matching', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Strictly enforce matching KRA PINs across ERP, eTIMS, and iTax schedules'),
                    value: _requirePinMatch,
                    activeTrackColor: AppColors.emeraldDark,
                    onChanged: (val) => setState(() => _requirePinMatch = val),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
