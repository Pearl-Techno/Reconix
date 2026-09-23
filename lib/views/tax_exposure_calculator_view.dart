import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class TaxExposureCalculatorView extends StatefulWidget {
  const TaxExposureCalculatorView({super.key});

  @override
  State<TaxExposureCalculatorView> createState() => _TaxExposureCalculatorViewState();
}

class _TaxExposureCalculatorViewState extends State<TaxExposureCalculatorView> {
  final TextEditingController _grossPurchasesController = TextEditingController(text: '10,000,000');
  double _nonEtimsPercent = 15.0; // 15% non-compliant invoices
  double _citTaxRate = 30.0; // 30% corporate income tax
  bool _includeKraPenalties = true;

  double get _grossPurchases {
    final clean = _grossPurchasesController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 10000000.0;
  }

  double get _nonEtimsAmount => _grossPurchases * (_nonEtimsPercent / 100.0);
  double get _lostInputVat => _nonEtimsAmount * (0.16 / 1.16);
  double get _disallowedExpense => _nonEtimsAmount - _lostInputVat;
  double get _additionalCitTax => _disallowedExpense * (_citTaxRate / 100.0);
  double get _kraPenalties => _includeKraPenalties ? (_lostInputVat + _additionalCitTax) * 0.10 : 0.0; // 10% penalty + interest
  double get _totalExposure => _lostInputVat + _additionalCitTax + _kraPenalties;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2026 Corporate Income Tax & VAA Exposure Calculator',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simulate potential tax disallowance exposure under Section 16 of the Kenya Income Tax Act.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Two Column Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              return Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inputs Form Column
                  SizedBox(
                    width: isDesktop ? constraints.maxWidth * 0.45 : double.infinity,
                    child: Card(
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
                              'Simulation Parameters',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text('Total Annual Purchase Expenditure (KES)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _grossPurchasesController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                prefixText: 'KES ',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Unmatched / Non-eTIMS & Non-TIMS Purchases (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${_nonEtimsPercent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.kraGold)),
                              ],
                            ),
                            Slider(
                              value: _nonEtimsPercent,
                              min: 0.0,
                              max: 50.0,
                              divisions: 50,
                              activeColor: AppColors.kraGold,
                              label: '${_nonEtimsPercent.toStringAsFixed(1)}%',
                              onChanged: (val) => setState(() => _nonEtimsPercent = val),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Corporate Income Tax Rate (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${_citTaxRate.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Slider(
                              value: _citTaxRate,
                              min: 15.0,
                              max: 30.0,
                              divisions: 3,
                              activeColor: AppColors.emeraldDark,
                              label: '${_citTaxRate.toStringAsFixed(0)}%',
                              onChanged: (val) => setState(() => _citTaxRate = val),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('Include KRA Statutory Late Penalties & Interest (10%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              value: _includeKraPenalties,
                              activeTrackColor: AppColors.emeraldDark,
                              onChanged: (val) => setState(() => _includeKraPenalties = val),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isDesktop) const SizedBox(width: 24) else const SizedBox(height: 24),

                  // Simulation Results Output Column
                  Expanded(
                    child: Card(
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
                              'Calculated Tax Liability Exposure',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            // Total Red Exposure Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(LucideIcons.alertOctagon, color: Colors.red, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('TOTAL POTENTIAL TAX PENALTY EXPOSURE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                        Text('KES ${currencyFormat.format(_totalExposure)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Breakdown List
                            _buildBreakdownRow('16% Disallowed Input VAT Lost', 'KES ${currencyFormat.format(_lostInputVat)}', Colors.orange.shade800),
                            const Divider(),
                            _buildBreakdownRow('Disallowed Business Expenses (Sec 16)', 'KES ${currencyFormat.format(_disallowedExpense)}', Colors.grey.shade800),
                            const Divider(),
                            _buildBreakdownRow('30% Additional CIT Corporate Tax Due', 'KES ${currencyFormat.format(_additionalCitTax)}', Colors.red.shade800),
                            if (_includeKraPenalties) ...[
                              const Divider(),
                              _buildBreakdownRow('KRA Interest & Late Payment Penalty', 'KES ${currencyFormat.format(_kraPenalties)}', Colors.purple.shade800),
                            ],
                            const SizedBox(height: 24),

                            // Mini Visual Chart
                            const Text('Tax Exposure Composition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 160,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barGroups: [
                                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _lostInputVat, color: Colors.orange, width: 24)]),
                                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _additionalCitTax, color: Colors.red, width: 24)]),
                                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _kraPenalties, color: Colors.purple, width: 24)]),
                                  ],
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          switch (val.toInt()) {
                                            case 0:
                                              return const Text('VAT Loss', style: TextStyle(fontSize: 10));
                                            case 1:
                                              return const Text('CIT Tax', style: TextStyle(fontSize: 10));
                                            case 2:
                                              return const Text('KRA Penalty', style: TextStyle(fontSize: 10));
                                            default:
                                              return const Text('');
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Live Active Entity KRA Statutory Penalty & Interest Simulator Card
          Builder(
            builder: (context) {
              final state = context.watch<AppState>();
              final sim = state.calculatePenaltyExposure(daysOverdue: 15);

              return Card(
                color: AppColors.darkCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.darkBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(LucideIcons.scale, color: AppColors.kraGold, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Live Active Entity KRA Statutory Penalty Simulator (TPA Sec. 38, 83 & 84)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.crimsonRisk.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.crimsonRisk),
                            ),
                            child: const Text(
                              'STATUTORY AUDIT SIMULATOR',
                              style: TextStyle(color: AppColors.crimsonRisk, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Simulated for ${state.activeClient.businessName} (PIN: ${state.activeClient.kraPin}) across Tax Period ${state.selectedTaxPeriod}. Assumes 15 days overdue past 20th statutory deadline.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sec. 83 Late Filing Penalty', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 4),
                                  Text('KES ${currencyFormat.format(sim.lateFilingPenalty)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kraGold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sec. 38 Late Payment Interest', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 4),
                                  Text('KES ${currencyFormat.format(sim.latePaymentInterest)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warningOrange)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sec. 84 VAA Disallowance Penalty (20%)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 4),
                                  Text('KES ${currencyFormat.format(sim.vaaDisallowancePenalty)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.crimsonRisk)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Statutory Audit Notes & Legal References:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      ...sim.breakdownNotes.map((note) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.checkCircle2, color: AppColors.mintAccent, size: 14),
                              const SizedBox(width: 8),
                              Expanded(child: Text(note, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
