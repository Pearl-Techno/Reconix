import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/taxpayer_client.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class AddCompanyDialog extends StatefulWidget {
  const AddCompanyDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const AddCompanyDialog(),
    );
  }

  @override
  State<AddCompanyDialog> createState() => _AddCompanyDialogState();
}

class _AddCompanyDialogState extends State<AddCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _vatController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedSector = 'Transport & Logistics';

  final List<String> _sectors = [
    'Transport & Logistics',
    'Manufacturing & Industrial',
    'Commercial Retail & Wholesale',
    'Agriculture & Export',
    'Professional Services & IT',
    'Construction & Real Estate',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _vatController.dispose();
    _emailController.dispose();
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
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.building2, color: AppColors.mintAccent, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Register New Taxpayer Company',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Add a new company profile to manage its independent eTIMS, ERP, and iTax datasets.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Business Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDecoration('Company / Business Name', LucideIcons.building),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter business name' : null,
              ),
              const SizedBox(height: 14),

              // KRA PIN & VAT Reg Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pinController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration('KRA PIN (e.g. P051234567A)', LucideIcons.fileText),
                      validator: (val) => val == null || val.trim().length < 11 ? 'Enter valid KRA PIN' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _vatController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration('VAT Registration No', LucideIcons.shield),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Sector & Email Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSector,
                      isExpanded: true,
                      dropdownColor: AppColors.darkBg,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration('Industry Sector', LucideIcons.briefcase),
                      items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSector = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration('Tax Contact Email', LucideIcons.mail),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.plusCircle, size: 16),
                    label: const Text('Register & Open Company', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final pin = _pinController.text.trim().toUpperCase();
      final vatNo = _vatController.text.trim().isEmpty ? 'VAT-$pin' : _vatController.text.trim();
      final id = 'CLI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final newClient = TaxpayerClient(
        id: id,
        businessName: _nameController.text.trim(),
        kraPin: pin,
        vatRegistrationNo: vatNo,
        sector: _selectedSector,
        contactEmail: _emailController.text.trim().isEmpty ? 'info@company.co.ke' : _emailController.text.trim(),
        currentTaxPeriod: '2026-08',
        totalMonthlyPurchases: 0.0,
        inputVatClaimable: 0.0,
        inputVatAtRisk: 0.0,
        totalInvoicesCount: 0,
        matchedInvoicesCount: 0,
        riskStatus: 'READY_TO_FILE',
      );

      final state = context.read<AppState>();
      state.addNewCompany(newClient);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registered and opened active entity: ${newClient.businessName}'),
          backgroundColor: AppColors.emeraldPrimary,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      prefixIcon: Icon(icon, size: 16, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.darkBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.mintAccent)),
    );
  }
}
