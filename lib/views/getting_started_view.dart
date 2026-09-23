import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/itax_invoice_checker_dialog.dart';
import 'widgets/user_guide_dialog.dart';

class GettingStartedView extends StatelessWidget {
  const GettingStartedView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.darkCard,
                  AppColors.emeraldPrimary.withValues(alpha: 0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emeraldPrimary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldPrimary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mintAccent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'WELCOME TO RECONIX',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                            color: Colors.white,
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.kraGold,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'KRA eTIMS & TIMS VAT 3-WAY ENGINE',
                                        style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Kenyan VAT 3-Way Reconciliation & eTIMS/TIMS ETR Compliance Defense System',
                                  style: TextStyle(color: AppColors.mintAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Quick Mode Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.darkBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.dataMode == DataMode.demo ? LucideIcons.sparkles : LucideIcons.database,
                            color: state.dataMode == DataMode.demo ? AppColors.kraGold : AppColors.mintAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state.dataMode == DataMode.demo ? 'DEMO DATA ACTIVE' : 'LIVE SQLITE ACTIVE',
                            style: TextStyle(
                              color: state.dataMode == DataMode.demo ? AppColors.kraGold : AppColors.mintAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Reconix is built specifically for Kenyan corporate taxpayers, finance managers, and ICPAK certified advisors. '
                  'It automates 3-way matching between internal ERP ledgers, eTIMS & hardware TIMS ETR server databases, and KRA pre-filled iTax Section B schedules '
                  'to eliminate VAA back-tax penalties under Section 16(2)(ac) and maximize legitimate input VAT claims.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),

                // Feature Highlights Pills Row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _featurePill(LucideIcons.gitCompare, 'Automated 3-Way Matching'),
                    _featurePill(LucideIcons.shieldAlert, 'VAA Penalty Protection'),
                    _featurePill(LucideIcons.fileSpreadsheet, 'Section B CSV Exporter'),
                    _featurePill(LucideIcons.checkCircle2, 'Official iTax Verification'),
                    _featurePill(LucideIcons.lock, 'SHA-256 Signed Evidence Packs'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Step-by-Step Interactive Workflow Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How Reconix Works: Step-by-Step Workflow', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Follow the 4-step guided process from raw dataset ingestion to filing-ready Section B CSV export and audit defense.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kraGold,
                  side: const BorderSide(color: AppColors.kraGold),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                icon: const Icon(LucideIcons.bookOpen, size: 16),
                label: const Text('Interactive User Guide & Manual', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => UserGuideDialog.show(context),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mintAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                icon: const Icon(LucideIcons.play, size: 18),
                label: const Text('Start Step 1: Upload CSVs', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => state.setActiveTab(3), // Switch to Data Ingestion Hub
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4 Step Cards Grid / Column
          _buildStepCard(
            context,
            stepNumber: 1,
            title: 'Multi-Source Data Ingestion (eTIMS + TIMS ETR)',
            badgeText: 'STEP 1: INGESTION',
            badgeColor: AppColors.infoBlue,
            icon: LucideIcons.uploadCloud,
            description:
                'Upload CSV/Excel files from 3 essential VAT sources: eTIMS online & TIMS ETR hardware exports, internal purchase ledgers (QuickBooks, SAP, Sage, Tally), '
                'and KRA auto-populated Section B pre-filled schedules downloaded from iTax (e.g. SEC_B_WITH_VAT_PIN.CSV & SEC_B_WITHOUT_PIN.CSV).',
            highlights: [
              'Auto-detects headerless KRA CSV schedules directly',
              'Supports both software eTIMS Control Codes & hardware TIMS ETR Serial Numbers (CU S/N)',
              'Strips leading pipe "|" symbols from Control Unit Numbers',
              'Separates VAT-registered PIN purchases from non-VAT merchant expenses',
              'Displays line-by-line diagnostic summary dialogs upon upload',
            ],
            buttonText: 'Proceed to Step 1: Data Ingestion Hub',
            buttonIcon: LucideIcons.uploadCloud,
            onAction: () => state.setActiveTab(3), // Navigates to Ingestion View
          ),
          const SizedBox(height: 20),

          _buildStepCard(
            context,
            stepNumber: 2,
            title: 'Automated 3-Way Matching Engine',
            badgeText: 'STEP 2: RECONCILIATION',
            badgeColor: AppColors.mintAccent,
            icon: LucideIcons.columns,
            description:
                'The Reconix engine cross-references every transaction by Control Unit Invoice Number / ETR CU Serial Number (eTIMS & TIMS), Supplier PIN, Date, and Amount '
                'to categorize invoices into 6 precision compliance statuses.',
            highlights: [
              'Perfect 3-Way Match: 100% safe to claim Section B Input VAT',
              'Timing Latency: Detects eTIMS/TIMS invoices delayed beyond month-end cutoff',
              'Unclaimed Input VAT: Uncovers missing internal ledger credits to claim extra KES refund',
              'VAA Risk & 2026 Expense Risk: Identifies disallowance threats BEFORE filing return',
            ],
            buttonText: 'Open Step 2: 3-Way VAT Matching Ledger',
            buttonIcon: LucideIcons.columns,
            onAction: () => state.setActiveTab(2), // Navigates to Reconciliation View
          ),
          const SizedBox(height: 20),

          _buildStepCard(
            context,
            stepNumber: 3,
            title: 'VAA Risk Resolution & Official iTax Verification',
            badgeText: 'STEP 3: RESOLUTION & VERIFICATION',
            badgeColor: AppColors.warningOrange,
            icon: LucideIcons.shieldAlert,
            description:
                'Audit high-risk exceptions, apply resolution tags, and verify suspicious control unit numbers live against KRA\'s official iTax verification database.',
            highlights: [
              'Filter by Risk Level (VAA Exposure, Unclaimed VAT, Corporate Tax Risk)',
              'Apply bulk resolution tags (Request Vendor eTIMS Transmission, Disallow Claim)',
              'Embedded KRA iTax Invoice Checker styled after official KRA portal interface',
            ],
            buttonText: 'Launch KRA iTax Invoice Checker Modal',
            buttonIcon: LucideIcons.shieldCheck,
            onAction: () {
              showDialog(
                context: context,
                builder: (context) => const ItaxInvoiceCheckerDialog(),
              );
            },
          ),
          const SizedBox(height: 20),

          _buildStepCard(
            context,
            stepNumber: 4,
            title: 'Export Filing-Ready Section B CSV & Cryptographic Evidence Pack',
            badgeText: 'STEP 4: FILING & AUDIT DEFENSE',
            badgeColor: AppColors.kraGold,
            icon: LucideIcons.fileCheck2,
            description:
                'Generate clean, verified KRA iTax Section B Input VAT CSV files ready for upload into KRA\'s iTax portal, and lock tax periods with SHA-256 signed audit certificates.',
            highlights: [
              'Exports Section B CSV containing ONLY 3-way verified claimable input VAT records',
              'Generates SHA-256 immutable Reconciliation Certificates',
              'Produces Audit Evidence Packs for ICPAK tax advisor sign-off and KRA defense',
            ],
            buttonText: 'View Step 4: Audit Evidence Packs',
            buttonIcon: LucideIcons.fileCheck2,
            onAction: () => state.setActiveTab(4), // Navigates to Evidence Pack View
          ),
          const SizedBox(height: 32),

          // Bottom Quick Navigation Action Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ready to Start Your Monthly VAT Reconciliation?',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Currently viewing taxpayer context: ${state.activeClient.businessName} (PIN: ${state.activeClient.kraPin})',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.darkBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.layoutDashboard, size: 16),
                      label: const Text('Go to Executive Dashboard'),
                      onPressed: () => state.setActiveTab(1),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.arrowRight, size: 18),
                      label: const Text('Go to Step 1: Data Ingestion Hub', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => state.setActiveTab(3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.mintAccent, size: 14),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required String description,
    required List<String> highlights,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onAction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Step Number Circle Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 2),
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(color: badgeColor, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Middle Content Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Highlights Checklist
                  Column(
                    children: highlights.map((h) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(LucideIcons.check, color: badgeColor, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Action Navigation Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBg,
                        foregroundColor: badgeColor,
                        side: BorderSide(color: badgeColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      icon: Icon(buttonIcon, size: 16),
                      label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: onAction,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
