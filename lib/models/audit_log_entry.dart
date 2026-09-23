enum UserRole {
  admin,
  seniorTaxManager,
  auditor,
  accountant,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'System Administrator';
      case UserRole.seniorTaxManager:
        return 'Senior Tax Partner / CFO';
      case UserRole.auditor:
        return 'External ICPAK Auditor';
      case UserRole.accountant:
        return 'Tax Accountant';
    }
  }
}

class AuditLogEntry {
  final String id;
  final String userId;
  final String userName;
  final UserRole userRole;
  final String action; // e.g. 'RESOLUTION_TAG_APPLIED', 'EXPORTED_ITAX_BUNDLE'
  final String targetInvoiceKey;
  final DateTime timestamp;
  final String details;

  const AuditLogEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    required this.targetInvoiceKey,
    required this.timestamp,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole.name,
      'action': action,
      'target_invoice_key': targetInvoiceKey,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userRole: UserRole.values.firstWhere(
        (e) => e.name == map['user_role'],
        orElse: () => UserRole.accountant,
      ),
      action: map['action'] as String,
      targetInvoiceKey: map['target_invoice_key'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      details: map['details'] as String,
    );
  }
}
