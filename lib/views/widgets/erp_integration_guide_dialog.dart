import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class ErpIntegrationGuideDialog extends StatefulWidget {
  const ErpIntegrationGuideDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ErpIntegrationGuideDialog(),
    );
  }

  @override
  State<ErpIntegrationGuideDialog> createState() => _ErpIntegrationGuideDialogState();
}

class _ErpIntegrationGuideDialogState extends State<ErpIntegrationGuideDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        width: 800,
        height: 620,
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
                    color: AppColors.infoBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.plug, color: AppColors.infoBlue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Direct ERP Connector & Export Guide',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Step-by-step export instructions for Tally Prime, QuickBooks, SAP, Sage, and Odoo.',
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
            const SizedBox(height: 12),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.infoBlue,
              labelColor: AppColors.infoBlue,
              unselectedLabelColor: AppColors.textMuted,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(LucideIcons.fileCode, size: 16), text: 'Tally Prime (XML)'),
                Tab(icon: Icon(LucideIcons.fileSpreadsheet, size: 16), text: 'QuickBooks (CSV)'),
                Tab(icon: Icon(LucideIcons.database, size: 16), text: 'SAP Business One'),
                Tab(icon: Icon(LucideIcons.layers, size: 16), text: 'Sage / Pastel'),
                Tab(icon: Icon(LucideIcons.cpu, size: 16), text: 'Odoo ERP / Custom API'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab View Contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTallyGuide(),
                  _buildQuickBooksGuide(),
                  _buildSapGuide(),
                  _buildSageGuide(),
                  _buildOdooGuide(),
                ],
              ),
            ),

            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.shieldCheck, color: AppColors.mintAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Automated auto-parsing enabled in Reconix Ingestion Hub',
                      style: TextStyle(color: AppColors.mintAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.infoBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Got It'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTallyGuide() {
    return _buildGuideContent(
      title: 'Tally Prime XML Voucher Export',
      subtitle: 'Native XML data interchange dump directly parsed by Reconix ErpConnectorService.',
      steps: [
        'Open Tally Prime and navigate to Gateway of Tally -> Display More Reports -> Day Book.',
        'Press F2 to set the desired Tax Period date range (e.g. 01-08-2026 to 31-08-2026).',
        'Press Alt + E (Export) -> Select "Master" or "Transactions".',
        'Set Format to XML (Data Interchange) and File Name to tally_vouchers.xml.',
        'Open Reconix -> Ingestion Hub -> Click "Upload ERP Ledger" and select your .xml file. Reconix will automatically parse all vouchers!',
      ],
      codeSnippet: '''<!-- Example Tally XML Format Auto-Detected by Reconix -->
<TALLYMESSAGE xmlns:UDF="TallyUDF">
 <VOUCHER VCHTYPE="Purchase" ACTION="Create">
  <DATE>20260815</DATE>
  <VOUCHERNUMBER>PUR-2026-0042</VOUCHERNUMBER>
  <PARTYLEDGERNAME>Crown Paints Kenya PLC</PARTYLEDGERNAME>
  <PARTYGSTIN>P051123456Z</PARTYGSTIN>
  <AMOUNT>-116000.00</AMOUNT>
 </VOUCHER>
</TALLYMESSAGE>''',
    );
  }

  Widget _buildQuickBooksGuide() {
    return _buildGuideContent(
      title: 'QuickBooks Desktop / Online CSV Export',
      subtitle: 'Standard Purchase Detail or Expense Transaction export schedule.',
      steps: [
        'In QuickBooks, go to Reports -> Expenses & Vendors -> Transaction List by Vendor.',
        'Customize report columns to include: Date, Transaction Type, Num, Vendor Name, Tax PIN, Taxable Amount, VAT Amount.',
        'Filter by Date Range corresponding to the VAT return month.',
        'Click Export -> Export to Excel/CSV and save as quickbooks_purchases.csv.',
        'Upload into Reconix Ingestion Hub. Reconix maps headers automatically.',
      ],
      codeSnippet: '''Date,Type,Num,Vendor,Supplier PIN,Taxable Amount,VAT Amount,Total
15/08/2026,Bill,INV-9821,Safaricom PLC,P051111222A,50000.00,8000.00,58000.00
18/08/2026,Bill,INV-1092,KPLC Ltd,P051222333B,120000.00,19200.00,139200.00''',
    );
  }

  Widget _buildSapGuide() {
    return _buildGuideContent(
      title: 'SAP Business One / R3 Purchase Ledger',
      subtitle: 'Exporting OPCH / PCH1 Purchase Invoice tables.',
      steps: [
        'In SAP Business One, open Reports -> Purchasing -> Purchase Analysis.',
        'Or run SQL Query / SE16 on OPCH (A/P Invoice Header) table.',
        'Export result set with DocNum, CardCode, CardName, LicTradNum (KRA PIN), DocDate, VatSum, DocTotal.',
        'Save as CSV file and upload directly into Reconix.',
      ],
      codeSnippet: '''DocNum,DocDate,CardName,LicTradNum,VatSum,DocTotal
80012,2026-08-10,Bamburi Cement PLC,P051333444C,48000.00,348000.00''',
    );
  }

  Widget _buildSageGuide() {
    return _buildGuideContent(
      title: 'Sage 50 / Sage Evolution / Pastel',
      subtitle: 'Tax Box Detail / Supplier Audit Trail schedule export.',
      steps: [
        'Open Sage -> Suppliers -> Reports -> Supplier Audit Trail.',
        'Select Date range for the VAT period and include Tax Codes.',
        'Export as CSV / Excel spreadsheet.',
        'Ingest via Reconix Ingestion Hub under ERP Ledger.',
      ],
      codeSnippet: '''Account,Name,Tax PIN,Reference,Date,Net,Tax,Gross
SUP001,TotalEnergies Kenya,P051444555D,TOT-8891,12/08/2026,200000.00,16000.00,216000.00''',
    );
  }

  Widget _buildOdooGuide() {
    return _buildGuideContent(
      title: 'Odoo ERP & Custom REST API Webhooks',
      subtitle: 'Automated nightly sync via Reconix Webhook API or Odoo Vendor Bills export.',
      steps: [
        'Odoo UI: Go to Accounting -> Vendors -> Bills -> Select All -> Action -> Export as XLSX/CSV.',
        'Select fields: Number, Vendor/Name, Vendor/Vat (KRA PIN), Date, Untaxed Amount, Tax Amount, Total.',
        'API Automated Sync: Send a POST request from your server or Odoo cron job to Reconix API at http://localhost:8080/api/v1/ingest/erp.',
      ],
      codeSnippet: '''// Automated JSON POST Payload for Custom ERP Integration
POST /api/v1/ingest/erp
{
  "kra_pin": "P051999888Z",
  "invoices": [
    {
      "invoice_number": "OD-2026-091",
      "supplier_name": "Car & General PLC",
      "supplier_pin": "P051555666E",
      "invoice_date": "2026-08-20",
      "taxable_amount": 75000.00,
      "vat_amount": 12000.00,
      "total_amount": 87000.00,
      "etims_control_code": "KRA-ETIMS-2026-99120"
    }
  ]
}''',
    );
  }

  Widget _buildGuideContent({
    required String title,
    required String subtitle,
    required List<String> steps,
    required String codeSnippet,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          const Text('Step-by-Step Procedure:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.infoBlue)),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.infoBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Expected Sample Format:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.kraGold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: SelectableText(
              codeSnippet,
              style: const TextStyle(fontFamily: 'Monospace', fontSize: 11, color: AppColors.mintAccent, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
