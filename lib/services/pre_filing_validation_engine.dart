import '../models/invoice_record.dart';
import '../models/whvat_record.dart';
import '../models/customs_entry_record.dart';

enum ValidationSeverity { info, warning, error }

class ValidationIssue {
  final String section;
  final String referenceKey;
  final ValidationSeverity severity;
  final String ruleCode;
  final String message;

  const ValidationIssue({
    required this.section,
    required this.referenceKey,
    required this.severity,
    required this.ruleCode,
    required this.message,
  });
}

class ValidationReport {
  final bool isReadyForFiling;
  final int totalRecordsAudited;
  final int errorCount;
  final int warningCount;
  final List<ValidationIssue> issues;

  const ValidationReport({
    required this.isReadyForFiling,
    required this.totalRecordsAudited,
    required this.errorCount,
    required this.warningCount,
    required this.issues,
  });
}

class PreFilingValidationEngine {
  /// Evaluates pre-flight validation rules against official KRA iTax portal constraints
  static ValidationReport validateReturn({
    required List<InvoiceRecord> salesRecords,
    required List<InvoiceRecord> purchaseRecords,
    required List<CustomsEntryRecord> customsEntries,
    required List<WhvatRecord> whvatRecords,
  }) {
    final List<ValidationIssue> issues = [];
    int errorCount = 0;
    int warningCount = 0;

    // 1. Validate Section B (Purchases)
    for (var r in purchaseRecords) {
      final key = 'SEC_B:${r.invoiceNumber}';
      if (!r.hasValidPin) {
        warningCount++;
        issues.add(ValidationIssue(
          section: 'Section B (Purchases)',
          referenceKey: key,
          severity: ValidationSeverity.warning,
          ruleCode: 'KRA-PIN-001',
          message: 'Invoice ${r.invoiceNumber} has non-VAT/no-PIN merchant. Must be declared under General Merchant schedule.',
        ));
      }

      if (r.vatAmount > 0 && (r.etimsControlCode == null || r.etimsControlCode!.isEmpty)) {
        errorCount++;
        issues.add(ValidationIssue(
          section: 'Section B (Purchases)',
          referenceKey: key,
          severity: ValidationSeverity.error,
          ruleCode: 'KRA-ETIMS-002',
          message: 'Claimed Input VAT of KES ${r.vatAmount.toStringAsFixed(2)} lacks valid eTIMS Control Code. KRA will issue automated VAA rejection.',
        ));
      }

      if (r.vatRate != 0.16 && r.vatRate != 0.08 && r.vatRate != 0.0) {
        warningCount++;
        issues.add(ValidationIssue(
          section: 'Section B (Purchases)',
          referenceKey: key,
          severity: ValidationSeverity.warning,
          ruleCode: 'KRA-RATE-003',
          message: 'Non-standard VAT rate ${(r.vatRate * 100).toStringAsFixed(1)}% detected on invoice ${r.invoiceNumber}. Standard KRA rates are 16%, 8%, or 0%.',
        ));
      }
    }

    // 2. Validate Section A (Sales)
    for (var s in salesRecords) {
      final key = 'SEC_A:${s.invoiceNumber}';
      if (s.totalAmount <= 0) {
        errorCount++;
        issues.add(ValidationIssue(
          section: 'Section A (Sales)',
          referenceKey: key,
          severity: ValidationSeverity.error,
          ruleCode: 'KRA-SALES-004',
          message: 'Sales invoice ${s.invoiceNumber} has invalid zero or negative gross amount.',
        ));
      }
    }

    // 3. Validate Section C (Customs)
    for (var c in customsEntries) {
      final key = 'SEC_C:${c.entryNumber}';
      if (c.entryNumber.length < 5) {
        errorCount++;
        issues.add(ValidationIssue(
          section: 'Section C (Imports)',
          referenceKey: key,
          severity: ValidationSeverity.error,
          ruleCode: 'KRA-CUST-005',
          message: 'Customs C17 Entry Number "${c.entryNumber}" is malformed.',
        ));
      }
    }

    // 4. Validate Section D (WHVAT 2%)
    for (var w in whvatRecords) {
      final key = 'SEC_D:${w.certificateNumber}';
      if (w.whvatAmount <= 0) {
        warningCount++;
        issues.add(ValidationIssue(
          section: 'Section D (WHVAT)',
          referenceKey: key,
          severity: ValidationSeverity.warning,
          ruleCode: 'KRA-WHV-006',
          message: 'WHVAT certificate ${w.certificateNumber} has zero credit value.',
        ));
      }
    }

    final totalCount = salesRecords.length + purchaseRecords.length + customsEntries.length + whvatRecords.length;
    return ValidationReport(
      isReadyForFiling: errorCount == 0,
      totalRecordsAudited: totalCount,
      errorCount: errorCount,
      warningCount: warningCount,
      issues: issues,
    );
  }
}
