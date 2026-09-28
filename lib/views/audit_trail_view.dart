import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AuditTrailView extends StatefulWidget {
  const AuditTrailView({super.key});

  @override
  State<AuditTrailView> createState() => _AuditTrailViewState();
}

class _AuditTrailViewState extends State<AuditTrailView> {
  String _search = '';
  String _selectedAction = 'ALL';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final logs = state.auditLogs;

    final filteredLogs = logs.where((log) {
      if (_selectedAction != 'ALL' && !log.action.contains(_selectedAction)) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return log.action.toLowerCase().contains(q) ||
            log.targetInvoiceKey.toLowerCase().contains(q) ||
            log.details.toLowerCase().contains(q) ||
            log.userName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SingleChildScrollView(
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
                    Row(
                      children: const [
                        Icon(LucideIcons.history, color: AppColors.mintAccent, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'System Audit Trail & Activity Log Inspector',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Non-repudiable log of practitioner actions, dataset ingestions, lock states, and export events.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.emeraldDark),
                  ),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.lock, color: AppColors.emeraldDark, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'SHA-256 IMMUTABLE LOG',
                        style: TextStyle(color: AppColors.emeraldDark, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search & Action Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _search = val.trim()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search audit trail by keyword, invoice key, user, or action...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textMuted),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.darkCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.mintAccent)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAction,
                      dropdownColor: AppColors.darkCard,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Actions')),
                        DropdownMenuItem(value: 'LOCK', child: Text('Lock & Unlock Actions')),
                        DropdownMenuItem(value: 'CLEAR', child: Text('Data Clear Events')),
                        DropdownMenuItem(value: 'BACKUP', child: Text('Backup / Restore')),
                        DropdownMenuItem(value: 'EXPORT', child: Text('File Exports')),
                      ],
                      onChanged: (v) => setState(() => _selectedAction = v ?? 'ALL'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Audit Logs Table Card
            Card(
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
                        const Text(
                          'Recorded Audit Trail Timeline',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${filteredLogs.length} Log Entries',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredLogs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(LucideIcons.history, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No Audit Logs Found',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'System actions will automatically be recorded into this audit log.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredLogs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.darkBorder),
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _actionColor(log.action).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_actionIcon(log.action), color: _actionColor(log.action), size: 16),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            log.action,
                                            style: TextStyle(
                                              color: _actionColor(log.action),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Monospace'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        log.details,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'User: ${log.userName} (${log.userRole.name})',
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                          ),
                                          if (log.targetInvoiceKey.isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            Text(
                                              'Target: ${log.targetInvoiceKey}',
                                              style: const TextStyle(color: AppColors.kraGold, fontSize: 11, fontFamily: 'Monospace'),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _actionColor(String action) {
    if (action.contains('LOCK')) return AppColors.crimsonRisk;
    if (action.contains('CLEAR')) return AppColors.kraGold;
    if (action.contains('BACKUP') || action.contains('RESTORE')) return AppColors.infoBlue;
    return AppColors.mintAccent;
  }

  IconData _actionIcon(String action) {
    if (action.contains('LOCK')) return LucideIcons.lock;
    if (action.contains('CLEAR')) return LucideIcons.trash2;
    if (action.contains('BACKUP')) return LucideIcons.database;
    return LucideIcons.checkCircle2;
  }
}
