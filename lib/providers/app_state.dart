import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../models/invoice_record.dart';
import '../models/reconciliation_match.dart';
import '../models/taxpayer_client.dart';
import '../models/reconciliation_certificate.dart';
import '../models/reconciliation_rules.dart';
import '../models/whvat_record.dart';
import '../models/customs_entry_record.dart';
import '../models/audit_log_entry.dart';
import '../services/demo_data_generator.dart';
import '../services/reconciliation_engine.dart';
import '../services/itax_export_service.dart';
import '../services/excel_export_service.dart';
import '../services/database_service.dart';
import '../services/supplier_chaser_service.dart';
import '../services/penalty_simulator_service.dart';
import '../services/audit_defense_pack_service.dart';
import '../services/license_service.dart';

enum DataMode { demo, live }

class AppState extends ChangeNotifier {
  LicenseStatus? _licenseStatus;
  LicenseStatus? get licenseStatus => _licenseStatus;

  Future<void> checkLicenseStatus() async {
    _licenseStatus = await LicenseService.getLicenseStatus();
    notifyListeners();
  }

  Future<bool> activateLicenseKey(String key) async {
    final success = await LicenseService.activateLicense(key);
    await checkLicenseStatus();
    return success;
  }

  int _activeTab = 0;
  int get activeTab => _activeTab;

  ReconciliationRules _rules = const ReconciliationRules();
  ReconciliationRules get rules => _rules;

  void updateRules(ReconciliationRules newRules) {
    _rules = newRules;
    runReconciliation();
  }

  DataMode _dataMode = DataMode.live;
  DataMode get dataMode => _dataMode;

  TaxpayerClient _activeClient = DemoDataGenerator.generateApexLogistics().client;
  TaxpayerClient get activeClient => _activeClient;

  final List<TaxpayerClient> _advisorClients = DemoDataGenerator.getAdvisorClients();
  List<TaxpayerClient> get advisorClients => _advisorClients;

  String _selectedTaxPeriod = 'August 2026';
  String get selectedTaxPeriod => _selectedTaxPeriod;

  List<InvoiceRecord> _erpRecords = [];
  List<InvoiceRecord> get erpRecords => _erpRecords;

  List<InvoiceRecord> _etimsRecords = [];
  List<InvoiceRecord> get etimsRecords => _etimsRecords;

  List<InvoiceRecord> _itaxRecords = [];
  List<InvoiceRecord> get itaxRecords => _itaxRecords;

  List<ReconciliationMatch> _reconciliationResults = [];
  List<ReconciliationMatch> get reconciliationResults => _reconciliationResults;

  // Filters
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  MatchStatus? _selectedStatusFilter;
  MatchStatus? get selectedStatusFilter => _selectedStatusFilter;

  RiskLevel? _selectedRiskFilter;
  RiskLevel? get selectedRiskFilter => _selectedRiskFilter;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isIngesting = false;
  bool get isIngesting => _isIngesting;

  void setIsIngesting(bool ingesting) {
    _isIngesting = ingesting;
    notifyListeners();
  }

  final List<WhvatRecord> _whvatRecords = [];
  List<WhvatRecord> get whvatRecords => _whvatRecords;

  List<WhvatMatchResult> _whvatMatches = [];
  List<WhvatMatchResult> get whvatMatches => _whvatMatches;

  final List<CustomsEntryRecord> _customsEntries = [];
  List<CustomsEntryRecord> get customsEntries => _customsEntries;

  UserRole _currentUserRole = UserRole.seniorTaxManager;
  UserRole get currentUserRole => _currentUserRole;

  void setUserRole(UserRole role) {
    _currentUserRole = role;
    notifyListeners();
  }

  final List<AuditLogEntry> _auditLogs = [];
  List<AuditLogEntry> get auditLogs => _auditLogs;

  Future<void> logAuditAction({
    required String action,
    required String targetKey,
    required String details,
  }) async {
    final entry = AuditLogEntry(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'USR-2026-TAX',
      userName: 'Tax Practitioner User',
      userRole: _currentUserRole,
      action: action,
      targetInvoiceKey: targetKey,
      timestamp: DateTime.now(),
      details: details,
    );
    _auditLogs.insert(0, entry);
    await DatabaseService.insertAuditLog(entry);
    notifyListeners();
  }

