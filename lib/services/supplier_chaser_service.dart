import '../models/reconciliation_match.dart';
import '../models/taxpayer_client.dart';

class SupplierChaserNotice {
  final String supplierName;
  final String supplierPin;
  final String supplierEmail;
  final String emailSubject;
  final String emailBody;
  final String whatsappMessage;

  const SupplierChaserNotice({
    required this.supplierName,
    required this.supplierPin,
    required this.supplierEmail,
    required this.emailSubject,
    required this.emailBody,
    required this.whatsappMessage,
  });
}

class SupplierChaserService {
  /// Generates pre-populated email & WhatsApp chaser notices for defaulting suppliers
  static SupplierChaserNotice generateNotice({
    required TaxpayerClient client,
    required List<ReconciliationMatch> supplierDiscrepancies,
  }) {
    if (supplierDiscrepancies.isEmpty) {
      throw ArgumentError('Supplier discrepancies list cannot be empty.');
    }

    final primary = supplierDiscrepancies.first;
    final supplierName = primary.supplierName;
    final supplierPin = primary.supplierPin;
    final supplierEmail = primary.erpRecord?.supplierContactEmail ?? 'accounts@${supplierName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.co.ke';

    final invoiceNumbers = supplierDiscrepancies.map((m) => m.invoiceNumber).join(', ');
    final totalVatAtRisk = supplierDiscrepancies.fold(0.0, (sum, m) => sum + m.claimableVatAtRisk);
    final totalTaxableAtRisk = supplierDiscrepancies.fold(0.0, (sum, m) => sum + (m.erpRecord?.taxableAmount ?? 0.0));

    final emailSubject = 'URGENT: Missing eTIMS Tax Invoice Confirmation - ${client.businessName} (Tax Period: ${client.currentTaxPeriod})';

    final emailBody = '''
Dear Accounts Payable / Tax Compliance Manager,
${supplierName.toUpperCase()} (KRA PIN: $supplierPin)

RE: URGENT REQUEST FOR eTIMS CONTROL CODES / RE-TRANSMISSION FOR INVOICE(S): $invoiceNumbers

We are writing from the Finance & Tax Compliance Department at ${client.businessName} (KRA PIN: ${client.kraPin}).

During our monthly 3-Way VAT Reconciliation audit for tax period ${client.currentTaxPeriod}, our automated compliance platform (Reconix) flagged the following invoice(s) booked in our accounting ledger which have NOT auto-populated on our KRA iTax Section B return or lack valid eTIMS transmission control codes:

Invoices Flagged:
- Invoice Reference(s): $invoiceNumbers
- Total Taxable Value: KES ${totalTaxableAtRisk.toStringAsFixed(2)}
- Total Input VAT Credit at Risk: KES ${totalVatAtRisk.toStringAsFixed(2)}

STATUTORY COMPLIANCE NOTICE:
1. KRA VAA Penalties: Claiming input VAT without a valid eTIMS transmitted invoice triggers KRA Value Added Automated Audit (VAA) disallowance, subjecting our company to 100% input VAT penalties and statutory interest.
2. Section 16(1) Corp Tax Disallowance: Under the 2026 Tax Laws Amendment, Corporate Income Tax expense deductions (30% tax rate) are strictly disallowed for any business expense lacking a valid eTIMS QR control code.

REQUIRED ACTION WITHIN 48 HOURS:
Please reply to this email (${client.contactEmail}) with:
1. The valid eTIMS Electronic Control Code / QR Verification URL for invoice(s) $invoiceNumbers.
2. OR transmit the electronic tax invoice via your eTIMS/TIMS ETR device immediately so KRA auto-populates our return.

Thank you for your prompt cooperation.

Best regards,

Finance & Tax Advisory Department
${client.businessName}
Contact Email: ${client.contactEmail}
Generated via Reconix Tax Evidence Platform
''';

    final rawWhatsapp = '⚠️ *URGENT TAX NOTICE - ${client.businessName}*\n\n'
        'Dear $supplierName (PIN: $supplierPin),\n'
        'Our monthly KRA VAT audit flagged missing eTIMS control codes for invoice(s): *$invoiceNumbers* (VAT at risk: KES ${totalVatAtRisk.toStringAsFixed(2)}).\n\n'
        'Please send the valid eTIMS Control Code / QR URL to ${client.contactEmail} within 48 hours to prevent KRA VAA disallowance.\n\n'
        'Thank you!';

    return SupplierChaserNotice(
      supplierName: supplierName,
      supplierPin: supplierPin,
      supplierEmail: supplierEmail,
      emailSubject: emailSubject,
      emailBody: emailBody,
      whatsappMessage: rawWhatsapp,
    );
  }
}
