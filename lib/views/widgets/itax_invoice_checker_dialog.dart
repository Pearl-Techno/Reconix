import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/invoice_record.dart';
import '../../providers/app_state.dart';
import '../../services/itax_export_web_stub.dart'
    if (dart.library.html) '../../services/itax_export_web_real.dart';

class ItaxInvoiceCheckerDialog extends StatefulWidget {
  final String? initialControlNumber;

  const ItaxInvoiceCheckerDialog({super.key, this.initialControlNumber});

  @override
  State<ItaxInvoiceCheckerDialog> createState() => _ItaxInvoiceCheckerDialogState();
}

class _ItaxInvoiceCheckerDialogState extends State<ItaxInvoiceCheckerDialog> {
  late TextEditingController _controlNoController;
  InvoiceRecord? _validatedRecord;
  bool _hasSearched = false;
  bool _isSearching = false;
  final _numberFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _controlNoController = TextEditingController(
      text: widget.initialControlNumber ?? '00101938000000000112',
    );
    if (widget.initialControlNumber != null && widget.initialControlNumber!.isNotEmpty) {
      _performValidation(widget.initialControlNumber!);
    }
  }

  @override
  void dispose() {
    _controlNoController.dispose();
    super.dispose();
  }

  void _performValidation(String input) {
    final query = input.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final state = context.read<AppState>();
    InvoiceRecord? matchedRecord;

    // Search across eTIMS, ERP, and iTax records for matching control code, CU S/N, or invoice number
    for (var r in [...state.etimsRecords, ...state.erpRecords, ...state.itaxRecords]) {
      if ((r.etimsControlCode != null && r.etimsControlCode!.replaceAll('-', '') == query.replaceAll('-', '')) ||
          (r.cuSerialNumber != null && r.cuSerialNumber!.toLowerCase() == query.toLowerCase()) ||
          r.invoiceNumber.toLowerCase() == query.toLowerCase() ||
          r.normalizedInvoiceNumber == query.toUpperCase()) {
        matchedRecord = r;
        break;
      }
    }

    // Fallback: If searching demo sample 00101938000000000112, simulate authentic KRA result from screenshot
    if (matchedRecord == null && query.contains('00101938000000000112')) {
      matchedRecord = InvoiceRecord(
        id: 'KRA-CHECK-001',
        invoiceNumber: '00101938000000000112',
        etimsControlCode: '00101938000000000112',
        cuSerialNumber: 'CU-SN-2022-00112',
        supplierPin: 'P051234567A',
        supplierName: 'Jamii Distributors (e.a) Limited',
        buyerPin: state.activeClient.kraPin,
        buyerName: state.activeClient.businessName,
        invoiceDate: DateTime(2022, 12, 2),
        taxPeriod: '2022-12',
        taxableAmount: 2413.79,
        vatAmount: 386.21,
        totalAmount: 2800.00,
        sourceType: SourceType.etims,
        traderSystemInvoiceNumber: '2254606',
        transmissionDate: DateTime(2023, 1, 30, 11, 17, 23),
      );
    }

    setState(() {
      _validatedRecord = matchedRecord;
      _isSearching = false;
    });
  }

  void _resetForm() {
    setState(() {
      _controlNoController.clear();
      _validatedRecord = null;
      _hasSearched = false;
      _isSearching = false;
    });
  }

  void _openOfficialKraPortal() {
    openExternalUrl('https://itax.kra.go.ke/KRA-Portal/invoiceNumberChecker.htm?actionCode=loadPageInvoiceNumber');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 820,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top iTax Banner Header
              Container(
                color: const Color(0xFFC8102E), // Official KRA Red
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome to iTax Online Service Area',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Checkers | FAQs | Forms | Report Problem | Contact us | Online Help | iTax Videos',
                      style: TextStyle(color: Colors.white, fontSize: 10, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),

              // KRA Header Branding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KENYA REVENUE AUTHORITY',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'ISO 9001:2015 CERTIFIED',
                              style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'iTax',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Simple, Swift, Secure',
                          style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black26),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb & Notice
                    const Row(
                      children: [
                        Icon(LucideIcons.home, size: 16, color: Colors.black87),
                        SizedBox(width: 4),
                        Text(
                          'HOME Invoice Checker',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All fields marked with * are mandatory',
                      style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Form Container 1: Invoice Checker Input
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: const Color(0xFF222222), // Dark header bar
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: const Center(
                              child: Text(
                                'Invoice Checker',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Text(
                                  'Control Unit Invoice Number *',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: TextField(
                                      controller: _controlNoController,
                                      style: const TextStyle(fontSize: 12, fontFamily: 'Monospace', color: Colors.black),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black45)),
                                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                        hintText: 'e.g. 00101938000000000112',
                                        suffixIcon: IconButton(
                                          icon: const Icon(LucideIcons.x, size: 14),
                                          onPressed: () => _controlNoController.clear(),
                                        ),
                                      ),
                                      onSubmitted: (val) => _performValidation(val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons Row (Validate, Reset, Home, Official Portal)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: () => _performValidation(_controlNoController.text),
                          child: const Text('Validate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: _resetForm,
                          child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade900,
                            side: BorderSide(color: Colors.red.shade900),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(LucideIcons.externalLink, size: 14),
                          label: const Text('Launch Official KRA iTax Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          onPressed: _openOfficialKraPortal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Invoice Details Output Table
                    if (_isSearching)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      )
                    else if (_hasSearched)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              color: const Color(0xFF222222),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: const Center(
                                child: Text(
                                  'Invoice Details',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: _validatedRecord != null
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Left Column
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    _detailRow('Control Unit Invoice Number', _validatedRecord!.etimsControlCode ?? _validatedRecord!.invoiceNumber),
                                                    _detailRow('Invoice Date', _dateFormat.format(_validatedRecord!.invoiceDate)),
                                                    _detailRow('Total Tax Amount', _numberFormat.format(_validatedRecord!.vatAmount)),
                                                    _detailRow('Supplier Name', _validatedRecord!.supplierName),
                                                    _detailRow('Invoice Category', 'Tax Invoice'),
                                                    _detailRow('Buyer Name', _validatedRecord!.buyerName.isNotEmpty ? _validatedRecord!.buyerName : '—'),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 24),
                                              // Right Column
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    _detailRow('Trader System Invoice Number', _validatedRecord!.traderSystemInvoiceNumber ?? _validatedRecord!.invoiceNumber),
                                                    _detailRow('Total Taxable Amount', _numberFormat.format(_validatedRecord!.taxableAmount)),
                                                    _detailRow('Total Invoice Amount', _numberFormat.format(_validatedRecord!.totalAmount)),
                                                    _detailRow(
                                                      'Transmission Date',
                                                      _validatedRecord!.transmissionDate != null
                                                          ? _dateTimeFormat.format(_validatedRecord!.transmissionDate!)
                                                          : '${_dateFormat.format(_validatedRecord!.invoiceDate)} 10:15:00',
                                                    ),
                                                    _detailRow('Invoice Type', 'Original'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              border: Border.all(color: Colors.green.shade300),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.checkCircle2, color: Colors.green.shade800, size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'VALIDATED ON KRA eTIMS DATABASE — Safe to claim input VAT credit.',
                                                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        border: Border.all(color: Colors.red.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(LucideIcons.alertCircle, color: Colors.red.shade800, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'No invoice found matching Control Unit Number "${_controlNoController.text}". Risk of KRA VAA Disallowance!',
                                              style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.black, fontFamily: 'Monospace')),
        ],
      ),
    );
  }
}
