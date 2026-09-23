import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class UserGuideDialog extends StatefulWidget {
  const UserGuideDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UserGuideDialog(),
    );
  }

  @override
  State<UserGuideDialog> createState() => _UserGuideDialogState();
}

class _UserGuideDialogState extends State<UserGuideDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        width: 880,
        height: 660,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mintAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.bookOpen, color: AppColors.mintAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Reconix Official Comprehensive User Guide & Operational Manual',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'End-to-end operational guide for corporate finance teams, tax managers, and ICPAK auditors.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 8),

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.mintAccent,
              labelColor: AppColors.mintAccent,
              unselectedLabelColor: AppColors.textMuted,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(LucideIcons.play, size: 15), text: '1. Overview & Architecture'),
                Tab(icon: Icon(LucideIcons.gitCompare, size: 15), text: '2. 4-Step VAT Workflow'),
                Tab(icon: Icon(LucideIcons.fileSpreadsheet, size: 15), text: '3. iTax Form VAT 7 Bundles'),
                Tab(icon: Icon(LucideIcons.shieldAlert, size: 15), text: '4. WHVAT & Customs Import'),
                Tab(icon: Icon(LucideIcons.plug, size: 15), text: '5. ERP Connectors'),
                Tab(icon: Icon(LucideIcons.lock, size: 15), text: '6. Security & Audit Defense'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildWorkflowTab(),
                  _buildFilingBundlesTab(),
                  _buildWhvatCustomsTab(),
                  _buildErpTab(),
                  _buildSecurityAuditTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return _buildSectionContainer([
      _sectionHeader('1. Executive Overview & System Architecture'),
      _sectionBody(
        'Reconix is an enterprise-grade Kenyan VAT 3-Way Reconciliation & Audit Evidence Platform. '
        'It is designed to protect corporate taxpayers and audit firms from KRA VAA (VAT Automated Assessments) back-tax disallowances '
        'and Section 16(1) expense deductibility penalties.',
      ),
      const SizedBox(height: 12),
      _bulletPoint('3-Way Matching Engine: Reconciles internal ERP purchase registers against eTIMS server transmissions and KRA iTax pre-filled schedules.'),
      _bulletPoint('2% WHVAT Certificate Ledger: Matches 2% withholding certificates issued by appointed withholding agents against sales invoices.'),
      _bulletPoint('Customs Import C17 Entry Ledger: Reconciles SIMBA/ICMS C17 entries for Section C input VAT claims.'),
      _bulletPoint('KRA Penalty Simulator: Real-time statutory penalty and interest exposure calculator under Sec. 38, 83 & 84 of the Tax Procedures Act.'),
    ]);
  }

  Widget _buildWorkflowTab() {
    return _buildSectionContainer([
      _sectionHeader('2. Standard Operating Procedure (4-Step Monthly Workflow)'),
      _stepBox(
        stepNum: 'Step 1',
        title: 'Multi-Source Ingestion',
        description: 'Upload eTIMS CSV/Excel, ERP Purchase Ledger (Tally, QuickBooks, SAP, Sage, Odoo), and KRA Section B iTax CSVs in Ingestion Hub.',
      ),
      _stepBox(
        stepNum: 'Step 2',
        title: '3-Way Reconciliation',
        description: 'Review matched, timing latency, unclaimed input VAT, and VAA disallowance risk records in the 3-Way Matching Ledger.',
      ),
      _stepBox(
        stepNum: 'Step 3',
        title: 'Dispute Chasing & iTax Verification',
        description: 'Generate 1-click Email & WhatsApp chaser notices for missing eTIMS codes and verify suspicious invoices in live iTax Checker.',
      ),
      _stepBox(
        stepNum: 'Step 4',
        title: 'KRA Form VAT 7 Export & Audit Lock',
        description: 'Generate sanitized 4-in-1 filing schedules (Sections A, B, C, D), lock tax period (`is_locked = 1`), and export SHA-256 PDF Audit Defense Binders.',
      ),
    ]);
  }

  Widget _buildFilingBundlesTab() {
    return _buildSectionContainer([
      _sectionHeader('3. KRA iTax Form VAT 7 Filing Bundle Exporter'),
      _sectionBody(
        'Reconix exports a 4-in-1 sanitized CSV upload bundle tailored specifically for KRA iTax portal return schedules:',
      ),
      const SizedBox(height: 10),
      _bulletPoint('Section A (Output VAT Sales): Auto-formatted sales register schedule.'),
      _bulletPoint('Section B (Input VAT Purchases): Sanitized list containing ONLY 3-way verified claimable input VAT records, stripping disallowances to eliminate VAA audits.'),
      _bulletPoint('Section C (Customs Import VAT): Verified C17 entry schedules.'),
      _bulletPoint('Section D (2% WHVAT Credits): Reconciled 2% withholding VAT certificates.'),
    ]);
  }

  Widget _buildWhvatCustomsTab() {
    return _buildSectionContainer([
      _sectionHeader('4. 2% WHVAT & Customs Import C17 Ledgers'),
      _sectionBody(
        'Withholding VAT (WHVAT 2%) and Customs Import C17 entries are crucial components of Kenyan VAT returns.',
      ),
      const SizedBox(height: 10),
      _bulletPoint('WHVAT 2% Certificate Ledger: Ingest certificates issued by KCB, Equity, Safaricom, or government withholding agents. Match certificates to sales invoices to reduce net VAT payable.'),
      _bulletPoint('Customs C17 Import Ledger: Ingest SIMBA/ICMS C17 entries from Mombasa Port / JKIA Airport. Reconcile CIF value, duty paid, and 16% import VAT claimed.'),
    ]);
  }

  Widget _buildErpTab() {
    return _buildSectionContainer([
      _sectionHeader('5. Direct ERP Connectors & Integration Guide'),
      _sectionBody(
        'Reconix seamlessly ingests data from major enterprise accounting software:',
      ),
      const SizedBox(height: 10),
      _bulletPoint('Tally Prime: Native XML interchange parser (`parseTallyXml`). Reads `<VOUCHER>` tags directly.'),
      _bulletPoint('QuickBooks Desktop & Online: CSV parser (`parseQuickBooksCsv`). Automatically maps vendor PINs and tax amounts.'),
      _bulletPoint('SAP Business One & Sage: Ingests exported purchase registers and audit trails.'),
      _bulletPoint('Automated REST API Webhook: JSON endpoint (`/api/v1/ingest/erp`) for automated nightly sync.'),
    ]);
  }

  Widget _buildSecurityAuditTab() {
    return _buildSectionContainer([
      _sectionHeader('6. Security, RBAC Roles & Audit Defense Binders'),
      _sectionBody(
        'Built for strict corporate governance and compliance integrity:',
      ),
      const SizedBox(height: 10),
      _bulletPoint('Multi-User RBAC: `admin` (System Administrator / Senior Partner), `auditor` (ICPAK Certified External Auditor), `preparer` (Tax Accountant).'),
      _bulletPoint('Non-Mutable Audit Trail: Every match resolution, invoice edit, CSV export, and lock action is recorded in SQLite v5 with cryptographic SHA-256 hashes.'),
      _bulletPoint('Executive PDF & Excel Audit Packs: 1-click export of printable PDF Audit Defense Binders and multi-tab Excel workbooks for KRA tax defense.'),
      _bulletPoint('Database Backup & Restore: 1-click SQLite database snapshot creation (`.db`) for offline archiving.'),
    ]);
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _sectionBody(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5));
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.checkCircle2, color: AppColors.mintAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.4))),
        ],
      ),
    );
  }

  Widget _stepBox({required String stepNum, required String title, required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.mintAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(stepNum, style: const TextStyle(color: AppColors.mintAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