  AppState() {
    checkLicenseStatus();
    loadLiveScenarioFromDb();
  }

  Future<void> setDataMode(DataMode mode) async {
    _dataMode = mode;
    clearSelection();
    if (_dataMode == DataMode.demo) {
      loadDemoScenario();
    } else {
      await loadLiveScenarioFromDb();
    }
    notifyListeners();
  }

  Future<void> loadLiveScenarioFromDb() async {
    final liveClients = await DatabaseService.getClients(isDemo: false);
    if (liveClients.isNotEmpty) {
      _activeClient = liveClients.first;
    } else {
      _activeClient = TaxpayerClient(
        id: 'LIVE-CLI-001',
        businessName: 'Live Taxpayer Entity Ltd',
        kraPin: 'P059999999Z',
        vatRegistrationNo: 'VAT-059999999Z',
        contactEmail: 'tax@liveentity.co.ke',
        sector: 'Commercial Operations',
        currentTaxPeriod: '2026-08',
        totalMonthlyPurchases: 0.0,
        inputVatClaimable: 0.0,
        inputVatAtRisk: 0.0,
        totalInvoicesCount: 0,
        matchedInvoicesCount: 0,
        riskStatus: 'READY_TO_FILE',
      );
      await DatabaseService.insertClient(_activeClient, isDemo: false);
    }

    await refreshInvoicesForActiveClient();
  }

