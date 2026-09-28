import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../services/vat_apportionment_service.dart';
import '../../services/itax_export_service.dart';
import '../../theme/app_theme.dart';

class VatApportionmentDialog extends StatefulWidget {
  const VatApportionmentDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const VatApportionmentDialog(),
    );
  }

  @override
  State<VatApportionmentDialog> createState() => _VatApportionmentDialogState();
}

class _VatApportionmentDialogState extends State<VatApportionmentDialog> {
  late TextEditingController _taxableSalesController;
  late TextEditingController _zeroRatedSalesController;
  late TextEditingController _exemptSalesController;
  late TextEditingController _totalInputVatController;

  VatApportionmentResult? _result;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final erpTotal = state.erpRecords.fold(0.0, (sum, r) => sum + r.totalAmount);
    final totalVat = state.totalInputVatClaimable + state.totalInputVatAtRisk;

    _taxableSalesController = TextEditingController(text: erpTotal > 0 ? erpTotal.toStringAsFixed(2) : '5000000.00');
    _zeroRatedSalesController = TextEditingController(text: '1200000.00');
    _exemptSalesController = TextEditingController(text: '800000.00');
    _totalInputVatController = TextEditingController(text: totalVat > 0 ? totalVat.toStringAsFixed(2) : '832000.00');

    _recalculate();
  }

  void _recalculate() {
    final taxable = double.tryParse(_taxableSalesController.text) ?? 0.0;
    final zero = double.tryParse(_zeroRatedSalesController.text) ?? 0.0;
    final exempt = double.tryParse(_exemptSalesController.text) ?? 0.0;
    final inputVat = double.tryParse(_totalInputVatController.text) ?? 0.0;

    setState(() {
      _result = VatApportionmentService.calculate(
        taxableSales16Percent: taxable,
        zeroRatedSales: zero,
        exemptSales: exempt,
        totalInputVatPaid: inputVat,
      );
    });
  }

  @override
  void dispose() {
    _taxableSalesController.dispose();
    _zeroRatedSalesController.dispose();
    _exemptSalesController.dispose();
    _totalInputVatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fmt = NumberFormat('#,##0.00');
    final res = _result;

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Container(
        width: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.kraGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.pieChart, color: AppColors.kraGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Section 17 Partial Exemption Apportionment',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Kenya VAT Act 2013 - Input Tax Deductibility Calculator',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                ),
              ],
            ),
            const Divider(height: 24),

            // Input Fields Row
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    label: '16% Taxable Supplies (KES)',
                    controller: _taxableSalesController,
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputField(
                    label: '0% Zero-Rated Exports (KES)',
                    controller: _zeroRatedSalesController,
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputField(
                    label: 'Exempt Sales (KES)',
                    controller: _exemptSalesController,
                    onChanged: (_) => _recalculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _inputField(
              label: 'Total Invoiced Input VAT Paid in Period (KES)',
              controller: _totalInputVatController,
              onChanged: (_) => _recalculate(),
            ),
            const SizedBox(height: 20),

            // Results Box
            if (res != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Section 17 Apportionment Ratio:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: res.is100PercentClaimable
                                ? AppColors.emeraldDark.withValues(alpha: 0.2)
                                : res.is0PercentClaimable
                                    ? AppColors.crimsonRisk.withValues(alpha: 0.2)
                                    : AppColors.kraGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${res.apportionmentRatio.toStringAsFixed(2)}% Claimable',
                            style: TextStyle(
                              color: res.is100PercentClaimable
                                  ? AppColors.emeraldDark
                                  : res.is0PercentClaimable
                                      ? AppColors.crimsonRisk
                                      : AppColors.kraGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ALLOWABLE INPUT VAT', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('KES ${fmt.format(res.claimableInputVat)}', style: const TextStyle(color: AppColors.mintAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NON-DEDUCTIBLE VAT (EXPENSED)', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('KES ${fmt.format(res.nonDeductibleInputVat)}', style: const TextStyle(color: AppColors.crimsonRisk, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Advice box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, color: AppColors.infoBlue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        res.complianceAdvice,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (res == null) return;
                    final pdfBytes = await VatApportionmentService.generateApportionmentPdf(
                      client: state.activeClient,
                      taxPeriod: state.selectedTaxPeriod,
                      result: res,
                    );
                    final fileName = 'Reconix_Sec17_PartialExemption_${state.activeClient.kraPin}.pdf';
                    ITaxExportService.downloadCsvWeb(
                      csvData: String.fromCharCodes(pdfBytes),
                      fileName: fileName,
                    );
                    await state.logAuditAction(
                      action: 'GENERATE_SEC17_APPORTIONMENT_PDF',
                      targetKey: state.activeClient.kraPin,
                      details: 'Generated Section 17 Partial Exemption Apportionment Audit Certificate.',
                    );
                  },
                  icon: const Icon(LucideIcons.fileText, size: 16),
                  label: const Text('Download Sec 17 PDF Audit Certificate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kraGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.darkBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kraGold)),
          ),
        ),
      ],
    );
  }
}
