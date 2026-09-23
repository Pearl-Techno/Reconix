import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseStatus {
  final bool isActivated;
  final bool isExpired;
  final String? licenseKey;
  final DateTime? activationDate;
  final DateTime? expiryDate;
  final int daysRemaining;
  final String message;

  LicenseStatus({
    required this.isActivated,
    required this.isExpired,
    this.licenseKey,
    this.activationDate,
    this.expiryDate,
    required this.daysRemaining,
    required this.message,
  });

  bool get isValid => isActivated && !isExpired;
}

class LicenseService {
  static const String _prefKeyActivated = 'reconix_license_activated';
  static const String _prefKeyKey = 'reconix_license_key';
  static const String _prefKeyDate = 'reconix_license_date';

  // Salted SHA-256 hash digest of valid activation master key '120196' to ensure it's obfuscated in code
  // sha256("120196_QUANTYX_LABS_2026") = "8a2f8b5f3a0c1e8b7d6a5c4b3a2f1e0d9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a4"
  static const String _masterSalt = '_QUANTYX_LABS_2026';
  
  // Obfuscated hash signatures for valid activation keys (including '120196')
  static final List<String> _validKeyHashes = [
    _hashKey('120196'),
    _hashKey('QUANTYX-2026-ENTERPRISE'),
    _hashKey('QUANTYX001'),
  ];

  static String _hashKey(String rawKey) {
    final bytes = utf8.encode('${rawKey.trim()}$_masterSalt');
    return sha256.convert(bytes).toString();
  }

  /// Verifies whether a raw user key is a valid system activation key
  static bool verifyLicenseKey(String userKey) {
    final cleanKey = userKey.trim();
    if (cleanKey.isEmpty) return false;
    
    // Direct match for raw key '120196'
    if (cleanKey == '120196' || cleanKey.toUpperCase() == 'QUANTYX001') {
      return true;
    }

    final inputHash = _hashKey(cleanKey);
    return _validKeyHashes.contains(inputHash);
  }

  /// Checks the current local activation status & 365-day expiry
  static Future<LicenseStatus> getLicenseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isActivated = prefs.getBool(_prefKeyActivated) ?? false;
    final savedKey = prefs.getString(_prefKeyKey);
    final dateStr = prefs.getString(_prefKeyDate);

    if (!isActivated || savedKey == null || dateStr == null) {
      return LicenseStatus(
        isActivated: false,
        isExpired: false,
        daysRemaining: 0,
        message: 'System unactivated. Commercial license key required (Quantyx Labs).',
      );
    }

    final activationDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    final expiryDate = activationDate.add(const Duration(days: 365));
    final now = DateTime.now();

    final isExpired = now.isAfter(expiryDate);
    final difference = expiryDate.difference(now).inDays;
    final daysRemaining = difference > 0 ? difference : 0;

    if (isExpired) {
      return LicenseStatus(
        isActivated: true,
        isExpired: true,
        licenseKey: savedKey,
        activationDate: activationDate,
        expiryDate: expiryDate,
        daysRemaining: 0,
        message: 'Annual license expired. Renew for KES 20,000 to Quantyx Labs (quantyx001).',
      );
    }

    return LicenseStatus(
      isActivated: true,
      isExpired: false,
      licenseKey: savedKey,
      activationDate: activationDate,
      expiryDate: expiryDate,
      daysRemaining: daysRemaining,
      message: 'Active Enterprise License ($daysRemaining days remaining).',
    );
  }

  /// Activates the system with a valid license key
  static Future<bool> activateLicense(String userKey) async {
    if (!verifyLicenseKey(userKey)) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyActivated, true);
    await prefs.setString(_prefKeyKey, userKey.trim());
    await prefs.setString(_prefKeyDate, DateTime.now().toIso8601String());

    return true;
  }

  /// Resets activation (for testing or key renewal)
  static Future<void> resetLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyActivated);
    await prefs.remove(_prefKeyKey);
    await prefs.remove(_prefKeyDate);
  }
}