  Future<void> refreshInvoicesForActiveClient() async {
    if (_dataMode == DataMode.live) {
      _erpRecords = await DatabaseService.getInvoices(clientId: _activeClient.id, sourceType: SourceType.erp, isDemo: false);
      _etimsRecords = await DatabaseService.getInvoices(clientId: _activeClient.id, sourceType: SourceType.etims, isDemo: false);
      _itaxRecords = await DatabaseService.getInvoices(clientId: _activeClient.id, sourceType: SourceType.itax, isDemo: false);
    }
    runReconciliation();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  void setTaxPeriod(String period) {
    _selectedTaxPeriod = period;
    notifyListeners();
  }

  void loadDemoScenario([DemoDataSet? dataSet]) {
    _dataMode = DataMode.demo;
    final ds = dataSet ?? DemoDataGenerator.generateApexLogistics();
    _activeClient = ds.client;
    _erpRecords = List.from(ds.erpRecords);
    _etimsRecords = List.from(ds.etimsRecords);
    _itaxRecords = List.from(ds.itaxRecords);
    
    runReconciliation();
  }

  Future<void> addLiveInvoices({
    required List<InvoiceRecord> records,
    required SourceType sourceType,
  }) async {
    _dataMode = DataMode.live;
    if (sourceType == SourceType.erp) {
      _erpRecords.addAll(records);
    } else if (sourceType == SourceType.etims) {
      _etimsRecords.addAll(records);
    } else if (sourceType == SourceType.itax) {
      _itaxRecords.addAll(records);
    }

    await DatabaseService.insertInvoices(records, clientId: _activeClient.id, isDemo: false);
    runReconciliation();
  }

  Future<void> addLiveWhvatRecords(List<WhvatRecord> records) async {
    _dataMode = DataMode.live;
    _whvatRecords.addAll(records);
    await DatabaseService.insertWhvatRecords(records, isDemo: false);
    runWhvatReconciliation();
  }

  Future<void> addLiveCustomsEntries(List<CustomsEntryRecord> entries) async {
    _dataMode = DataMode.live;
    _customsEntries.addAll(entries);
    await DatabaseService.insertCustomsEntries(entries, isDemo: false);
    notifyListeners();
  }

  void runWhvatReconciliation() {
    _whvatMatches = ReconciliationEngine.reconcileWhvat(
      whvatRecords: _whvatRecords,
      invoiceRecords: [..._erpRecords, ..._etimsRecords],
    );
    notifyListeners();
  }

  SupplierChaserNotice generateSupplierNotice(ReconciliationMatch match) {
    final matchesForSupplier = _reconciliationResults.where((m) => m.supplierPin == match.supplierPin).toList();
    return SupplierChaserService.generateNotice(
      client: _activeClient,
      supplierDiscrepancies: matchesForSupplier.isNotEmpty ? matchesForSupplier : [match],
    );
  }

  Future<void> addNewCompany(TaxpayerClient newClient) async {
    if (!_advisorClients.any((c) => c.id == newClient.id)) {
      _advisorClients.insert(0, newClient);
    }
    await DatabaseService.insertClient(newClient, isDemo: _dataMode == DataMode.demo);
    await selectClient(newClient);
  }

  Future<void> selectClient(TaxpayerClient client) async {
    _activeClient = client;
    clearSelection();
    if (_dataMode == DataMode.demo) {
      if (client.id == 'CLI-001') {
        loadDemoScenario(DemoDataGenerator.generateApexLogistics());
      } else {
        loadDemoScenario();
      }
    } else {
      await refreshInvoicesForActiveClient();
    }
    notifyListeners();
  }

  Future<void> runReconciliationAsync() async {
    _isProcessing = true;
    notifyListeners();

    try {
      _reconciliationResults = await ReconciliationEngine.reconcileAsync(
        erpRecords: _erpRecords,
        etimsRecords: _etimsRecords,
        itaxRecords: _itaxRecords,
        rules: _rules,
      );
    } catch (e) {
      _reconciliationResults = ReconciliationEngine.reconcile(
        erpRecords: _erpRecords,
        etimsRecords: _etimsRecords,
        itaxRecords: _itaxRecords,
        rules: _rules,
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void runReconciliation() {
    _reconciliationResults = ReconciliationEngine.reconcile(
      erpRecords: _erpRecords,
      etimsRecords: _etimsRecords,
      itaxRecords: _itaxRecords,
      rules: _rules,
    );
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setStatusFilter(MatchStatus? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setRiskFilter(RiskLevel? risk) {
    _selectedRiskFilter = risk;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedStatusFilter = null;
    _selectedRiskFilter = null;
    notifyListeners();
  }

  // Selection & Bulk Action State
  final Set<String> _selectedMatchIds = {};
  Set<String> get selectedMatchIds => _selectedMatchIds;

  void toggleSelectMatch(String matchId) {
    if (_selectedMatchIds.contains(matchId)) {
      _selectedMatchIds.remove(matchId);
    } else {
      _selectedMatchIds.add(matchId);
    }
    notifyListeners();
  }

  void selectAllFilteredMatches() {
    final ids = filteredMatches.map((m) => m.matchId).toSet();
    if (_selectedMatchIds.containsAll(ids)) {
      _selectedMatchIds.removeAll(ids);
    } else {
      _selectedMatchIds.addAll(ids);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedMatchIds.clear();
    notifyListeners();
  }

  void bulkApplyTag(String tag) {
    if (_selectedMatchIds.isEmpty) return;
    final now = DateTime.now();
    for (int i = 0; i < _reconciliationResults.length; i++) {
      if (_selectedMatchIds.contains(_reconciliationResults[i].matchId)) {
        _reconciliationResults[i] = _reconciliationResults[i].copyWith(
          resolutionTag: tag,
          isResolved: true,
          resolvedAt: now,
        );
      }
    }
    notifyListeners();
  }

  void exportITaxSectionBCsv() {
    final csvContent = ITaxExportService.generateITaxSectionBCsv(
      client: _activeClient,
      taxPeriod: _selectedTaxPeriod,
      matches: _reconciliationResults,
    );
    final fileName = 'KRA_iTax_SectionB_InputVAT_${_activeClient.kraPin}_${_selectedTaxPeriod.replaceAll(' ', '_')}.csv';
    ITaxExportService.downloadCsvWeb(csvData: csvContent, fileName: fileName);
  }

  void exportAuditLedgerExcel() {
    final bytes = ExcelExportService.generateAuditLedgerExcel(
      client: _activeClient,
      taxPeriod: _selectedTaxPeriod,
      matches: _reconciliationResults,
    );
    if (bytes != null && bytes.isNotEmpty) {
      final fileName = 'Reconix_3Way_VAT_AuditLedger_${_activeClient.kraPin}_${_selectedTaxPeriod.replaceAll(' ', '_')}.xlsx';
      final csvRepresentation = String.fromCharCodes(bytes);
      ITaxExportService.downloadCsvWeb(csvData: csvRepresentation, fileName: fileName);
    }
  }

  void updateResolution({
    required String matchId,
    required String tag,
    String? note,
  }) {
    final index = _reconciliationResults.indexWhere((m) => m.matchId == matchId);
    if (index != -1) {
      _reconciliationResults[index] = _reconciliationResults[index].copyWith(
        resolutionTag: tag,
        userNote: note,
        isResolved: true,
        resolvedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Filtered getter for the view table
  List<ReconciliationMatch> get filteredMatches {
    return _reconciliationResults.where((m) {
      // Status filter
      if (_selectedStatusFilter != null && m.status != _selectedStatusFilter) {
        return false;
      }
      // Risk filter
      if (_selectedRiskFilter != null && m.riskLevel != _selectedRiskFilter) {
        return false;
      }
      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchInv = m.invoiceNumber.toLowerCase().contains(q);
        final matchPin = m.supplierPin.toLowerCase().contains(q);
        final matchName = m.supplierName.toLowerCase().contains(q);
        return matchInv || matchPin || matchName;
      }
      return true;
    }).toList();
  }

  // Summary KPI Getters
  double get totalInputVatClaimable {
    return _reconciliationResults
        .where((m) => m.status == MatchStatus.matched)
        .fold(0.0, (sum, m) => sum + m.primaryVat);
  }

  double get totalInputVatAtRisk {
    return _reconciliationResults
        .where((m) => m.status == MatchStatus.unclaimedInputVat || m.status == MatchStatus.vaaDisallowanceRisk)
        .fold(0.0, (sum, m) => sum + m.claimableVatAtRisk);
  }

  double get total2026ExpenseDeductibilityRisk {
    return _reconciliationResults
        .where((m) => m.status == MatchStatus.expenseValidationRisk2026 || m.status == MatchStatus.vaaDisallowanceRisk)
        .fold(0.0, (sum, m) => sum + m.incomeTaxDisallowanceRisk);
  }

  double get corporateTaxRate => 0.30;

  double get totalCorporateTaxDisallowanceLiability => total2026ExpenseDeductibilityRisk * corporateTaxRate;

  double get matchedRatioPercentage {
    if (_reconciliationResults.isEmpty) return 0.0;
    final matchedCount = _reconciliationResults.where((m) => m.status == MatchStatus.matched).length;
    return (matchedCount / _reconciliationResults.length) * 100;
  }

  int get timingLatencyCount {
    return _reconciliationResults.where((m) => m.status == MatchStatus.timingLatency).length;
  }

  int get vaaRiskCount {
    return _reconciliationResults.where((m) => m.status == MatchStatus.vaaDisallowanceRisk).length;
  }

  int get unclaimedVatCount {
    return _reconciliationResults.where((m) => m.status == MatchStatus.unclaimedInputVat).length;
  }

  ReconciliationCertificate generateCertificate() {
    final now = DateTime.now();
    final rawString = '${_activeClient.kraPin}_${_selectedTaxPeriod}_${_reconciliationResults.length}_${now.toIso8601String()}';
    final hashDigest = sha256.convert(utf8.encode(rawString)).toString();

    final fullyMatched = _reconciliationResults.where((m) => m.status == MatchStatus.matched).length;
    final timingLatency = _reconciliationResults.where((m) => m.status == MatchStatus.timingLatency).length;
    final unclaimedVat = _reconciliationResults.where((m) => m.status == MatchStatus.unclaimedInputVat).length;
    final vaaRisk = _reconciliationResults.where((m) => m.status == MatchStatus.vaaDisallowanceRisk).length;
    final expenseRisk = _reconciliationResults.where((m) => m.status == MatchStatus.expenseValidationRisk2026).length;

    final totalErpPurchases = _erpRecords.fold(0.0, (sum, r) => sum + r.totalAmount);

    return ReconciliationCertificate(
      certificateId: 'REC-${now.year}${(now.month).toString().padLeft(2, '0')}-${_activeClient.kraPin.substring(0, 7)}-${hashDigest.substring(0, 4).toUpperCase()}',
      sha256Hash: hashDigest,
      taxpayerName: _activeClient.businessName,
      kraPin: _activeClient.kraPin,
      taxPeriod: _selectedTaxPeriod,
      generatedAt: now,
      totalErpRecordsCount: _erpRecords.length,
      totalEtimsRecordsCount: _etimsRecords.length,
      totalItaxRecordsCount: _itaxRecords.length,
      fullyMatchedCount: fullyMatched,
      timingLatencyCount: timingLatency,
      unclaimedInputVatCount: unclaimedVat,
      vaaDisallowanceCount: vaaRisk,
      expenseValidationRiskCount: expenseRisk,
      totalPurchasesErp: totalErpPurchases,
      totalInputVatClaimable: totalInputVatClaimable,
      totalInputVatDisallowedExposure: totalInputVatAtRisk,
      total2026ExpenseDeductibilityRisk: total2026ExpenseDeductibilityRisk,
      signedByAdvisor: 'Kenyan Certified Tax Advisor (ICPAK #2026-VAT)',
    );
  }

  // --- OPERATIONAL FEATURES ---

  bool _isTaxPeriodLocked = false;
  bool get isTaxPeriodLocked => _isTaxPeriodLocked;

  Future<void> checkTaxPeriodLock() async {
    _isTaxPeriodLocked = await DatabaseService.isTaxPeriodLocked(_activeClient.id, _selectedTaxPeriod);
    notifyListeners();
  }

  Future<void> toggleTaxPeriodLock() async {
    _isTaxPeriodLocked = !_isTaxPeriodLocked;
    await DatabaseService.setTaxPeriodLock(
      clientId: _activeClient.id,
      taxPeriod: _selectedTaxPeriod,
      isLocked: _isTaxPeriodLocked,
      userRole: _currentUserRole.name,
    );
    await logAuditAction(
      action: _isTaxPeriodLocked ? 'TAX_PERIOD_LOCKED' : 'TAX_PERIOD_UNLOCKED',
      targetKey: '${_activeClient.kraPin}_$_selectedTaxPeriod',
      details: 'Tax Period $_selectedTaxPeriod lock status changed to $_isTaxPeriodLocked by ${_currentUserRole.name}',
    );
    notifyListeners();
  }

  PenaltySimulationResult calculatePenaltyExposure({int daysOverdue = 0}) {
    final deadline = DateTime(2026, 9, 20);
    final filingDate = deadline.add(Duration(days: daysOverdue));
    return PenaltySimulatorService.calculatePenaltyExposure(
      netTaxPayable: totalInputVatClaimable,
      vaaDisallowanceRiskPool: totalInputVatAtRisk,
      returnDeadline: deadline,
      filingDate: filingDate,
    );
  }

  Future<Uint8List> generateAuditDefensePdf() async {
    return AuditDefensePackService.generateAuditDefensePdf(
      businessName: _activeClient.businessName,
      kraPin: _activeClient.kraPin,
      taxPeriod: _selectedTaxPeriod,
      erpRecords: _erpRecords,
      etimsRecords: _etimsRecords,
      whvatRecords: _whvatRecords,
      auditLogs: _auditLogs,
      userRole: _currentUserRole.name,
      isLocked: _isTaxPeriodLocked,
    );
  }

  Future<List<int>> generateAuditDefenseExcel() async {
    return AuditDefensePackService.generateAuditDefenseExcel(
      businessName: _activeClient.businessName,
      kraPin: _activeClient.kraPin,
      taxPeriod: _selectedTaxPeriod,
      erpRecords: _erpRecords,
      etimsRecords: _etimsRecords,
      whvatRecords: _whvatRecords,
      auditLogs: _auditLogs,
    );
  }

  Future<void> backupDatabase(String targetFilePath) async {
    await DatabaseService.backupDatabase(targetFilePath);
    await logAuditAction(
      action: 'DATABASE_BACKUP_CREATED',
      targetKey: targetFilePath,
      details: 'Created SQLite Database backup snapshot at $targetFilePath',
    );
  }

  Future<void> restoreDatabase(String sourceFilePath) async {
    await DatabaseService.restoreDatabase(sourceFilePath);
    await loadLiveScenarioFromDb();
    await logAuditAction(
      action: 'DATABASE_RESTORED',
      targetKey: sourceFilePath,
      details: 'Restored SQLite Database from $sourceFilePath',
    );
    notifyListeners();
  }
}
