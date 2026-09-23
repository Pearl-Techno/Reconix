import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import '../models/invoice_record.dart';
import '../models/taxpayer_client.dart';
import '../models/whvat_record.dart';
import '../models/customs_entry_record.dart';
import '../models/audit_log_entry.dart';

class DatabaseService {
  static Database? _db;

  /// Returns active SQLite database instance
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // In Web, initialize FFI in-memory database
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      return await openDatabase(
        inMemoryDatabasePath,
        version: 5,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      // Desktop / FFI initialization for Windows
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      } catch (_) {}

      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'reconix.db');

      return await openDatabase(
        path,
        version: 5,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN client_id TEXT');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS whvat_records (
            id TEXT PRIMARY KEY,
            certificate_number TEXT,
            supplier_pin TEXT,
            supplier_name TEXT,
            buyer_pin TEXT,
            buyer_name TEXT,
            certificate_date TEXT,
            tax_period TEXT,
            gross_invoice_amount REAL,
            whvat_amount REAL,
            invoice_number TEXT,
            is_claimed_on_itax INTEGER,
            is_demo INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS customs_records (
            id TEXT PRIMARY KEY,
            entry_number TEXT,
            customs_station TEXT,
            importer_pin TEXT,
            importer_name TEXT,
            declaration_date TEXT,
            tax_period TEXT,
            taxable_value REAL,
            import_vat_amount REAL,
            hs_code TEXT,
            is_matched_with_erp INTEGER,
            is_demo INTEGER
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tax_period_locks (
            client_id TEXT,
            tax_period TEXT,
            is_locked INTEGER,
            locked_by_user TEXT,
            locked_at TEXT,
            PRIMARY KEY (client_id, tax_period)
          )
        ''');
      } catch (_) {}
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 1. Clients Table
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        business_name TEXT,
        kra_pin TEXT,
        vat_reg_no TEXT,
        sector TEXT,
        contact_email TEXT,
        is_advisor_client INTEGER,
        risk_status TEXT,
        current_tax_period TEXT,
        total_monthly_purchases REAL,
        input_vat_claimable REAL,
        input_vat_at_risk REAL,
        total_invoices_count INTEGER,
        matched_invoices_count INTEGER,
        is_demo INTEGER
      )
    ''');

    // 2. Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        client_id TEXT,
        invoice_number TEXT,
        supplier_pin TEXT,
        supplier_name TEXT,
        buyer_pin TEXT,
        buyer_name TEXT,
        invoice_date TEXT,
        tax_period TEXT,
        taxable_amount REAL,
        vat_amount REAL,
        total_amount REAL,
        source_type TEXT,
        etims_control_code TEXT,
        cu_serial_number TEXT,
        is_demo INTEGER
      )
    ''');

    // 3. Resolutions Table
    await db.execute('''
      CREATE TABLE reconciliation_resolutions (
        match_id TEXT PRIMARY KEY,
        resolution_tag TEXT,
        user_note TEXT,
        is_resolved INTEGER,
        resolved_at TEXT
      )
    ''');

    // 4. App Settings Table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // 5. WHVAT Table
    await db.execute('''
      CREATE TABLE whvat_records (
        id TEXT PRIMARY KEY,
        certificate_number TEXT,
        supplier_pin TEXT,
        supplier_name TEXT,
        buyer_pin TEXT,
        buyer_name TEXT,
        certificate_date TEXT,
        tax_period TEXT,
        gross_invoice_amount REAL,
        whvat_amount REAL,
        invoice_number TEXT,
        is_claimed_on_itax INTEGER,
        is_demo INTEGER
      )
    ''');

    // 6. Customs Entries Table
    await db.execute('''
      CREATE TABLE customs_records (
        id TEXT PRIMARY KEY,
        entry_number TEXT,
        customs_station TEXT,
        importer_pin TEXT,
        importer_name TEXT,
        declaration_date TEXT,
        tax_period TEXT,
        taxable_value REAL,
        import_vat_amount REAL,
        hs_code TEXT,
        is_matched_with_erp INTEGER,
        is_demo INTEGER
      )
    ''');

    // 7. Audit Logs Table
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT,
        user_role TEXT,
        action TEXT,
        target_invoice_key TEXT,
        timestamp TEXT,
        details TEXT
      )
    ''');
  }

  // --- CLIENT OPERATIONS ---

  static Future<void> insertClient(TaxpayerClient client, {bool isDemo = false}) async {
    final db = await database;
    await db.insert(
      'clients',
      {
        'id': client.id,
        'business_name': client.businessName,
        'kra_pin': client.kraPin,
        'vat_reg_no': client.vatRegistrationNo,
        'sector': client.sector,
        'contact_email': client.contactEmail,
        'is_advisor_client': client.isAdvisorClient ? 1 : 0,
        'risk_status': client.riskStatus,
        'current_tax_period': client.currentTaxPeriod,
        'total_monthly_purchases': client.totalMonthlyPurchases,
        'input_vat_claimable': client.inputVatClaimable,
        'input_vat_at_risk': client.inputVatAtRisk,
        'total_invoices_count': client.totalInvoicesCount,
        'matched_invoices_count': client.matchedInvoicesCount,
        'is_demo': isDemo ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<TaxpayerClient>> getClients({required bool isDemo}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'is_demo = ?',
      whereArgs: [isDemo ? 1 : 0],
    );

    return maps.map((map) {
      return TaxpayerClient(
        id: map['id'] as String,
        businessName: map['business_name'] as String,
        kraPin: map['kra_pin'] as String,
        vatRegistrationNo: map['vat_reg_no'] as String,
        sector: map['sector'] as String,
        contactEmail: map['contact_email'] as String,
        isAdvisorClient: (map['is_advisor_client'] as int) == 1,
        riskStatus: map['risk_status'] as String,
        currentTaxPeriod: map['current_tax_period'] as String,
        totalMonthlyPurchases: (map['total_monthly_purchases'] as num).toDouble(),
        inputVatClaimable: (map['input_vat_claimable'] as num).toDouble(),
        inputVatAtRisk: (map['input_vat_at_risk'] as num).toDouble(),
        totalInvoicesCount: map['total_invoices_count'] as int,
        matchedInvoicesCount: map['matched_invoices_count'] as int,
      );
    }).toList();
  }

  // --- INVOICE OPERATIONS ---

  static Future<void> insertInvoices(
    List<InvoiceRecord> records, {
    required String clientId,
    bool isDemo = false,
  }) async {
    if (records.isEmpty) return;
    final db = await database;

    const int chunkSize = 1000;
    for (var i = 0; i < records.length; i += chunkSize) {
      final end = (i + chunkSize < records.length) ? i + chunkSize : records.length;
      final chunk = records.sublist(i, end);
      final batch = db.batch();

      for (var r in chunk) {
        batch.insert(
          'invoices',
          {
            'id': r.id,
            'client_id': clientId,
            'invoice_number': r.invoiceNumber,
            'supplier_pin': r.supplierPin,
            'supplier_name': r.supplierName,
            'buyer_pin': r.buyerPin,
            'buyer_name': r.buyerName,
            'invoice_date': r.invoiceDate.toIso8601String(),
            'tax_period': r.taxPeriod,
            'taxable_amount': r.taxableAmount,
            'vat_amount': r.vatAmount,
            'total_amount': r.totalAmount,
            'source_type': r.sourceType.name,
            'etims_control_code': r.etimsControlCode,
            'cu_serial_number': r.cuSerialNumber,
            'is_demo': isDemo ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    }
  }

  static Future<List<InvoiceRecord>> getInvoices({
    required String clientId,
    required SourceType sourceType,
    required bool isDemo,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'client_id = ? AND source_type = ? AND is_demo = ?',
      whereArgs: [clientId, sourceType.name, isDemo ? 1 : 0],
    );

    return maps.map((map) {
      return InvoiceRecord(
        id: map['id'] as String,
        invoiceNumber: map['invoice_number'] as String,
        supplierPin: map['supplier_pin'] as String,
        supplierName: map['supplier_name'] as String,
        buyerPin: map['buyer_pin'] as String,
        buyerName: map['buyer_name'] as String,
        invoiceDate: DateTime.parse(map['invoice_date'] as String),
        taxPeriod: map['tax_period'] as String,
        taxableAmount: (map['taxable_amount'] as num).toDouble(),
        vatAmount: (map['vat_amount'] as num).toDouble(),
        totalAmount: (map['total_amount'] as num).toDouble(),
        sourceType: SourceType.values.firstWhere((e) => e.name == map['source_type']),
        etimsControlCode: map['etims_control_code'] as String?,
        cuSerialNumber: map['cu_serial_number'] as String?,
      );
    }).toList();
  }

  static Future<void> clearLiveDatabase() async {
    final db = await database;
    await db.delete('invoices', where: 'is_demo = 0');
    await db.delete('clients', where: 'is_demo = 0');
    await db.delete('whvat_records', where: 'is_demo = 0');
    await db.delete('customs_records', where: 'is_demo = 0');
    await db.delete('audit_logs');
    await db.delete('reconciliation_resolutions');
  }

  // --- AUDIT LOG OPERATIONS ---

  static Future<void> insertAuditLog(AuditLogEntry entry) async {
    final db = await database;
    await db.insert(
      'audit_logs',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<AuditLogEntry>> getAuditLogs() async {
    final db = await database;
    final maps = await db.query('audit_logs', orderBy: 'timestamp DESC');
    return maps.map((m) => AuditLogEntry.fromMap(m)).toList();
  }

  // --- WHVAT OPERATIONS ---

  static Future<void> insertWhvatRecords(List<WhvatRecord> records, {bool isDemo = false}) async {
    if (records.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (var r in records) {
      final map = r.toMap();
      map['is_demo'] = isDemo ? 1 : 0;
      batch.insert('whvat_records', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<WhvatRecord>> getWhvatRecords({required bool isDemo}) async {
    final db = await database;
    final maps = await db.query(
      'whvat_records',
      where: 'is_demo = ?',
      whereArgs: [isDemo ? 1 : 0],
    );
    return maps.map((map) => WhvatRecord.fromMap(map)).toList();
  }

  // --- CUSTOMS OPERATIONS ---

  static Future<void> insertCustomsEntries(List<CustomsEntryRecord> entries, {bool isDemo = false}) async {
    if (entries.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (var e in entries) {
      final map = e.toMap();
      map['is_demo'] = isDemo ? 1 : 0;
      batch.insert('customs_records', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<CustomsEntryRecord>> getCustomsEntries({required bool isDemo}) async {
    final db = await database;
    final maps = await db.query(
      'customs_records',
      where: 'is_demo = ?',
      whereArgs: [isDemo ? 1 : 0],
    );
    return maps.map((map) => CustomsEntryRecord.fromMap(map)).toList();
  }

  // --- TAX PERIOD LOCK OPERATIONS ---

  static Future<bool> isTaxPeriodLocked(String clientId, String taxPeriod) async {
    final db = await database;
    final maps = await db.query(
      'tax_period_locks',
      where: 'client_id = ? AND tax_period = ?',
      whereArgs: [clientId, taxPeriod],
    );
    if (maps.isEmpty) return false;
    return (maps.first['is_locked'] as int?) == 1;
  }

  static Future<void> setTaxPeriodLock({
    required String clientId,
    required String taxPeriod,
    required bool isLocked,
    required String userRole,
  }) async {
    final db = await database;
    await db.insert(
      'tax_period_locks',
      {
        'client_id': clientId,
        'tax_period': taxPeriod,
        'is_locked': isLocked ? 1 : 0,
        'locked_by_user': userRole,
        'locked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- DATABASE BACKUP & RESTORE OPERATIONS ---

  static Future<void> backupDatabase(String targetFilePath) async {
    if (kIsWeb) return;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'reconix.db');
    final dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.copy(targetFilePath);
    }
  }

  static Future<void> restoreDatabase(String sourceFilePath) async {
    if (kIsWeb) return;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'reconix.db');
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    final sourceFile = File(sourceFilePath);
    if (await sourceFile.exists()) {
      await sourceFile.copy(path);
      _db = await _initDatabase();
    }
  }
}
