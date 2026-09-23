import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class TaxLawCitation {
  final String actName;
  final String sectionNumber;
  final String title;
  final String verbatimExcerpt;
  final String practicalImpact;
  final String keyRequirement;

  const TaxLawCitation({
    required this.actName,
    required this.sectionNumber,
    required this.title,
    required this.verbatimExcerpt,
    required this.practicalImpact,
    required this.keyRequirement,
  });
}

class TaxLawReferenceDialog extends StatefulWidget {
  const TaxLawReferenceDialog({super.key});

  @override
  State<TaxLawReferenceDialog> createState() => _TaxLawReferenceDialogState();
}

class _TaxLawReferenceDialogState extends State<TaxLawReferenceDialog> {
  String _searchQuery = '';

  final List<TaxLawCitation> _citations = const [
    TaxLawCitation(
      actName: 'VAT Act 2013',
      sectionNumber: 'Section 17(1) & (2)',
      title: 'Conditions for Claiming Input Tax Deductions',
      verbatimExcerpt:
          'A registered person shall be allowed an input tax credit on taxable supply made to or imported by him where the tax was charged on a valid tax invoice issued in accordance with Section 42 or an electronic tax invoice generated via an electronic tax invoice management system (eTIMS/TIMS). Input tax credit must be claimed within six (6) months from the date of supply.',
      practicalImpact:
          'Input VAT claims are strictly barred if the supplier does not transmit an eTIMS QR control code or if claimed after the 6-month statutory window.',
      keyRequirement: '6-Month Claiming Window & eTIMS QR / Control Code Verification Required',
    ),
    TaxLawCitation(
      actName: 'Income Tax Act (Cap 470)',
      sectionNumber: 'Section 16(1) & Section 16(2)(ac)',
      title: 'Disallowance of Non-eTIMS Business Expenses (2026 Rule)',
      verbatimExcerpt:
          'In ascertaining the total income of any person for any year of income, no deduction shall be allowed in respect of expenditure or loss incurred in the production of income unless such expenditure or loss is supported by an electronic tax invoice generated through an electronic system established by the Commissioner (eTIMS / TIMS ETR).',
      practicalImpact:
          'Corporate tax deductions for corporate purchases are completely disallowed by KRA without eTIMS evidence, incurring a 30% Corporate Income Tax liability on gross purchases.',
      keyRequirement: '100% Expense Disallowance for Non-eTIMS Business Expenses',
    ),
    TaxLawCitation(
      actName: 'Tax Procedures Act 2015',
      sectionNumber: 'Section 23(1)',
      title: 'Record Keeping & Audit Trail Retention Mandate',
      verbatimExcerpt:
          'A person shall maintain documents and records required under a tax law in Kenya for a period of not less than five (5) years from the end of the reporting period to which they relate, and shall produce such records upon notice by the Commissioner.',
      practicalImpact:
          'Auditors and taxpayers must retain immutable 3-way reconciliation ledgers, supplier PIN verification logs, and SHA-256 evidence certificates for 5 years.',
      keyRequirement: '5-Year Immutable Digital Evidence & Ledger Retention',
    ),
    TaxLawCitation(
      actName: 'VAT Act 2013',
      sectionNumber: 'Section 42 & Sec 16(2)',
      title: 'VAA Automated Assessment & Penalty Provisions',
      verbatimExcerpt:
          'Where a discrepancy exists between input tax claimed by a purchaser and output tax declared by a seller in Section B schedules (VAT Automated Audit - VAA), the Commissioner shall issue a disallowance notice. Unresolved VAA discrepancies shall attract a 100% tax penalty and 1% monthly compounding interest.',
      practicalImpact:
          'Discrepancies lead to immediate automated VAA demand notices. Pre-filing 3-way reconciliation in Reconix blocks VAA notices before submission.',
      keyRequirement: 'Automated 100% VAA Disallowance Penalty & Interest Protection',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _citations.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.actName.toLowerCase().contains(q) ||
          c.sectionNumber.toLowerCase().contains(q) ||
          c.title.toLowerCase().contains(q) ||
          c.verbatimExcerpt.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Container(
        width: 780,
        height: 720,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.kraGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.scale, color: AppColors.kraGold, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Kenyan Tax Law Quick Reference & Citation Drawer',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Statutory provisions governing Input VAT, eTIMS compliance & VAA audit defense',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search Tax Acts, Section Numbers, or Legal Keywords...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Citations List
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, idx) {
                  final c = filtered[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.darkBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.kraGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c.actName,
                                    style: const TextStyle(color: AppColors.kraGold, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.sectionNumber,
                                  style: const TextStyle(color: AppColors.mintAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.copy, size: 16, color: AppColors.textMuted),
                              tooltip: 'Copy Citation Legal Text',
                              onPressed: () {
                                final textToCopy = '${c.actName} (${c.sectionNumber}) - ${c.title}:\n${c.verbatimExcerpt}';
                                Clipboard.setData(ClipboardData(text: textToCopy));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied legal citation text to clipboard!')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: Text(
                            '"${c.verbatimExcerpt}"',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.info, color: AppColors.infoBlue, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Practical Practitioner Impact: ${c.practicalImpact}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
