import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'widgets/add_company_dialog.dart';

class AdvisorPortalView extends StatelessWidget {
  const AdvisorPortalView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final clients = state.advisorClients;
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tax Advisor & Multi-Client Practice Portal', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Multi-client management workspace for Kenyan tax agents, accounting firms, and CFO advisors.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldPrimary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: const Text('Add Taxpayer Client PIN'),
                onPressed: () => AddCompanyDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Advisor Portfolio Aggregate KPI Cards
          Row(
            children: [
              Expanded(
                child: _portfolioCard(
                  context,
                  title: 'Managed Client Portfolio',
                  value: '${clients.length} Taxpayers',
                  subtitle: 'August 2026 VAT 7 filing cycle',
                  icon: LucideIcons.building2,
                  color: AppColors.infoBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _portfolioCard(
                  context,
                  title: 'Total Input VAT Protected',
                  value: 'KES ${numberFormat.format(clients.fold(0.0, (sum, c) => sum + c.inputVatClaimable))}',
                  subtitle: 'Cleared across all client books',
                  icon: LucideIcons.shieldCheck,
                  color: AppColors.mintAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _portfolioCard(
                  context,
                  title: 'Aggregate VAA Exposure Risk',
                  value: 'KES ${numberFormat.format(clients.fold(0.0, (sum, c) => sum + c.inputVatAtRisk))}',
                  subtitle: 'Requires immediate practitioner intervention',
                  icon: LucideIcons.alertTriangle,
                  color: AppColors.crimsonRisk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Client Directory Ledger
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Taxpayer Client Readiness Directory', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(1.8),
                      3: FlexColumnWidth(1.8),
                      4: FlexColumnWidth(1.8),
                      5: FlexColumnWidth(1.5),
                      6: FlexColumnWidth(1.2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(6)),
                        children: [
                          _tableHeader('Taxpayer Name & KRA PIN'),
                          _tableHeader('Sector'),
                          _tableHeader('Purchases (KES)'),
                          _tableHeader('Claimable VAT'),
                          _tableHeader('VAT at Risk'),
                          _tableHeader('Readiness Status'),
                          _tableHeader('Action'),
                        ],
                      ),
                      ...clients.map((client) {
                        final isSelected = client.id == state.activeClient.id;
                        final statusColor = client.riskStatus == 'READY_TO_FILE'
                            ? AppColors.mintAccent
                            : (client.riskStatus == 'HIGH_RISK' ? AppColors.crimsonRisk : AppColors.warningOrange);

                        return TableRow(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.emeraldDark.withValues(alpha: 0.3) : null,
                            border: const Border(bottom: BorderSide(color: AppColors.darkBorder, width: 0.5)),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(client.businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                  Text('${client.kraPin} • ${client.vatRegistrationNo}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            _tableCell(client.sector),
                            _tableCell('KES ${numberFormat.format(client.totalMonthlyPurchases)}'),
                            _tableCell('KES ${numberFormat.format(client.inputVatClaimable)}', color: AppColors.mintAccent, isBold: true),
                            _tableCell('KES ${numberFormat.format(client.inputVatAtRisk)}', color: client.inputVatAtRisk > 0 ? AppColors.crimsonRisk : AppColors.textMuted, isBold: true),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                child: Text(client.riskStatus.replaceAll('_', ' '), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                child: Text(isSelected ? 'ACTIVE' : 'SELECT', style: TextStyle(fontSize: 11, color: isSelected ? AppColors.mintAccent : AppColors.textPrimary)),
                                onPressed: () {
                                  state.selectClient(client);
                                  state.setActiveTab(0); // Jump to dashboard
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _portfolioCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  static Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
    );
  }

  static Widget _tableCell(String text, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? AppColors.textPrimary,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
