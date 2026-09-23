import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class LicenseActivationDialog extends StatefulWidget {
  final bool isDismissible;

  const LicenseActivationDialog({
    super.key,
    this.isDismissible = false,
  });

  static Future<void> show(BuildContext context, {bool isDismissible = false}) async {
    await showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => LicenseActivationDialog(isDismissible: isDismissible),
    );
  }

  @override
  State<LicenseActivationDialog> createState() => _LicenseActivationDialogState();
}

class _LicenseActivationDialogState extends State<LicenseActivationDialog> {
  final _keyController = TextEditingController();
  bool _isActivating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleActivation() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid commercial activation license key.';
      });
      return;
    }

    setState(() {
      _isActivating = true;
      _errorMessage = null;
    });

    final appState = context.read<AppState>();
    final success = await appState.activateLicenseKey(key);

    if (!mounted) return;

    setState(() {
      _isActivating = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconix System Activated Successfully! Annual Subscription Valid.'),
          backgroundColor: AppColors.emeraldPrimary,
        ),
      );
      if (widget.isDismissible || Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid Activation License Key. Contact Quantyx Labs (+254702687799) to purchase a license.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.licenseStatus;

    return PopScope(
      canPop: widget.isDismissible,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 650,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(LucideIcons.keyRound, color: AppColors.mintAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'RECONIX COMMERCIAL ACTIVATION',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.kraGold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'QUANTYX LABS',
                                  style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'System License & First-Run Security Protection Engine',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isDismissible)
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.darkBorder),
                const SizedBox(height: 16),

                // System Status Warning Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: status?.isExpired == true
                        ? AppColors.crimsonRisk.withValues(alpha: 0.15)
                        : AppColors.kraGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: status?.isExpired == true ? AppColors.crimsonRisk : AppColors.kraGold,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status?.isExpired == true ? LucideIcons.alertOctagon : LucideIcons.shieldAlert,
                        color: status?.isExpired == true ? AppColors.crimsonRisk : AppColors.kraGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status?.message ?? 'System license check required. Activation is mandatory prior to first operational use.',
                          style: TextStyle(
                            color: status?.isExpired == true ? AppColors.crimsonRisk : AppColors.kraGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Commercial Purchase & Renewal Information Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.building, color: AppColors.mintAccent, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'LICENSING & ACQUISITION PRICING',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow('System Access Fee (Minimum):', 'KES 15,000 (One-time Repository Access)'),
                      _infoRow('Annual Subscription Renewal:', 'KES 20,000 / year (M-Pesa Direct: +254702687799)'),
                      _infoRow('Lead Developer:', 'Davies Mukoya'),
                      _infoRow('Company:', 'Quantyx Labs'),
                      _infoRow('Email Contact:', 'info@quantyx.co.ke'),
                      _infoRow('M-Pesa Direct Payment / Coffee:', '+254702687799 (Davies Mukoya)'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Key Entry Form
                const Text(
                  'ENTER ACTIVATION KEY',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _keyController,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Monospace'),
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit master activation key or enterprise token',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.darkBg,
                    prefixIcon: const Icon(LucideIcons.key, color: AppColors.mintAccent, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.darkBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.mintAccent),
                    ),
                  ),
                  onSubmitted: (_) => _handleActivation(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.crimsonRisk, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 24),

                // Action Buttons & Support Coffee Note
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isActivating ? null : _handleActivation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isActivating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.checkCircle, size: 18),
                        label: Text(
                          _isActivating ? 'ACTIVATING...' : 'ACTIVATE RECONIX SYSTEM',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.coffee, color: AppColors.kraGold, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Buy the Lead Engineer Coffee via M-Pesa: +254702687799 (Davies Mukoya)',
                        style: TextStyle(color: AppColors.kraGold.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
