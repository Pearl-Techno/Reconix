import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/taxpayer_client.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

import 'getting_started_view.dart';
import 'dashboard_view.dart';
import 'reconciliation_view.dart';
import 'whvat_reconciliation_view.dart';
import 'historical_trend_view.dart';
import 'ingestion_view.dart';
import 'evidence_pack_view.dart';
import 'advisor_portal_view.dart';
import 'supplier_risk_view.dart';
import 'tax_exposure_calculator_view.dart';
import 'settings_view.dart';
import 'widgets/add_company_dialog.dart';
import 'widgets/itax_invoice_checker_dialog.dart';
import 'widgets/tax_law_reference_dialog.dart';
import 'widgets/itax_filing_bundle_dialog.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final views = [
      const GettingStartedView(),
      const DashboardView(),
      const ReconciliationView(),
      const WhvatReconciliationView(),
      const HistoricalTrendView(),
      const IngestionView(),
      SupplierRiskView(matches: state.reconciliationResults),
      const TaxExposureCalculatorView(),
      const EvidencePackView(),
      const AdvisorPortalView(),
      SettingsView(
        currentRules: state.rules,
        onRulesSaved: (newRules) => state.updateRules(newRules),
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar Container
          Container(
            width: 270,
            color: AppColors.darkSidebar,
            child: Column(
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldPrimary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintAccent.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.shieldAlert, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'RECONIX',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.kraGold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'KENYA',
                                  style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'eTIMS-ERP VAT Evidence',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Client Selector Widget
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE TAXPAYER CONTEXT',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.darkBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Builder(
                          builder: (context) {
                            final allClients = [
                              if (!state.advisorClients.any((c) => c.id == state.activeClient.id)) state.activeClient,
                              ...state.advisorClients,
                            ];

                            return DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: state.activeClient.id,
                                isExpanded: true,
                                dropdownColor: AppColors.darkCard,
                                icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textSecondary),
                                items: allClients.map((client) {
                                  return DropdownMenuItem<String>(
                                    value: client.id,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          client.businessName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'PIN: ${client.kraPin}',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (selectedId) {
                                  if (selectedId != null) {
                                    final found = allClients.firstWhere((c) => c.id == selectedId);
                                    state.selectClient(found);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => AddCompanyDialog.show(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.mintAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.plusCircle, color: AppColors.mintAccent, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Register New Company',
                                style: TextStyle(color: AppColors.mintAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      _navItem(
                        context,
                        index: 0,
                        title: 'Workflow & Guide',
                        icon: LucideIcons.playCircle,
                        activeTab: state.activeTab,
                        badge: 'START',
                        badgeColor: AppColors.mintAccent,
                      ),
                      _navItem(
                        context,
                        index: 1,
                        title: 'Executive Dashboard',
                        icon: LucideIcons.layoutDashboard,
                        activeTab: state.activeTab,
                      ),
                      _navItem(
                        context,
                        index: 2,
                        title: '3-Way VAT Ledger',
                        icon: LucideIcons.columns,
                        activeTab: state.activeTab,
                        badge: '${state.reconciliationResults.length}',
                      ),
                      _navItem(
                        context,
                        index: 3,
                        title: '2% WHVAT Ledger',
                        icon: LucideIcons.fileCheck,
                        activeTab: state.activeTab,
                        badge: '${state.whvatRecords.length}',
                        badgeColor: AppColors.kraGold,
                      ),
                      _navItem(
                        context,
                        index: 4,
                        title: 'Multi-Period Analytics',
                        icon: LucideIcons.barChart2,
                        activeTab: state.activeTab,
                        badge: 'TRENDS',
                        badgeColor: AppColors.infoBlue,
                      ),
                      _navItem(
                        context,
                        index: 5,
                        title: 'Data Ingestion Hub',
                        icon: LucideIcons.uploadCloud,
                        activeTab: state.activeTab,
                      ),
                      _navItem(
                        context,
                        index: 6,
                        title: 'Supplier Risk Hub',
                        icon: LucideIcons.shieldAlert,
                        activeTab: state.activeTab,
                        badge: 'VAA RISK',
                        badgeColor: AppColors.kraGold,
                      ),
                      _navItem(
                        context,
                        index: 7,
                        title: 'CIT 30% Tax Exposure',
                        icon: LucideIcons.calculator,
                        activeTab: state.activeTab,
                      ),
                      _navItem(
                        context,
                        index: 8,
                        title: 'Audit Evidence Packs',
                        icon: LucideIcons.fileCheck2,
                        activeTab: state.activeTab,
                        badge: 'PDF',
                        badgeColor: AppColors.kraGold,
                      ),
                      _navItem(
                        context,
                        index: 9,
                        title: 'Advisor Multi-Client',
                        icon: LucideIcons.users,
                        activeTab: state.activeTab,
                        badge: '${state.advisorClients.length}',
                        badgeColor: AppColors.infoBlue,
                      ),
                      _navItem(
                        context,
                        index: 10,
                        title: 'Rules & Settings',
                        icon: LucideIcons.settings,
                        activeTab: state.activeTab,
                      ),
                    ],
                  ),
                ),

                // Sidebar Footer Filing Countdown
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.clock, color: AppColors.kraGold, size: 14),
                          SizedBox(width: 6),
                          Text('20TH DEADLINE TIMER', style: TextStyle(color: AppColors.kraGold, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text('August 2026 Return', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('8 Days Remaining to File', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),

          // Main View Area with Top App Bar Header
          Expanded(
            child: Column(
              children: [
                // Top App Shell Header Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.darkCard,
                    border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Active Entity Info (Interactive Client Switcher Dropdown)
                      Flexible(
                        child: PopupMenuButton<dynamic>(
                          color: AppColors.darkCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.darkBorder),
                          ),
                          onSelected: (value) async {
                            if (value is TaxpayerClient) {
                              await state.selectClient(value);
                            } else if (value == 'ADD_NEW') {
                              showDialog(
                                context: context,
                                builder: (context) => const AddCompanyDialog(),
                              );
                            }
                          },
                          itemBuilder: (context) {
                            return [
                              const PopupMenuItem<dynamic>(
                                enabled: false,
                                child: Text(
                                  'SELECT TAXPAYER ENTITY',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.kraGold),
                                ),
                              ),
                              ...state.advisorClients.map((client) {
                                final isSelected = client.id == state.activeClient.id;
                                return PopupMenuItem<dynamic>(
                                  value: client,
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? LucideIcons.checkCircle2 : LucideIcons.building2,
                                        size: 16,
                                        color: isSelected ? AppColors.mintAccent : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              client.businessName,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'PIN: ${client.kraPin}',
                                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'Monospace'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const PopupMenuDivider(),
                              const PopupMenuItem<dynamic>(
                                value: 'ADD_NEW',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.plusCircle, size: 16, color: AppColors.mintAccent),
                                    SizedBox(width: 8),
                                    Text('+ Add New Taxpayer Entity', style: TextStyle(color: AppColors.mintAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ];
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.darkBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.building2, color: AppColors.mintAccent, size: 16),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    state.activeClient.businessName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.darkBorder),
                                  ),
                                  child: Text(
                                    'PIN: ${state.activeClient.kraPin}',
                                    style: const TextStyle(color: AppColors.kraGold, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.chevronDown, color: AppColors.textMuted, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right-hand header action controls
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.kraGold,
                                  side: const BorderSide(color: AppColors.kraGold),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                                label: const Text('KRA VAT 7 Filing Bundle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  ITaxFilingBundleDialog.show(context);
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.kraGold,
                                  side: const BorderSide(color: AppColors.kraGold),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(LucideIcons.scale, size: 14),
                                label: const Text('Kenyan Tax Laws', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const TaxLawReferenceDialog(),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.mintAccent,
                                  side: const BorderSide(color: AppColors.mintAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(LucideIcons.shieldCheck, size: 14),
                                label: const Text('iTax Invoice Checker', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const ItaxInvoiceCheckerDialog(),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              // Data Mode Switcher Widget (Demo vs Live SQLite)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.darkBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.darkBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => state.setDataMode(DataMode.demo),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: state.dataMode == DataMode.demo ? AppColors.kraGold : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              LucideIcons.sparkles,
                                              size: 13,
                                              color: state.dataMode == DataMode.demo ? Colors.black : AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'DEMO MODE',
                                              style: TextStyle(
                                                color: state.dataMode == DataMode.demo ? Colors.black : AppColors.textMuted,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => state.setDataMode(DataMode.live),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: state.dataMode == DataMode.live ? AppColors.mintAccent : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              LucideIcons.database,
                                              size: 13,
                                              color: state.dataMode == DataMode.live ? Colors.black : AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'LIVE SQLITE DATA',
                                              style: TextStyle(
                                                color: state.dataMode == DataMode.live ? Colors.black : AppColors.textMuted,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  ),
                ),

                // Main View Body
                Expanded(
                  child: views[state.activeTab],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required int index,
    required String title,
    required IconData icon,
    required int activeTab,
    String? badge,
    Color badgeColor = AppColors.mintAccent,
  }) {
    final isSelected = activeTab == index;
    final state = context.read<AppState>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => state.setActiveTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.emeraldPrimary.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.mintAccent.withValues(alpha: 0.4) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.mintAccent : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
