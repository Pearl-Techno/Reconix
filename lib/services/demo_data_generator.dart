import '../models/invoice_record.dart';
import '../models/taxpayer_client.dart';

class DemoDataSet {
  final TaxpayerClient client;
  final List<InvoiceRecord> erpRecords;
  final List<InvoiceRecord> etimsRecords;
  final List<InvoiceRecord> itaxRecords;

  const DemoDataSet({
    required this.client,
    required this.erpRecords,
    required this.etimsRecords,
    required this.itaxRecords,
  });
}

class DemoDataGenerator {
  /// Primary realistic scenario: Apex Logistics Kenya Ltd
  static DemoDataSet generateApexLogistics() {
    final client = TaxpayerClient(
      id: 'CLI-001',
      businessName: 'Apex Logistics Kenya Ltd',
      kraPin: 'P051284920A',
      vatRegistrationNo: 'VAT-051284920',
      sector: 'Freight & Logistics',
      contactEmail: 'tax.finance@apexlogistics.co.ke',
      isAdvisorClient: true,
      riskStatus: 'ACTION_REQUIRED',
      currentTaxPeriod: 'August 2026',
      totalMonthlyPurchases: 14850000.0,
      inputVatClaimable: 2048000.0,
      inputVatAtRisk: 485000.0,
      totalInvoicesCount: 14,
      matchedInvoicesCount: 8,
    );

    final String period = '2026-08';
    final String buyerPin = client.kraPin;
    final String buyerName = client.businessName;

    final List<InvoiceRecord> erp = [
      // 1. Matched Safaricom
      InvoiceRecord(
        id: 'ERP-001',
        invoiceNumber: 'INV-SAF-8821',
        etimsControlCode: '011020260815000192',
        cuSerialNumber: 'KRA0192384-01',
        supplierPin: 'P0511192931Z',
        supplierName: 'Safaricom PLC',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 4),
        taxPeriod: period,
        taxableAmount: 450000.0,
        vatAmount: 72000.0,
        totalAmount: 522000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
      ),
      // 2. Matched Kenya Power
      InvoiceRecord(
        id: 'ERP-002',
        invoiceNumber: 'KPLC-2026-9912',
        etimsControlCode: '011020260812009823',
        cuSerialNumber: 'KRA0882194-04',
        supplierPin: 'P051101992A',
        supplierName: 'Kenya Power & Lighting Co.',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 8),
        taxPeriod: period,
        taxableAmount: 1250000.0,
        vatAmount: 200000.0,
        totalAmount: 1450000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
      ),
      // 3. Matched Fuel (TotalEnergies 8% VAT)
      InvoiceRecord(
        id: 'ERP-003',
        invoiceNumber: 'TOT-KEN-4402',
        etimsControlCode: '011020260818004411',
        cuSerialNumber: 'KRA0112349-02',
        supplierPin: 'P051188392X',
        supplierName: 'TotalEnergies Marketing Kenya',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 12),
        taxPeriod: period,
        taxableAmount: 3200000.0,
        vatAmount: 256000.0, // 8% fuel tax
        totalAmount: 3456000.0,
        vatRate: 0.08,
        sourceType: SourceType.erp,
      ),
      // 4. Timing Latency (Crown Paints) - eTIMS sent Aug 25th, missing in iTax
      InvoiceRecord(
        id: 'ERP-004',
        invoiceNumber: 'CPK-9021-AUG',
        etimsControlCode: '011020260825007722',
        cuSerialNumber: 'KRA0449102-01',
        supplierPin: 'P051229910C',
        supplierName: 'Crown Paints Kenya PLC',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 25),
        taxPeriod: period,
        taxableAmount: 850000.0,
        vatAmount: 136000.0,
        totalAmount: 986000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
      ),
      // 5. Unclaimed Input VAT Risk (Bamburi Cement) - In ERP & eTIMS, missing in iTax return
      InvoiceRecord(
        id: 'ERP-005',
        invoiceNumber: 'BMB-88391',
        etimsControlCode: '011020260810003310',
        cuSerialNumber: 'KRA0993182-03',
        supplierPin: 'P051139011B',
        supplierName: 'Bamburi Cement PLC',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: period,
        taxableAmount: 2100000.0,
        vatAmount: 336000.0,
        totalAmount: 2436000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
      ),
      // 6. VAA Disallowance Exposure (Quickmart) - Booked in ERP, no eTIMS code
      InvoiceRecord(
        id: 'ERP-006',
        invoiceNumber: 'QKM-2026-1102',
        etimsControlCode: null,
        cuSerialNumber: null,
        supplierPin: 'P051992019Q',
        supplierName: 'Quickmart Supermarkets Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 14),
        taxPeriod: period,
        taxableAmount: 620000.0,
        vatAmount: 99200.0,
        totalAmount: 719200.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
      ),
      // 7. 2026 Expense Deductibility Risk (TechSolutions) - Booked without eTIMS, exempt VAT
      InvoiceRecord(
        id: 'ERP-007',
        invoiceNumber: 'TSK-EXP-4401',
        etimsControlCode: null,
        cuSerialNumber: null,
        supplierPin: 'P051887210T',
        supplierName: 'TechSolutions Kenya Consultancy',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 19),
        taxPeriod: period,
        taxableAmount: 1150000.0,
        vatAmount: 0.0, // Non-VAT registered expense
        totalAmount: 1150000.0,
        vatRate: 0.0,
        sourceType: SourceType.erp,
      ),
      // 8. Amount Variance (AutoXpress Kenya)
      InvoiceRecord(
        id: 'ERP-008',
        invoiceNumber: 'AXP-NBI-3321',
        etimsControlCode: '011020260816005510',
        cuSerialNumber: 'KRA0228194-01',
        supplierPin: 'P051177209A',
        supplierName: 'AutoXpress Kenya Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 16),
        taxPeriod: period,
        taxableAmount: 480000.0,
        vatAmount: 76800.0,
        totalAmount: 556800.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
      ),
    ];

    final List<InvoiceRecord> etims = [
      // 1. Safaricom
      InvoiceRecord(
        id: 'ETM-001',
        invoiceNumber: 'INV-SAF-8821',
        etimsControlCode: '011020260815000192',
        cuSerialNumber: 'KRA0192384-01',
        supplierPin: 'P0511192931Z',
        supplierName: 'Safaricom PLC',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 4),
        taxPeriod: period,
        taxableAmount: 450000.0,
        vatAmount: 72000.0,
        totalAmount: 522000.0,
        vatRate: 0.16,
        sourceType: SourceType.etims,
      ),
      // 2. Kenya Power
      InvoiceRecord(
        id: 'ETM-002',
        invoiceNumber: 'KPLC-2026-9912',
        etimsControlCode: '011020260812009823',
        cuSerialNumber: 'KRA0882194-04',
        supplierPin: 'P051101992A',
        supplierName: 'Kenya Power & Lighting Co.',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 8),
        taxPeriod: period,
        taxableAmount: 1250000.0,
        vatAmount: 200000.0,
        totalAmount: 1450000.0,
        vatRate: 0.16,
        sourceType: SourceType.etims,
      ),
      // 3. TotalEnergies
      InvoiceRecord(
        id: 'ETM-003',
        invoiceNumber: 'TOT-KEN-4402',
        etimsControlCode: '011020260818004411',
        cuSerialNumber: 'KRA0112349-02',
        supplierPin: 'P051188392X',
        supplierName: 'TotalEnergies Marketing Kenya',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 12),
        taxPeriod: period,
        taxableAmount: 3200000.0,
        vatAmount: 256000.0,
        totalAmount: 3456000.0,
        vatRate: 0.08,
        sourceType: SourceType.etims,
      ),
      // 4. Crown Paints (transmitted on eTIMS)
      InvoiceRecord(
        id: 'ETM-004',
        invoiceNumber: 'CPK-9021-AUG',
        etimsControlCode: '011020260825007722',
        cuSerialNumber: 'KRA0449102-01',
        supplierPin: 'P051229910C',
        supplierName: 'Crown Paints Kenya PLC',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 25),
        taxPeriod: period,
        taxableAmount: 850000.0,
        vatAmount: 136000.0,
        totalAmount: 986000.0,
        vatRate: 0.16,
        sourceType: SourceType.etims,
      ),
      // 5. Bamburi Cement (transmitted on eTIMS)
      InvoiceRecord(
        id: 'ETM-005',
        invoiceNumber: 'BMB-88391',
        etimsControlCode: '011020260810003310',
        cuSerialNumber: 'KRA0993182-03',
        supplierPin: 'P051139011B',
        supplierName: 'Bamburi Cement PLC',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 10),
        taxPeriod: period,
        taxableAmount: 2100000.0,
        vatAmount: 336000.0,
        totalAmount: 2436000.0,
        vatRate: 0.16,
        sourceType: SourceType.etims,
      ),
      // 8. AutoXpress (eTIMS shows KES 500,000 instead of 480,000)
      InvoiceRecord(
        id: 'ETM-008',
        invoiceNumber: 'AXP-NBI-3321',
        etimsControlCode: '011020260816005510',
        cuSerialNumber: 'KRA0228194-01',
        supplierPin: 'P051177209A',
        supplierName: 'AutoXpress Kenya Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 16),
        taxPeriod: period,
        taxableAmount: 500000.0,
        vatAmount: 80000.0,
        totalAmount: 580000.0,
        vatRate: 0.16,
        sourceType: SourceType.etims,
      ),
      // 9. Unmatched eTIMS Only (Toyota Kenya - fleet service transmitted under PIN, unbooked)
      InvoiceRecord(
        id: 'ETM-009',
        invoiceNumber: 'TYT-MSA-1109',
        etimsControlCode: '011020260822008819',
        cuSerialNumber: 'KRA0771829-01',
        supplierPin: 'P051199201T',
        supplierName: 'Toyota Kenya Ltd (CFAO Motors)',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 22),
        taxPeriod: period,
        taxableAmount: 750000.0,
        vatAmount: 120000.0,
        totalAmount: 870000.0,
        vatRate: 0.16,
        sourceType: SourceType.etims,
      ),
    ];

    final List<InvoiceRecord> itax = [
      // 1. Safaricom
      InvoiceRecord(
        id: 'ITX-001',
        invoiceNumber: 'INV-SAF-8821',
        etimsControlCode: '011020260815000192',
        cuSerialNumber: 'KRA0192384-01',
        supplierPin: 'P0511192931Z',
        supplierName: 'Safaricom PLC',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 4),
        taxPeriod: period,
        taxableAmount: 450000.0,
        vatAmount: 72000.0,
        totalAmount: 522000.0,
        vatRate: 0.16,
        sourceType: SourceType.itax,
      ),
      // 2. Kenya Power
      InvoiceRecord(
        id: 'ITX-002',
        invoiceNumber: 'KPLC-2026-9912',
        etimsControlCode: '011020260812009823',
        cuSerialNumber: 'KRA0882194-04',
        supplierPin: 'P051101992A',
        supplierName: 'Kenya Power & Lighting Co.',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 8),
        taxPeriod: period,
        taxableAmount: 1250000.0,
        vatAmount: 200000.0,
        totalAmount: 1450000.0,
        vatRate: 0.16,
        sourceType: SourceType.itax,
      ),
      // 3. TotalEnergies
      InvoiceRecord(
        id: 'ITX-003',
        invoiceNumber: 'TOT-KEN-4402',
        etimsControlCode: '011020260818004411',
        cuSerialNumber: 'KRA0112349-02',
        supplierPin: 'P051188392X',
        supplierName: 'TotalEnergies Marketing Kenya',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 12),
        taxPeriod: period,
        taxableAmount: 3200000.0,
        vatAmount: 256000.0,
        totalAmount: 3456000.0,
        vatRate: 0.08,
        sourceType: SourceType.itax,
      ),
      // 8. AutoXpress (matches eTIMS version)
      InvoiceRecord(
        id: 'ITX-008',
        invoiceNumber: 'AXP-NBI-3321',
        etimsControlCode: '011020260816005510',
        cuSerialNumber: 'KRA0228194-01',
        supplierPin: 'P051177209A',
        supplierName: 'AutoXpress Kenya Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 16),
        taxPeriod: period,
        taxableAmount: 500000.0,
        vatAmount: 80000.0,
        totalAmount: 580000.0,
        vatRate: 0.16,
        sourceType: SourceType.itax,
      ),
    ];

    return DemoDataSet(
      client: client,
      erpRecords: erp,
      etimsRecords: etims,
      itaxRecords: itax,
    );
  }

  /// Scenario 2: Nairobi Commercial Retailers Ltd (High VAA Exposure Risk)
  static DemoDataSet generateNairobiRetailers() {
    final client = getAdvisorClients()[1]; // Nairobi Commercial Retailers Ltd
    final String period = '2026-08';
    final String buyerPin = client.kraPin;
    final String buyerName = client.businessName;

    final List<InvoiceRecord> erp = [
      InvoiceRecord(
        id: 'NR-ERP-001',
        invoiceNumber: 'BDC-NBI-1002',
        etimsControlCode: '011020260802001192',
        cuSerialNumber: 'KRA0991823-01',
        supplierPin: 'P051188291A',
        supplierName: 'Bidco Africa Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 2),
        taxPeriod: period,
        taxableAmount: 4800000.0,
        vatAmount: 768000.0,
        totalAmount: 5568000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
        sectionType: SectionType.sectionBPurchases,
      ),
      InvoiceRecord(
        id: 'NR-ERP-002',
        invoiceNumber: 'ULV-KEN-9921',
        etimsControlCode: '011020260806004410',
        cuSerialNumber: 'KRA0881920-02',
        supplierPin: 'P051177290B',
        supplierName: 'Unilever Kenya Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 6),
        taxPeriod: period,
        taxableAmount: 6200000.0,
        vatAmount: 992000.0,
        totalAmount: 7192000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
        sectionType: SectionType.sectionBPurchases,
      ),
      InvoiceRecord(
        id: 'NR-ERP-003',
        invoiceNumber: 'BRK-DAIRY-3310',
        etimsControlCode: null, // VAA Risk
        cuSerialNumber: null,
        supplierPin: 'P051299381C',
        supplierName: 'Brookside Dairy Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 14),
        taxPeriod: period,
        taxableAmount: 3903125.0,
        vatAmount: 624500.0,
        totalAmount: 4527625.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
        sectionType: SectionType.sectionBPurchases,
      ),
    ];

    final List<InvoiceRecord> etims = [
      InvoiceRecord(
        id: 'NR-ETM-001',
        invoiceNumber: 'BDC-NBI-1002',
        etimsControlCode: '011020260802001192',
        cuSerialNumber: 'KRA0991823-01',
        supplierPin: 'P051188291A',
        supplierName: 'Bidco Africa Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 2),
        taxPeriod: period,
        taxableAmount: 4800000.0,
        vatAmount: 768000.0,
        totalAmount: 5568000.0,
        vatRate: 0.16,
        sourceType: SourceType.etims,
        sectionType: SectionType.sectionBPurchases,
      ),
      InvoiceRecord(
        id: 'NR-ETM-002',
        invoiceNumber: 'ULV-KEN-9921',
        etimsControlCode: '011020260806004410',
        cuSerialNumber: 'KRA0881920-02',
        supplierPin: 'P051177290B',
        supplierName: 'Unilever Kenya Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 6),
        taxPeriod: period,
        taxableAmount: 6200000.0,
        vatAmount: 992000.0,
        totalAmount: 7192000.0,
        vatRate: 0.16,
        sourceType: SourceType.etims,
        sectionType: SectionType.sectionBPurchases,
      ),
    ];

    final List<InvoiceRecord> itax = List.from(etims);

    return DemoDataSet(
      client: client,
      erpRecords: erp,
      etimsRecords: etims,
      itaxRecords: itax,
    );
  }

  /// Scenario 3: Rift Valley Agriculture Exporters (100% Clean Baseline)
  static DemoDataSet generateRiftValleyAgri() {
    final client = getAdvisorClients()[2]; // Rift Valley Agriculture Exporters
    final String period = '2026-08';
    final String buyerPin = client.kraPin;
    final String buyerName = client.businessName;

    final List<InvoiceRecord> erp = [
      InvoiceRecord(
        id: 'RVA-ERP-001',
        invoiceNumber: 'TEA-EXP-2026-01',
        etimsControlCode: '011020260801009988',
        cuSerialNumber: 'KRA0551928-01',
        supplierPin: 'P051339920K',
        supplierName: 'Kenya Tea Packers (KETEPA)',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 3),
        taxPeriod: period,
        taxableAmount: 9450000.0,
        vatAmount: 0.0, // Zero rated export Category B
        totalAmount: 9450000.0,
        vatRate: 0.0,
        sourceType: SourceType.erp,
        taxClassification: TaxClassification.zeroRated,
        sectionType: SectionType.sectionASales,
      ),
      InvoiceRecord(
        id: 'RVA-ERP-002',
        invoiceNumber: 'YARA-FERT-8821',
        etimsControlCode: '011020260805004419',
        cuSerialNumber: 'KRA0662819-02',
        supplierPin: 'P051449910Y',
        supplierName: 'Yara East Africa Fertilizers',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 7),
        taxPeriod: period,
        taxableAmount: 9450000.0,
        vatAmount: 1512000.0,
        totalAmount: 10962000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
        sectionType: SectionType.sectionBPurchases,
      ),
    ];

    final List<InvoiceRecord> etims = List.from(erp);
    final List<InvoiceRecord> itax = List.from(erp);

    return DemoDataSet(
      client: client,
      erpRecords: erp,
      etimsRecords: etims,
      itaxRecords: itax,
    );
  }

  /// Scenario 4: Coastline Hospitality & Resorts Group
  static DemoDataSet generateCoastlineHospitality() {
    final client = getAdvisorClients()[3]; // Coastline Hospitality
    final String period = '2026-08';
    final String buyerPin = client.kraPin;
    final String buyerName = client.businessName;

    final List<InvoiceRecord> erp = [
      InvoiceRecord(
        id: 'CH-ERP-001',
        invoiceNumber: 'MSA-HOTEL-4401',
        etimsControlCode: '011020260804008812',
        cuSerialNumber: 'KRA0773910-01',
        supplierPin: 'P051662910M',
        supplierName: 'Mombasa Linen & Catering Ltd',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 4),
        taxPeriod: period,
        taxableAmount: 8100000.0,
        vatAmount: 1296000.0,
        totalAmount: 9396000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
        sectionType: SectionType.sectionBPurchases,
      ),
    ];

    final List<InvoiceRecord> etims = List.from(erp);
    final List<InvoiceRecord> itax = List.from(erp);

    return DemoDataSet(
      client: client,
      erpRecords: erp,
      etimsRecords: etims,
      itaxRecords: itax,
    );
  }

  /// Generic dynamic dataset generator for custom added taxpayer companies
  static DemoDataSet generateGenericClientDataset(TaxpayerClient client) {
    final String period = client.currentTaxPeriod.contains('-') ? client.currentTaxPeriod : '2026-08';
    final String buyerPin = client.kraPin;
    final String buyerName = client.businessName;

    final List<InvoiceRecord> erp = [
      InvoiceRecord(
        id: 'GEN-ERP-001',
        invoiceNumber: 'INV-${client.kraPin.substring(0, 4)}-01',
        etimsControlCode: '011020260801001100',
        cuSerialNumber: 'KRA0112233-01',
        supplierPin: 'P0511192931Z',
        supplierName: 'Safaricom Enterprise Solutions',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 2),
        taxPeriod: period,
        taxableAmount: 500000.0,
        vatAmount: 80000.0,
        totalAmount: 580000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
        sectionType: SectionType.sectionBPurchases,
      ),
      InvoiceRecord(
        id: 'GEN-ERP-002',
        invoiceNumber: 'INV-${client.kraPin.substring(0, 4)}-02',
        etimsControlCode: '011020260805002200',
        cuSerialNumber: 'KRA0223344-02',
        supplierPin: 'P051101992A',
        supplierName: 'Kenya Power & Lighting Co.',
        buyerPin: buyerPin,
        buyerName: buyerName,
        invoiceDate: DateTime(2026, 8, 8),
        taxPeriod: period,
        taxableAmount: 1200000.0,
        vatAmount: 192000.0,
        totalAmount: 1392000.0,
        vatRate: 0.16,
        sourceType: SourceType.erp,
        sectionType: SectionType.sectionBPurchases,
      ),
    ];

    final List<InvoiceRecord> etims = List.from(erp);
    final List<InvoiceRecord> itax = List.from(erp);

    return DemoDataSet(
      client: client,
      erpRecords: erp,
      etimsRecords: etims,
      itaxRecords: itax,
    );
  }

  /// Maps a TaxpayerClient to its specific isolated DemoDataSet
  static DemoDataSet getDatasetForClient(TaxpayerClient client) {
    switch (client.id) {
      case 'CLI-001':
        return generateApexLogistics();
      case 'CLI-002':
        return generateNairobiRetailers();
      case 'CLI-003':
        return generateRiftValleyAgri();
      case 'CLI-004':
        return generateCoastlineHospitality();
      default:
        return generateGenericClientDataset(client);
    }
  }

  /// List of additional demo tax clients for the Advisor Portal
  static List<TaxpayerClient> getAdvisorClients() {
    return [
      TaxpayerClient(
        id: 'CLI-001',
        businessName: 'Apex Logistics Kenya Ltd',
        kraPin: 'P051284920A',
        vatRegistrationNo: 'VAT-051284920',
        sector: 'Freight & Logistics',
        contactEmail: 'tax.finance@apexlogistics.co.ke',
        isAdvisorClient: true,
        riskStatus: 'ACTION_REQUIRED',
        currentTaxPeriod: 'August 2026',
        totalMonthlyPurchases: 14850000.0,
        inputVatClaimable: 2048000.0,
        inputVatAtRisk: 485000.0,
        totalInvoicesCount: 14,
        matchedInvoicesCount: 8,
      ),
      TaxpayerClient(
        id: 'CLI-002',
        businessName: 'Nairobi Commercial Retailers Ltd',
        kraPin: 'P051992011Z',
        vatRegistrationNo: 'VAT-051992011',
        sector: 'Supermarket & FMCG Retail',
        contactEmail: 'accounts@nairobretail.co.ke',
        isAdvisorClient: true,
        riskStatus: 'HIGH_RISK',
        currentTaxPeriod: 'August 2026',
        totalMonthlyPurchases: 28400000.0,
        inputVatClaimable: 3912000.0,
        inputVatAtRisk: 624500.0,
        totalInvoicesCount: 32,
        matchedInvoicesCount: 19,
      ),
      TaxpayerClient(
        id: 'CLI-003',
        businessName: 'Rift Valley Agriculture Exporters',
        kraPin: 'P052001192M',
        vatRegistrationNo: 'VAT-052001192',
        sector: 'Agri-Business & Horticulture',
        contactEmail: 'finance@riftagri.com',
        isAdvisorClient: true,
        riskStatus: 'READY_TO_FILE',
        currentTaxPeriod: 'August 2026',
        totalMonthlyPurchases: 18900000.0,
        inputVatClaimable: 1512000.0,
        inputVatAtRisk: 0.0,
        totalInvoicesCount: 22,
        matchedInvoicesCount: 22,
      ),
      TaxpayerClient(
        id: 'CLI-004',
        businessName: 'Coastline Hospitality & Resorts Group',
        kraPin: 'P051773099C',
        vatRegistrationNo: 'VAT-051773099',
        sector: 'Tourism & Hotel Management',
        contactEmail: 'tax@coastlinemombasa.com',
        isAdvisorClient: true,
        riskStatus: 'ACTION_REQUIRED',
        currentTaxPeriod: 'August 2026',
        totalMonthlyPurchases: 9400000.0,
        inputVatClaimable: 1296000.0,
        inputVatAtRisk: 184000.0,
        totalInvoicesCount: 18,
        matchedInvoicesCount: 12,
      ),
    ];
  }
}
